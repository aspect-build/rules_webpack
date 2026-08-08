// Thin entry point for rspack worker mode.
// The Bazel macro copies this and bundler_worker.js side-by-side with matching
// name prefixes (e.g. _mybundle_webpack_worker.js + _mybundle_bundler_worker.js).
const { main } = require(
  __filename.replace(/_webpack_worker\.js$/, '_bundler_worker.js')
)
main(require('@rspack/cli').RspackCLI, true)
