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
const worker = require('@bazel/worker')
const cp = require('child_process')
const fs = require('fs')

const webpackCli = require('webpack-cli')

const MNEMONIC = 'webpack'

/** @typedef {{type: "built" | "error"}} IPCMessage */

function main() {
  if (worker.runAsWorker(process.argv)) {
    runAsPersistentWorker()
  } else {
    runStandalone()
  }
}

/**
 * Returns arguments that is preceded by -c
 * @param {string[]} args
 * @returns {string[]}
 */
function findWebpackConfigs(args) {
  const configs = []
  for (let i = 0; i < args.length; i++) {
    if (i > 0 && args[i - 1] == '-c') {
      configs.push(args[i])
    }
  }
  return configs
}

function runAsPersistentWorker() {
  const webpackCliPath = require.resolve('webpack-cli/bin/cli.js')
  /** @type {string} */
  let key
  /** @type {cp.ChildProcess} */
  let proc

  /** @type {Map<string, string>} */
  let configDigestMap = new Map()

  /**
   * @param args {string[]}
   * @param inputs { [path: string]: string }
   */
  const build = async (args, inputs) => {
    return new Promise((resolve, reject) => {
      const configs = findWebpackConfigs(args)

      for (const config of configs) {
        if (configDigestMap.get(config) != inputs[config]) {
          configDigestMap.set(config, inputs[config])
          if (proc && !proc.killed) {
            console.error(
              `a config file change ${config} has been detected. Restarting webpack..`
            )
            proc.kill()
          }
        }
      }

      // We can not add --watch argument earlier in the starlark side
      // until we know for sure which mode we are working on. in RBE
      // local execution strategy will be the default and we have
      // no choice but to add it dynamically on runtime.
      args = [...args, '--watch']

      const argumentKey = args.join('#')

      if (key != argumentKey) {
        worker.log(`Arguments have changed. Killing the process.`)
        proc?.kill()
      }

      /** @param err {Error} */
      const procDied = (err) => {
        if (err) console.error(err)
        worker.log(`Process has died.`)
        resolve(false)
      }

      if (!proc || proc?.killed) {
        worker.log(`Forking webpack cli.`)
        proc = cp.fork(webpackCliPath, args, { stdio: 'pipe' })
        proc.once('error', procDied)
        proc.once('exit', procDied)
        proc.stderr.pipe(process.stderr)
        proc.stdout.pipe(process.stderr)
        key = argumentKey
      }
      proc.send(inputs)

      /** @param message {IPCMessage} */
      const gotMessage = (message) => {
        switch (message.type) {
          case 'built':
            worker.log(`Compilation has succeeded.`)
            resolve(true)
            proc.off('message', gotMessage)
            break
          case 'error':
            worker.log(`Compilation has failed.`)
            console.error(error)
            resolve(false)
            proc.off('message', gotMessage)
            break
        }
      }

      proc.on('message', gotMessage)
    })
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
  new webpackCli().run([process.argv[0], process.argv[1], ...args])
}

if (require.main === module) {
  main()
}
