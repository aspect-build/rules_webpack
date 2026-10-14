const path = require('path')
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
    entry: {"entry":"./webpack/tests/create_configs/entry.js"},
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

async function loadUserConfig(configPath) {
  if (!configPath.endsWith('.mjs')) {
    // Drop any cached copy so that a long-lived process, such as a persistent
    // worker, picks up changes to the config.
    delete require.cache[require.resolve(configPath)]
    try {
      return require(configPath)
    } catch (e) {
      if (e.code !== 'ERR_REQUIRE_ESM') {
        throw e
      }
    }
  }
  const mod = await import(pathToFileURL(configPath).href)
  return mod.default !== undefined ? mod.default : mod
}

// Resolves a config the same way webpack-cli does: it may be a function of
// (env, argv) and/or a promise.
async function resolveConfig(config, env, argv) {
  if (typeof config === 'function') {
    config = config(env, argv)
  }
  return await config
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
  const userConfig = await resolveConfig(
    await loadUserConfig(path.join(__dirname, USER_CONFIG)),
    env,
    argv
  )
  if (Array.isArray(userConfig)) {
    const configs = await Promise.all(
      userConfig.map((config) => resolveConfig(config, env, argv))
    )
    return configs.map((config) => merge(bazelDefaults(v4), config))
  }
  return merge(bazelDefaults(v4), userConfig)
}
