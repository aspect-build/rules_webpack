const HtmlWebpackPlugin = require('html-webpack-plugin')

/** @type {import("webpack").Configuration} */
module.exports = {
  plugins: [
    new HtmlWebpackPlugin({
      template: __dirname + '/index.html',
    }),
  ],
  
}
