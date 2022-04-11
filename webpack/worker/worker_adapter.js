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
const fs = require('fs');
const path = require('path');
const WebpackCLI = require('webpack-cli');
const Linker = require(path.join(process.cwd(), process.env._LINKER_PATH));
const Runfiles = require(process.env.BAZEL_NODE_RUNFILES_HELPER)

class WorkerAwareCLI extends WebpackCLI {
  /** @type {import("webpack").Compiler | null} */
  compiler = null;

  resolve; reject;

  /**
   * 
   * @param {import("webpack").StatsError} err 
   * @param {import("webpack").Stats} stats 
   */
  callback(err, stats) {
    if (err && this.reject) {
      console.err(err);
      this.reject(err);
    } else if (!err && this.resolve) {
      worker.log(stats.toString());
      this.resolve(true);
    }
  }

  async createCompiler(options) {
    const cb = (err, stats) => this.callback(err, stats);
    if (this.compiler) {
      this.compiler.run(cb);
    } else {
      this.compiler = await super.createCompiler(options, cb);
    }
  }
}

const MNEMONIC = 'webpack'

function main() {
  if (worker.runAsWorker(process.argv)) {
    runAsPersistentWorker()
  } else {
    runStandalone()
  }
}

async function runAsPersistentWorker() {
  const wp = new WorkerAwareCLI();
  let hashMap;
  const rootPath = process.cwd();
  const execrootNodeModules = path.join(rootPath, "node_modules");

  /**
   * @param args {string[]}
   * @param inputs { [path: string]: string }
   */
  const build = async (args, inputs) => {
    worker.log(`[${MNEMONIC}] Building`);    
    worker.log(`[${MNEMONIC}] ${rootPath}`);    
    if (!fs.existsSync(execrootNodeModules)) {
      worker.log(`[${MNEMONIC}] execroot/node_modules is missing relinking.`);
      await Linker.main([process.env.MODULES_MANIFEST], Runfiles);
      worker.log(`[${MNEMONIC}] execroot/node_modules is missing relinked.`);
    }

    // only diff in subsequent builds
    if (hashMap) {
      const changes = new Set();
      const removals = new Set();
      for (const input of Object.keys(hashMap)) {
        const absolutePath = path.join(rootPath, input)
        if (!inputs[input]) {
          removals.add(absolutePath)
          this.inputFileSystem.purge(absolutePath)
        }
      }
      for (const [input, digest] of Object.entries(inputs)) {
        const absolutePath = path.join(rootPath, input)
        if (hashMap[input] != digest) {
          wp.compiler.inputFileSystem.purge(absolutePath);
          changes.add(absolutePath)
        }
      }
      wp.compiler.modifiedFiles = changes;
      wp.compiler.removedFiles = removals;
    }

    if (wp.compiler) {
      await new Promise((resolve, reject) => wp.compiler.cache.endIdle(err => {
        if (err) {
          return reject(err);
        }
        wp.compiler.idle = false;
        resolve();
      }));
      await new Promise((resolve, reject) => wp.compiler.readRecords(err => {
        if (err) {
          return reject(err);
        }
        resolve();
      }));

      wp.compiler.fsStartTime = Date.now();
    }

    hashMap = inputs;

    return new Promise((resolve, reject) => {
      wp.resolve = resolve;
      wp.reject = reject;
      wp.run([process.argv[0], process.argv[1], ...args]);
    });
  }
  worker.runWorkerLoop(build)
}

function runStandalone() {
  worker.log(`Running ${MNEMONIC} as a standalone process`)
  worker.log(
    `Started a new process to perform this action. Your build might be misconfigured, try	
     --strategy=${MNEMONIC}=worker`
  )
  let argsFilePath = process.argv.pop()
  if (argsFilePath.startsWith('@')) {
    argsFilePath = argsFilePath.slice(1)
  }
  const args = fs.readFileSync(argsFilePath).toString().trim().split('\n')
  new WebpackCLI().run([process.argv[0], process.argv[1], ...args])
}

if (require.main === module) {
  main()
}
