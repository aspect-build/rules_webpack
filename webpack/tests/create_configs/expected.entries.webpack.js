module.exports = {
  infrastructureLogging: {
    colors: false,
    console: new console.Console(process.stderr, process.stderr),
    level: 'error',
  },
  // We want webpack to spit out deterministic file hashes and module ids
  // this will improve remote caching
  // https://webpack.js.org/guides/caching/#module-identifiers
  optimization: {
    moduleIds: 'deterministic',
    chunkIds: 'deterministic',
  },
  output: {
    // We want deterministic sourceMaps among other stuff that depends on the unique name.
    // Default behavior of this field causes non-hermetic behavior. Eg; it looks into package.json
    // which is always present in a non-sandboxed environment.
    // See: https://webpack.js.org/configuration/output/#outputuniquename
    // and https://webpack.js.org/configuration/output/#outputdevtoolmodulefilenametemplate
    uniqueName: process.env.BAZEL_WORKSPACE,
  },
  entry: {"bar.js":"./webpack/tests/create_configs/bar","foo.js":"./webpack/tests/create_configs/foo"},
  devtool: 'eval',
  mode: 'development',
}
