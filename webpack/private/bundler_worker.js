/**
 * @fileoverview Shared worker logic for webpack and rspack bundlers.
 *
 * Intercepts the Bazel Persistent Worker protocol to remote-control the
 * bundler CLI. Consolidates file changes only when a request arrives from
 * the worker protocol.
 *
 * Entry points (webpack_worker.js / rspack_worker.js) call main() with the
 * appropriate CLI class.
 */

const worker_protocol = require(process.env.RULES_JS_WORKER)
const fs = require('fs')
const path = require('path')

const MNEMONIC = 'Webpack'

function createWorkerClass(CLI, isRspack) {
  class BundlerWorker extends CLI {
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

    async createCompiler(options, ...extra) {
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
        if (isRspack) {
          // RspackCLI.createCompiler doesn't start compilation in non-watch
          // mode — it only returns the compiler. We must call run() ourselves.
          this.compiler = await super.createCompiler(options, extra[0])
          this.compiler.run(cb)
        } else {
          this.compiler = await super.createCompiler(options, cb)
        }
        this.options = options

        // The output directory will be cleaned between runs, however the bundler
        // assumes the output directory will not be modified and caches the file
        // system state.
        if (this.compiler._assetEmittingPreviousFiles) {
          this.compiler.hooks.afterEmit.tap('rules_webpack', () =>
            this.compiler._assetEmittingPreviousFiles.clear()
          )
        } else if (!isRspack) {
          // Webpack4: patch the compiler to ensure all assets are re-written on each completion
          const fsCache = new Map()
          const fsWrites = new Set()

          this.compiler.hooks.emit.tap('rules_webpack', () => fsWrites.clear())

          const originalWriteFile = this.compiler.outputFileSystem.writeFile
          this.compiler.outputFileSystem.writeFile = function workerWriteFile(
            p,
            data,
            cb
          ) {
            fsCache.set(p, data)
            fsWrites.add(p)
            return originalWriteFile.apply(this, arguments)
          }

          this.compiler.hooks.afterEmit.tap('rules_webpack', () => {
            for (const [p, data] of fsCache.entries()) {
              if (!fsWrites.has(p)) {
                originalWriteFile.call(
                  this.compiler.outputFileSystem,
                  p,
                  data,
                  () => {}
                )
              }
            }
            fsWrites.clear()
          })
        }
      }
    }
  }

  return BundlerWorker
}

function main(CLI, isRspack) {
  const BundlerWorker = createWorkerClass(CLI, isRspack)

  /** @type {Map<string, InstanceType<typeof BundlerWorker>>} */
  const workers = new Map()

  function createOrGetWorker(args) {
    const key = args[args.indexOf('--config') + 1]
    if (!workers.has(key)) {
      console.error(`New ${MNEMONIC} worker for ${key}`)
      workers.set(key, new BundlerWorker())
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
      if (worker.compiler.readRecords) {
        await new Promise((resolve, reject) =>
          worker.compiler.readRecords((err) => {
            if (err) {
              return reject(err)
            }
            resolve()
          })
        )
      }

      worker.compiler.fsStartTime = Date.now()
    }

    worker.previousInputs = inputs

    return new Promise((resolve, reject) => {
      console.error(
        `Running ${MNEMONIC} worker ${path.basename(process.argv[1])}`
      )

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
    new CLI().run([process.argv[0], process.argv[1], ...args])
  }

  if (worker_protocol.isPersistentWorker(process.argv)) {
    worker_protocol.enterWorkerLoop(emit)
  } else {
    emitOnce()
  }
}

module.exports = { main }
