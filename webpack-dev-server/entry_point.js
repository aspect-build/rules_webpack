const { spawn } = require('child_process');

const webpack = require.resolve('webpack/bin/webpack.js');
console.log(`${webpack}\n  ${process.argv.slice(2).join('\n  ')}\n`);

spawn(process.argv[0], [
    webpack,
    ...process.argv.slice(2)
], {
    stdio: 'inherit'
});