const { spawn } = require('child_process');

const webpack = require.resolve('webpack/bin/webpack.js');

spawn(process.argv[0], [
    webpack,
    ...process.argv.slice(2)
], {
    stdio: 'inherit'
});