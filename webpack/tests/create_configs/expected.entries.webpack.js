const path = require('path')
const {createRequire} = require('module')

// Path to the user-supplied webpack config, relative to this file, or null if
// there is none.
const USER_CONFIG = null

function isWebpackCli4() {
  return new Error().stack.includes('webpack-cli@4.')
}

function bazelDefaults(v4) {
  const infrastructureLogging = v4 ? {level: 'error'} : {
    colors: false,
    console: new console.Console(process.stderr, process.stderr),
    level: 'error',
  }

  // We want webpack to spit out deterministic file hashes and module ids
  // this will improve remote caching
  // https://webpack.js.org/guides/caching/#module-identifiers
  const optimization = {
    moduleIds: v4 ? 'natural' : 'deterministic',
    chunkIds: v4 ? 'natural' : 'deterministic',
  }

  // Webpack4: passing any 'output' overrides the standard output config in entries
  const output = v4 ? {
    path: __dirname,
  } : {
    // We want deterministic sourceMaps among other stuff that depends on the unique name.
    // Default behavior of this field causes non-hermetic behavior. Eg; it looks into package.json
    // which is always present in a non-sandboxed environment.
    // See: https://webpack.js.org/configuration/output/#outputuniquename
    // and https://webpack.js.org/configuration/output/#outputdevtoolmodulefilenametemplate
    uniqueName: process.env.BAZEL_WORKSPACE,
  }

  // When use_execroot_entry_point is False, the config files and their dependencies will live in
  // the runfiles directory. Let's add __dirname to the search path to ensure that we can correctly
  // resolve loaders from there.
  const resolveLoader = {
    modules: [path.join(__dirname, 'node_modules'), 'node_modules'],
  }

  // Set by the Bazel rule at action execution time so that the target
  // platform's compilation mode is reflected.
  const mode = process.env.WEBPACK_MODE
  const devtool = process.env.WEBPACK_DEVTOOL

  return {
    infrastructureLogging,
    optimization,
    output,
    resolveLoader,
    ...(mode ? {mode} : {}),
    ...(devtool ? {devtool} : {}),
    entry: {"bar.js":"./webpack/tests/create_configs/bar","foo.js":"./webpack/tests/create_configs/foo"},
  }
}

// webpack-cli and webpack-merge, which it depends on. Neither is necessarily
// resolvable from here (e.g. js_run_devserver copies this config to a temporary
// directory), so resolve webpack-cli from the program's entry point, which
// loads it: webpack's bin script or webpack_worker.js. webpack-merge is then
// resolved from webpack-cli.
let webpackCli
function getWebpackCli() {
  if (!webpackCli) {
    if (!require.main) {
      throw new Error(
        'Cannot find webpack-cli: the generated webpack config must be loaded by a CommonJS entry point'
      )
    }
    const mainRequire = createRequire(require.main.filename)
    const cliRequire = createRequire(mainRequire.resolve('webpack-cli'))
    webpackCli = {
      WebpackCLI: cliRequire('webpack-cli'),
      merge: cliRequire('webpack-merge').merge,
    }
  }
  return webpackCli
}

// Loads the user config with webpack-cli, the same way it loads a `--config`
// file (resolving functions, promises, ESM, `extends`, etc.), and merges the
// Bazel defaults into each of its configs, so that multi-compiler configs
// (arrays) keep their configs separate.
module.exports = async function (env, argv) {
  const v4 = isWebpackCli4()
  if (USER_CONFIG === null) {
    return bazelDefaults(v4)
  }
  const configPath = path.join(__dirname, USER_CONFIG)
  const {WebpackCLI, merge} = getWebpackCli()
  const {options} = await new WebpackCLI().loadConfig({
    config: [configPath],
    argv,
    disableInterpret: argv?.disableInterpret,
  })
  const configs = [].concat(options).map((config) => merge(bazelDefaults(v4), config))
  return Array.isArray(options) ? configs : configs[0]
}
