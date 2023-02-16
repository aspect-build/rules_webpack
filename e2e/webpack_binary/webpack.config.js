const webpack = require('webpack')

module.exports = {
  plugins: [
    // Using this plugin will result in the error:
    //
    //  `TypeError: The 'compilation' argument must be an instance of Compilation`
    //
    // ...due to the webpack config being constructed in rules_webpack's copy of webpack,
    // and the plugin code executing in the user's linked version of webpack.
    //
    // See relevant snippet:
    // https://github.com/webpack/webpack/blob/cd3ec1da92450c2c9878bb05a89f9f623c637d65/lib/javascript/JavascriptModulesPlugin.js#L142
    //
    // This can be avoided by explicitly using the user's linked version of webpack deps
    // using the `webpack_binary` macro and passing the binary into the `webpack` attr
    // of `webpack_bundle`.

    new webpack.SourceMapDevToolPlugin(),
  ],
}
