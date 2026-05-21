module.exports = function () {
  const v4 = new Error().stack.includes('webpack-cli@4.')

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

  // Set by the Bazel rule at action execution time so the target platform's
  // compilation mode is reflected. Defined here (not as CLI flags) so that
  // user-provided configs merged after this one can override them.
  const mode = process.env.WEBPACK_MODE
  const devtool = process.env.WEBPACK_DEVTOOL

  return {
    infrastructureLogging,
    optimization,
    output,
    ...(mode ? {mode} : {}),
    ...(devtool ? {devtool} : {}),
    entry: {"bar.js":"./webpack/tests/create_configs/bar","foo.js":"./webpack/tests/create_configs/foo"},
  }
}
