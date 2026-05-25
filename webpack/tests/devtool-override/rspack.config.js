'use strict'

module.exports = {
  devtool: 'inline-cheap-source-map',
  entry: {
    'rspack-bundle': './webpack/tests/devtool-override/index.js',
  },
}
