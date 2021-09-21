/**
 * @fileoverview wrapper program around the Webpack CLI.
 *
 * It intercepts the Bazel Persistent Worker protocol, using it to
 * remote-control webpack cli. It tells the compiler process to
 * consolidate file changes only when it receives a request from the worker
 * protocol.
 *
 * See
 * https://medium.com/@mmorearty/how-to-create-a-persistent-worker-for-bazel-7738bba2cabb
 * for more background on the worker protocol.
 */
const worker = require('@bazel/worker');
const cp = require('child_process');
const fs = require('fs');

const webpackCli = require('webpack-cli');

const MNEMONIC = 'webpack';

/** @typedef {{type: "built" | "error" | "ready"}} IPCMessage */

function main() {
  if (worker.runAsWorker(process.argv)) {
    runAsPersistentWorker();
  } else {
    runStandalone();
  }
}

function runAsPersistentWorker() {
  const webpackCliPath = require.resolve('webpack-cli/bin/cli.js');
  /** @type {string} */
  let key;
  /** @type {cp.ChildProcess} */
  let proc;

  /**
   * @param args {string[]}
   * @param inputs { [path: string]: string }
   */
  const build =
    async (args, inputs) => {
      return new Promise((resolve, reject) => {
        // We can not add --watch argument earlier in the starlark side
        // until we know for sure which mode we are working on. in RBE
        // local execution strategy will be the default and we have
        // no choice but to add it dynamically on runtime.
        args = [...args, '--watch'];

        const argumentKey = args.join('#');

        if (key != argumentKey || proc?.killed) {
          proc?.kill('SIGKILL');
          proc = undefined;
        }

        /** @param err {Error} */
        const procDied =
          (err) => {
            if (err) console.error(err);
            proc = undefined;
            reject();
          }


        if (!proc) {
          proc = cp.fork(webpackCliPath, args, { stdio: 'pipe' });
          proc.once('error', procDied);
          proc.once('exit', procDied);
          proc.stderr.pipe(process.stderr);
          proc.stdout.pipe(process.stderr);
          key = argumentKey;
        }
        else {
          proc.send(inputs);
        }

    
        /** @param message {IPCMessage} */
        const gotMessage = (message) => {
          switch (message.type) {
            case 'ready':
              proc.send(inputs);
              break;
            case 'built':
              resolve(true);
              proc.off('message', gotMessage);
              break;
            case 'error':
              console.error(error);
              resolve(false);
              proc.off('message', gotMessage);
              break;
          }
        }

          proc.on('message', gotMessage);

      });
    }

  worker.runWorkerLoop(build);
}

function runStandalone() {
  worker.log(`Running ${MNEMONIC} as a standalone process`);
  worker.log(
    `Started a new process to perform this action. Your build might be misconfigured, try	
     --strategy=${MNEMONIC}=worker`);
  let argsFilePath = process.argv.pop();
  if (argsFilePath.startsWith('@')) {
    argsFilePath = argsFilePath.slice(1)
  }
  const args = fs.readFileSync(argsFilePath).toString().trim().split('\n');
  new webpackCli().run([process.argv[0], process.argv[1], ...args]);
}

if (require.main === module) {
  main();
}
