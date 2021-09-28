const { join } = require('path');
const AsyncQueue = require("webpack/lib/util/AsyncQueue");

function notAvailable() {
  throw new Error(
    `Watcher polling or pausing is not available under bazel worker mode.`);
}

class WorkerWatchFileSystem {
  /** @type {Map<string, string} */
  digestMap = new Map();

  constructor(inputFileSystem, logger) {
    this.inputFileSystem = inputFileSystem;
    this.logger = logger;
  }

  watch(files, directories, missing, startTime, options, callback, callbackUndelayed) {
    if (!files || typeof files[Symbol.iterator] !== 'function') {
      throw new Error('Invalid arguments: \'files\'');
    }
    if (!directories || typeof directories[Symbol.iterator] !== 'function') {
      throw new Error('Invalid arguments: \'directories\'');
    }
    if (!missing || typeof missing[Symbol.iterator] !== 'function') {
      throw new Error('Invalid arguments: \'missing\'');
    }
    if (typeof callback !== 'function') {
      throw new Error('Invalid arguments: \'callback\'');
    }
    if (typeof options !== 'object') {
      throw new Error('Invalid arguments: \'options\'');
    }

    if (options.poll) {
      notAvailable();
    }

    const rootPath = process.cwd();

    /** @param inputs {{[input: string]: string}} */
    const gotInput = (inputs) => {
      /** @type {Set<string>} */
      const changes = new Set();
      /** @type {Set<string>} */
      const removals = new Set();

      /** @type {Map<string, string>} */
      const times = new Map();

      for (const input of this.digestMap.keys()) {
        if (!inputs[input]) {
          this.digestMap.delete(input);
          const absolutePath = join(rootPath, input);
          removals.add(absolutePath);
          this.inputFileSystem.purge(absolutePath);
        }
      }


      for (const [input, digest] of Object.entries(inputs)) {
        const absolutePath = join(rootPath, input);
        times.set(absolutePath, { timestamp: digest });
        if (this.digestMap.get(input) != digest) {

          changes.add(absolutePath);
          this.inputFileSystem.purge(absolutePath);

          this.digestMap.set(input, digest);
          callbackUndelayed(absolutePath, Date.now());
        }
      }

      callback(null, times, times, changes, removals);
    }

    process.on('message', gotInput);

    return {
      close: () => process.off('message', gotInput),
      // Pause is called before every compilation to ensure
      // that it does not receive any changes while building
      pause: () => process.off('message', gotInput)
    };
  }
}

/** @type {import("webpack").Configuration}  */
module.exports = {
  snapshot: {
    module: { hash: true },
    resolve: { hash: true },
    resolveBuildDependencies: { hash: true },
    buildDependencies: { hash: true },
  },
  plugins: [new class WorkerWatchPlugin {
    /** @param compiler {import("webpack").Compiler} */
    apply(compiler) {
      // Do not install the bazel watcher if we are running under RBE or
      // --strategy=webpack=local
      if (process.send) {
        const logger = compiler.getInfrastructureLogger("bazel.WorkerWatchFileSystem");
        compiler.watchFileSystem = new WorkerWatchFileSystem(
          compiler.inputFileSystem,
          logger,
        );
        compiler.hooks.afterEmit.tap('WorkerWatchPlugin', () => {
          process.send({ type: 'built' });
          logger.debug("Compilation succedded.");
        });
        compiler.hooks.failed.tap('WorkerWatchPlugin', (err) => {
          process.send({ type: 'error' });
          logger.error(err);
          logger.debug("Compilation has failed.")
        });
        compiler.hooks.compilation.tap("WorkerWatchPlugin", compilation => {
          compilation.fileSystemInfo.fileHashQueue = new AsyncQueue({
            name: "file hash",
            parallelism: 1000,
            processor: (path, callback) => {
              const digest = compiler.watchFileSystem.digestMap.get(path) || null;
              if (!digest) {
                compiler.watchFileSystem.digestMap.set(path, null)
              } else {
                compilation.fileSystemInfo._fileHashes.set(path, digest);
              }
              callback(null, digest);
            }
          });
        })
      }
    }
  }]
}
