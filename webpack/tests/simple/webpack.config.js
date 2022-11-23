if (process.env.MY_ENV != 'webpack/tests/simple/index.js') {
  console.error(
    'ERROR: expected process.env.MY_ENV to be webpack/tests/simple/index.js'
  )
  process.exit(1)
}

module.exports = (env, argv) => ({})
