class IBazelPlugin {
  /** @param compiler {import("webpack").Compiler} */
  apply(compiler) {

    let running = false;

    compiler.hooks.done.tap('WebpackBazelPlugin', () => {
      if (!running) {
        compiler.watching.suspend();
      }
      running = false;
    });

    compiler.hooks.watchRun.tap("WebpackBazelPlugin", () => {
      running = true;
    })

    process.stdin.on('data', (chunk) => {
      const chunkString = chunk.toString();
      if (chunkString.indexOf('IBAZEL_BUILD_COMPLETED SUCCESS') !== -1) {
        compiler.watching.resume();
      } else if (chunkString.indexOf('IBAZEL_BUILD_STARTED') !== -1) {
        compiler.watching.suspend();
      }
    });
  }
}

module.exports = {
  plugins: [new IBazelPlugin()],
  watchOptions: {
    poll: true,
  },
};
