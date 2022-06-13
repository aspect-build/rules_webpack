/**
 * @fileoverview wrapper program around the Webpack CLI.
 *
 * It intercepts the Bazel Persistent Worker protocol, using it to
 * remote-control webpack cli. It tells the compiler process to
 * consolidate file changes only when it receives a request from the worker
 * protocol.
 */

 const worker = require('@bazel/worker')
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
     this.previousInputs = null
   }
 
   async createCompiler(options) {
     if (
       this.options != null &&
       JSON.stringify(options) != JSON.stringify(this.options)
     ) {
       worker.debug(
         `[${MNEMONIC}] options have changed. discarding webpack cache.`
       )
       await this.teardown()
     }
     const cb = (err, stats) => this.callback(err, stats)
     if (this.compiler) {
       this.compiler.run(cb)
     } else {
       worker.debug(options);
       this.compiler = await super.createCompiler(options, cb)
       this.options = options
     }
   }
 }
 
 /** @type {Map<string, WebpackWorker>} */
 const workers = new Map();
 
 /**
  * @argument {string[]} args
  */
 function createOrGetWorker(args) {
   const key = args[args.indexOf('-c') + 1]
   if (!workers.has(key)) {
     worker.debug(`Couldn't find a worker for ${key}`);
     workers.set(key, new WebpackWorker());
   }
   return workers.get(key);
 }
 
 
 async function emit(args, inputs) {
   const wworker = createOrGetWorker(args);
   const previousInputs = wworker.previousInputs;
   const bazelBin = process.cwd();
   const execRoot = path.resolve(bazelBin, "..", "..", "..")
   if (previousInputs) {
     const changes = new Set()
     const removals = new Set()
     for (const input of Object.keys(previousInputs)) {
       const absolutePath = path.join(execRoot, input)
       if (!inputs[input]) {
         wworker.compiler.inputFileSystem.purge(absolutePath)
         removals.add(absolutePath)
       }
     }
     for (const [input, digest] of Object.entries(inputs)) {
       const absolutePath = path.join(execRoot, input)
       if (previousInputs[input] != digest) {
         wworker.compiler.inputFileSystem.purge(absolutePath)
         changes.add(absolutePath)
       }
     }
     wworker.compiler.modifiedFiles = changes
     wworker.compiler.removedFiles = removals
     let hasConfigChanges = false
     for (const config of wworker.options.config) {
       const configPath = path.join(bazelBin, config)
       if (changes.has(configPath) || removals.has(configPath)) {
         hasConfigChanges = true
         worker.debug(
           `Config ${config} has changed. webpack cache will be discarded.`
         )
       }
     }
     if (hasConfigChanges) {
       worker.debug(
         `One or more configs have changed. discarding webpack cache.`
       )
       await wworker.teardown()
     }
   }
 
   if (wworker.compiler) {
     await new Promise((resolve, reject) =>
       wworker.compiler.cache.endIdle((err) => {
         if (err) {
           return reject(err)
         }
         wworker.compiler.idle = false
         resolve()
       })
     )
     await new Promise((resolve, reject) =>
       wworker.compiler.readRecords((err) => {
         if (err) {
           return reject(err)
         }
         resolve()
       })
     )
 
     wworker.compiler.fsStartTime = Date.now()
   }
 
   wworker.previousInputs = inputs
 
   return new Promise((resolve, reject) => {
     wworker.resolve = resolve
     wworker.reject = reject
     wworker.run([process.argv[0], process.argv[1], ...args])
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
   worker.debug(`Running ${MNEMONIC} as a standalone process`)
   worker.debug(
     `Started a new process to perform this action. Your build might be misconfigured, try	
      --strategy=${MNEMONIC}=worker`
   )
   const args = getArgsFromParamFile()
   new WebpackCLI().run([process.argv[0], process.argv[1], ...args])
 }
 
 function main() {
   if (worker.runAsWorker(process.argv)) {
     worker.runWorkerLoop(emit)
   } else {
     emitOnce()
   }
 }
 
 if (require.main === module) {
   main()
 }
 