const path = require('path')
const {createRequire} = require('module')

// Path to the user-supplied webpack config, relative to this file, or null if
// there is none.
const USER_CONFIG = null

function isWebpackCli4() {
  // Must be called synchronously from webpack-cli so that its frames are on the stack.
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
    entry: {"entry":"./webpack/tests/create_configs/entry.js"},
  }
}

// The webpack-cli module that is loading this config, which is always loaded.
// Its packages (e.g. webpack-merge) are not necessarily resolvable from here.
let webpackCli
function getWebpackCli() {
  if (!webpackCli) {
    const cliPath = Object.keys(require.cache).find((p) =>
      /[\\/]webpack-cli[\\/]lib[\\/]webpack-cli\.js$/.test(p)
    )
    const webpackMerge = createRequire(cliPath)('webpack-merge')
    webpackCli = {
      WebpackCLI: require.cache[cliPath].exports,
      merge: webpackMerge.merge || webpackMerge.default || webpackMerge,
    }
  }
  return webpackCli
}

// Applies the Bazel defaults underneath a config from the user config file.
// `configPaths` are the files the config was loaded from.
function withDefaults(defaults, config, configPaths) {
  const {merge} = getWebpackCli()
  const result = merge(defaults, config)
  // webpack-cli only adds the `--config` file (this one) to the filesystem
  // cache's build dependencies, so add the user config files too.
  if (result.cache?.type === 'filesystem') {
    return merge(result, {cache: {buildDependencies: {defaultConfig: configPaths}}})
  }
  return result
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
  // No need to evict the user config from the require cache: it is in the
  // persistent worker's tool inputs, so changing it starts a new worker.
  const configPath = path.join(__dirname, USER_CONFIG)
  const {WebpackCLI} = getWebpackCli()
  // `paths` maps each config to the files it was loaded from, including any
  // configs it extends.
  const {options, path: paths} = await new WebpackCLI().loadConfig({
    config: [configPath],
    argv,
    disableInterpret: argv?.disableInterpret,
  })
  const configs = [].concat(options).map((config) =>
    withDefaults(bazelDefaults(v4), config, [].concat(paths.get(config) || configPath))
  )
  return Array.isArray(options) ? configs : configs[0]
}
