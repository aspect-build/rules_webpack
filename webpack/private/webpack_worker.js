/**
 * @fileoverview wrapper program around the Webpack CLI.
 *
 * It intercepts the Bazel Persistent Worker protocol, using it to
 * remote-control webpack cli. It tells the compiler process to
 * consolidate file changes only when it receives a request from the worker
 * protocol.
 */

const worker_protocol = require(process.env.RULES_JS_WORKER)
const fs = require('fs')
const path = require('path')
const WebpackCLI = require('webpack-cli')
const MNEMONIC = 'Webpack'

class WebpackWorker extends WebpackCLI {
  /** @type {import("webpack").Compiler | null} */
  compiler = null
  /** @type {import("@bazel/worker").Inputs | null} */
  previousInputs = null

  /** @type {{[k: string]: unknown} | null} */
  options = null

  /** @type {Function | null} */
  resolve = null
  /** @type {Function | null} */
  reject = null

  /** @type {console.Console} */
  console = null

  /**
   * @param {import("stream").Writable} output
   */
  setOutput(output) {
    this.console = new console.Console(output, output)
  }

  /**
   *
   * @param {import("webpack").StatsError} err
   * @param {import("webpack").Stats} stats
   */
  callback(err, stats) {
    if (err && this.reject) {
      this.console.error(err)
      this.reject(err)
    } else if (stats.hasErrors() && this.reject) {
      const statErr = new Error(stats.toJson().errors)
      this.console.error(statErr)
      this.reject(statErr)
    } else if (!err && this.resolve) {
      this.console.log(stats.toString())
      this.resolve(0)
    }
  }

  async teardown() {
    // Cleanup build compiler outputs
    // Webpack5+: https://webpack.js.org/migrate/5/#cleanup-the-build-code
    if (this.compiler.close) {
      await new Promise((resolve, reject) =>
        this.compiler.close((e) => {
          if (e) {
            return reject(e)
          }
          resolve()
        })
      )
    }
    this.compiler = null
    this.options = null
    this.previousInputs = null
  }

  async createCompiler(options) {
    if (
      this.options != null &&
      JSON.stringify(options) != JSON.stringify(this.options)
    ) {
      console.error(
        `[${MNEMONIC}] options have changed. discarding webpack cache.`
      )
      await this.teardown()
    }
    const cb = (err, stats) => this.callback(err, stats)
    if (this.compiler) {
      this.compiler.run(cb)
    } else {
      console.error(options)
      this.compiler = await super.createCompiler(options, cb)
      this.options = options

      // Necessary cache-clearing after each emit to ensure files are re-written to disk
      // on each incremental build.
      this.compiler.hooks.afterEmit.tap("rules_webpack", compilation => {
        // The output directory will be cleaned between runs, webpack assumes the output directory will not be modified:
        // Webpack5: https://github.com/webpack/webpack/blob/v5.36.2/lib/Compiler.js#L783-L788
        if (this.compiler._assetEmittingPreviousFiles) {
          this.compiler._assetEmittingPreviousFiles.clear()
        }

        // Clear the full "emitting sources" cache in <v5 'futureEmitAssets' mode:
        // Webpack4: https://github.com/webpack/webpack/blob/v4.47.0/lib/Compiler.js#L374-L404
        //
        // Or clear the "emitted assets" 'existsAt' cache:
        // Webpack4: https://github.com/webpack/webpack/blob/v4.47.0/lib/Compiler.js#L450-L453
        if (this.compiler.options.output.futureEmitAssets && this.compiler._assetEmittingSourceCache) {
          this.compiler._assetEmittingSourceCache = new WeakMap()
        } else {
          compilation.emittedAssets.clear()
        }
      })
    }
  }
}

/** @type {Map<string, WebpackWorker>} */
const workers = new Map()

function createOrGetWorker(args) {
  const key = args[args.indexOf('--config') + 1]
  if (!workers.has(key)) {
    console.error(`New ${MNEMONIC} worker for ${key}`)
    workers.set(key, new WebpackWorker())
  }
  return workers.get(key)
}

async function emit(request) {
  const inputs = Object.fromEntries(
    request.inputs.map((input) => [
      input.path,
      input.digest.byteLength
        ? Buffer.from(input.digest).toString('hex')
        : null,
    ])
  )
  const worker = createOrGetWorker(request.arguments)
  const previousInputs = worker.previousInputs
  const bazelBin = process.cwd()
  const execRoot = path.resolve(bazelBin, '..', '..', '..')

  worker.setOutput(request.output)

  if (previousInputs) {
    const changes = new Set()
    const removals = new Set()
    for (const input of Object.keys(previousInputs)) {
      const absolutePath = path.join(execRoot, input)
      if (!inputs[input]) {
        worker.compiler.inputFileSystem.purge(absolutePath)
        removals.add(absolutePath)
      }
    }
    for (const [input, digest] of Object.entries(inputs)) {
      const absolutePath = path.join(execRoot, input)
      if (previousInputs[input] != digest) {
        worker.compiler.inputFileSystem.purge(absolutePath)
        changes.add(absolutePath)
      }
    }
    worker.compiler.modifiedFiles = changes
    worker.compiler.removedFiles = removals
    let hasConfigChanges = false
    for (const config of worker.options.config) {
      const configPath = path.join(bazelBin, config)
      if (changes.has(configPath) || removals.has(configPath)) {
        hasConfigChanges = true
        console.error(
          `Config ${config} has changed. webpack cache will be discarded.`
        )
      }
    }
    if (hasConfigChanges) {
      console.error(
        `One or more configs have changed. discarding webpack cache.`
      )
      await worker.teardown()
    }
  }

  if (worker.compiler) {
    // Webpack5: ensure the 'idle' flag is set to false before reading records
    if (worker.compiler.idle) {
      await new Promise((resolve, reject) =>
        worker.compiler.cache.endIdle((err) => {
          if (err) {
            return reject(err)
          }
          worker.compiler.idle = false
          resolve()
        })
      )
    }
    await new Promise((resolve, reject) =>
      worker.compiler.readRecords((err) => {
        if (err) {
          return reject(err)
        }
        resolve()
      })
    )

    worker.compiler.fsStartTime = Date.now()
  }

  worker.previousInputs = inputs

  return new Promise((resolve, reject) => {
    console.error(`Running ${MNEMONIC} worker ${path.basename(process.argv[1])}`)

    worker.resolve = resolve
    worker.reject = reject
    worker.run([process.argv[0], process.argv[1], ...request.arguments])
  })
}

function getArgsFromParamFile() {
  let argsFilePath = process.argv.pop()
  if (argsFilePath.startsWith('@')) {
    argsFilePath = argsFilePath.slice(1)
  }
  return fs.readFileSync(argsFilePath).toString().trim().split('\n')
}

function emitOnce() {
  console.error(`Running ${MNEMONIC} as a standalone process`)
  console.error(
    `Started a new process to perform this action. Your build might be misconfigured, try	
      --strategy=${MNEMONIC}=worker`
  )
  const args = getArgsFromParamFile()
  new WebpackCLI().run([process.argv[0], process.argv[1], ...args])
}

function main() {
  if (worker_protocol.isPersistentWorker(process.argv)) {
    worker_protocol.enterWorkerLoop(emit)
  } else {
    emitOnce()
  }
}

if (require.main === module) {
  main()
}
