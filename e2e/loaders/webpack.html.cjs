const path = require('path')
const MiniCssExtractPlugin = require('mini-css-extract-plugin')
const HtmlWebpackPlugin = require('html-webpack-plugin')

module.exports = (_env, options) => {
  return {
    entry: {
      styles: path.resolve(__dirname, 'src/component.js'),
    },
    output: {
      path: path.resolve(__dirname, 'dist'),
      filename: '[name].bundle.js',
    },
    plugins: [
      new MiniCssExtractPlugin(),
      new HtmlWebpackPlugin({
        template: path.resolve(__dirname + '/src/index.html'),
      }),
    ],
    module: {
      rules: [
        {
          test: /\.css$/i,
          use: [
            {
              loader: MiniCssExtractPlugin.loader,
              options: {
                esModule: true,
              },
            },
            'css-loader',
          ],
        },
      ],
    },
  }
}
