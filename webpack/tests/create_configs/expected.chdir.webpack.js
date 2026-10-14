const path = require('path')
const {createRequire} = require('module')
const {pathToFileURL} = require('url')

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
    entry: {"bar.js":"./bar","foo.js":"./foo"},
  }
}

function isPlainObject(value) {
  if (value === null || typeof value !== 'object') {
    return false
  }
  const proto = Object.getPrototypeOf(value)
  return proto === Object.prototype || proto === null
}

// Merges `user` on top of `base` with the same semantics as webpack-merge's
// default merge: plain objects are merged recursively, arrays are
// concatenated and any other value in `user` takes precedence.
function merge(base, user) {
  const result = {...base}
  for (const [key, value] of Object.entries(user)) {
    if (value === undefined) {
      continue
    }
    const prev = result[key]
    if (Array.isArray(prev) && Array.isArray(value)) {
      result[key] = [...prev, ...value]
    } else if (isPlainObject(prev) && isPlainObject(value)) {
      result[key] = merge(prev, value)
    } else {
      result[key] = value
    }
  }
  return result
}

// Returns a `require` that resolves modules from webpack-cli's location, as the
// packages it uses (e.g. interpret, rechoir) are not necessarily resolvable
// from here. webpack-cli is always loaded, since it is what loads this config.
function webpackCliRequire() {
  const cliPath = Object.keys(require.cache).find((p) =>
    /[\\/]webpack-cli[\\/]lib[\\/]webpack-cli\.js$/.test(p)
  )
  return cliPath ? createRequire(cliPath) : require
}

// Registers a loader (e.g. ts-node) for config files that Node can't load
// natively, such as .ts, the same way webpack-cli does for `--config`.
function registerInterpreter(configPath, argv) {
  if (argv && argv.disableInterpret) {
    return
  }
  const cliRequire = webpackCliRequire()
  const interpret = cliRequire('interpret')
  const ext = path.extname(configPath).toLowerCase()
  if (ext in interpret.jsVariants || ext === '.cts') {
    // Throws a helpful error listing the packages to install if no loader is
    // available.
    cliRequire('rechoir').prepare(interpret.extensions, configPath)
  }
}

// Loads the user config the same way webpack-cli loads a `--config` file.
async function loadUserConfig(configPath, argv) {
  const ext = path.extname(configPath).toLowerCase()
  if (!['.js', '.cjs', '.mjs'].includes(ext)) {
    registerInterpreter(configPath, argv)
  }
  let config
  if (ext !== '.mjs' && ext !== '.mts') {
    // Drop any cached copy so that a long-lived process, such as a persistent
    // worker, picks up changes to the config.
    delete require.cache[require.resolve(configPath)]
    try {
      config = require(configPath)
    } catch (e) {
      if (e.code !== 'ERR_REQUIRE_ESM' || ext === '.cjs' || ext === '.cts') {
        throw e
      }
    }
  }
  if (config === undefined) {
    config = (await import(pathToFileURL(configPath).href)).default
  } else if (config && typeof config === 'object' && 'default' in config) {
    // Transpiled ESM (`exports.default = ...`) or an ES module loaded via
    // require().
    config = config.default
  }
  return config
}

// Resolves a config the same way webpack-cli does: it may be a function of
// (env, argv) and/or a promise.
async function resolveConfig(config, env, argv, configPath) {
  if (typeof config === 'function') {
    config = config(env, argv)
  }
  config = await config
  if (!config || typeof config !== 'object') {
    throw new Error(
      `Failed to load '${configPath}' config: expected an object or array of objects, got ${config}.`
    )
  }
  return config
}

// Applies the Bazel defaults to a config from the user config file.
function withDefaults(defaults, config, configPath) {
  const result = merge(defaults, config)
  // webpack-cli only adds the `--config` file (this one) to the filesystem
  // cache's build dependencies, so add the user config too.
  const cache = result.cache
  if (cache && typeof cache === 'object' && cache.type === 'filesystem') {
    const buildDependencies = cache.buildDependencies || {}
    result.cache = {
      ...cache,
      buildDependencies: {
        ...buildDependencies,
        defaultConfig: [...(buildDependencies.defaultConfig || []), configPath],
      },
    }
  }
  return result
}

// Instead of passing the user config to webpack-cli alongside this one and
// using `--merge`, which collapses multi-compiler configs (arrays) into a
// single config, load the user config here and merge the defaults into each
// of its configs.
module.exports = async function (env, argv) {
  const v4 = isWebpackCli4()
  if (USER_CONFIG === null) {
    return bazelDefaults(v4)
  }
  const configPath = path.join(__dirname, USER_CONFIG)
  const userConfig = await resolveConfig(
    await loadUserConfig(configPath, argv),
    env,
    argv,
    configPath
  )
  if (Array.isArray(userConfig)) {
    const configs = await Promise.all(
      userConfig.map((config) => resolveConfig(config, env, argv, configPath))
    )
    return configs.map((config) => withDefaults(bazelDefaults(v4), config, configPath))
  }
  return withDefaults(bazelDefaults(v4), userConfig, configPath)
}
