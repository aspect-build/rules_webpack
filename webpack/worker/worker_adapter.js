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
const fs = require('fs')
const path = require('path')
const WebpackCLI = require('webpack-cli')
const Linker = require(path.join(process.cwd(), process.env._LINKER_PATH))
const Runfiles = require(process.env.BAZEL_NODE_RUNFILES_HELPER)

class WorkerAwareCLI extends WebpackCLI {
  /** @type {import("webpack").Compiler | null} */
  compiler = null

  /** @type {{[k: string]: unknown} | null} */
  options = null

  /** @type {Function | null} */
  resolve = null
  /** @type {Function | null} */
  reject = null

  /**
   *
   * @param {import("webpack").StatsError} err
   * @param {import("webpack").Stats} stats
   */
  callback(err, stats) {
    if (err && this.reject) {
      console.err(err)
      this.reject(err)
    } else if (!err && this.resolve) {
      worker.log(stats.toString())
      this.resolve(true)
    }
  }

  async teardown() {
    await new Promise((resolve, reject) =>
      this.compiler.close((e) => {
        if (e) {
          return reject(e)
        }
        resolve()
      })
    )
    this.compiler = null
    this.options = null
  }

  async createCompiler(options) {
    if (
      this.options != null &&
      JSON.stringify(options) != JSON.stringify(this.options)
    ) {
      worker.log(
        `[${MNEMONIC}] options have changed. discarding webpack cache.`
      )
      await this.teardown()
    }
    const cb = (err, stats) => this.callback(err, stats)
    if (this.compiler) {
      this.compiler.run(cb)
    } else {
      this.compiler = await super.createCompiler(options, cb)
      this.options = options
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
  const cli = new WorkerAwareCLI()
  /** @type {import("@bazel/worker").Inputs} */
  let inputMap
  const rootPath = process.cwd()
  const execrootNodeModules = path.join(rootPath, 'node_modules')

  /**
   * @param args {string[]}
   * @param inputs { [path: string]: string }
   */
  const build = async (args, inputs) => {
    worker.log(`[${MNEMONIC}] Building`)
    if (!fs.existsSync(execrootNodeModules)) {
      worker.log(
        `[${MNEMONIC}] Looks like execroot has been pruned. Running the linker.`
      )
      await Linker.main([process.env._MODULES_MANIFEST], Runfiles)
    }

    // only diff in subsequent builds
    if (inputMap) {
      const changes = new Set()
      const removals = new Set()
      for (const input of Object.keys(inputMap)) {
        const absolutePath = path.join(rootPath, input)
        if (!inputs[input]) {
          cli.compiler.inputFileSystem.purge(absolutePath)
          removals.add(absolutePath)
        }
      }
      for (const [input, digest] of Object.entries(inputs)) {
        const absolutePath = path.join(rootPath, input)
        if (inputMap[input] != digest) {
          cli.compiler.inputFileSystem.purge(absolutePath)
          changes.add(absolutePath)
        }
      }
      cli.compiler.modifiedFiles = changes
      cli.compiler.removedFiles = removals
      let hasConfigChanges = false
      for (const config of cli.options.config) {
        const configPath = path.join(rootPath, config)
        if (changes.has(configPath) || removals.has(configPath)) {
          hasConfigChanges = true
          worker.log(
            `[${MNEMONIC}] config ${config} has changed. webpack cache will be discarded.`
          )
        }
      }
      if (hasConfigChanges) {
        worker.log(
          `[${MNEMONIC}] one or more configs have changed. discarding webpack cache.`
        )
        await cli.teardown()
      }
    }

    if (cli.compiler) {
      await new Promise((resolve, reject) =>
        cli.compiler.cache.endIdle((err) => {
          if (err) {
            return reject(err)
          }
          cli.compiler.idle = false
          resolve()
        })
      )
      await new Promise((resolve, reject) =>
        cli.compiler.readRecords((err) => {
          if (err) {
            return reject(err)
          }
          resolve()
        })
      )

      cli.compiler.fsStartTime = Date.now()
    }

    inputMap = inputs

    return new Promise((resolve, reject) => {
      cli.resolve = resolve
      cli.reject = reject
      cli.run([process.argv[0], process.argv[1], ...args])
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
  new WebpackCLI().run([process.argv[0], process.argv[1], ...args])
}

if (require.main === module) {
  main()
}
