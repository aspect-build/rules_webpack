const path = require("path");
const MiniCssExtractPlugin = require("mini-css-extract-plugin");

module.exports = (_env, options) => {
    return {
        entry: {
            styles: path.resolve(process.cwd(), "src/component.js")
        },
        output: {
            path: path.resolve(process.cwd(), "dist"),
            filename: "[name].bundle.js"
        },
        plugins: [
            new MiniCssExtractPlugin(),
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
                        "css-loader"
                    ],
                }
            ]
        }
    };
};
