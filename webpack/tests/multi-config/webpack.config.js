const path = require('path')

// A multi-compiler config. Each config aliases `dep` to a different module, so
// the bundles only come out right if the configs are kept separate rather than
// merged into one. Paths are relative to the working directory (chdir).
module.exports = [
  {
    name: 'a',
    mode: 'production',
    devtool: false,
    entry: {a: './a.js'},
    resolve: {alias: {dep: path.resolve('dep-a.js')}},
  },
  (env, argv) => ({
    name: 'b',
    mode: 'production',
    devtool: false,
    entry: {b: './b.js'},
    resolve: {alias: {dep: path.resolve('dep-b.js')}},
  }),
]
