/** @type {import("webpack").Configuration} */
module.exports = {
  entry: { ENTRIES },
  infrastructureLogging: {
    colors: false,
    console: new console.Console(process.stderr, process.stderr),
    level: "error"
  },
  stats: "errors-only",
  cache: {
    type: "memory"
  },
  // We want webpack to spit out deterministic file hashes 
  // this will improve remote caching
  // https://webpack.js.org/guides/caching/#module-identifiers
  optimization: {
    moduleIds: "deterministic",
    chunkIds: "deterministic",
  }
}
