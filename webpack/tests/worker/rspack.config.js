module.exports = {
  infrastructureLogging: {
    debug: true,
  },
  stats: {
    loggingDebug: true,
    logging: true,
  },
  entry: {
    'rspack-bundle': './webpack/tests/worker/index.js',
  },
}
