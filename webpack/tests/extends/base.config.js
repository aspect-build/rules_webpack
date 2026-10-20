// Settings in an extended config take precedence over the Bazel defaults
// (which would otherwise set `mode: 'development'` and `devtool: 'eval'` under
// fastbuild), as they do for the user config itself.
module.exports = {
  mode: 'production',
  devtool: false,
}
