const path = require("path");

module.exports = (_env, options) => {
    return {
        entry: {
            index: path.resolve(__dirname, "src/index.ts"),
        },
        output: {
            path: path.resolve(__dirname, "dist"),
            filename: "[name].bundle.js",

            // Alternative and webpack5 default:
            // futureEmitAssets: true,
        },
        module: {
            rules: [
                {
                    test: /\.ts$/,
                    exclude: /node_modules/,
                    use: ["ts-loader"]
                }
            ]
        }
    };
};
