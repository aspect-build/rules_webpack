const HtmlWebpackPlugin = require('html-webpack-plugin')

module.exports = {
  plugins: [
    new HtmlWebpackPlugin({
      template: __dirname + '/index.html',
    }),
  ],
  entry: {
    main: './app.js',
  },
}
