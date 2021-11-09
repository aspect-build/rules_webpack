<!-- Generated with Stardoc: http://skydoc.bazel.build -->

webpack_dev_server macro

<a id="#webpack_dev_server"></a>

## webpack_dev_server

<pre>
webpack_dev_server(<a href="#webpack_dev_server-name">name</a>, <a href="#webpack_dev_server-webpack_config">webpack_config</a>, <a href="#webpack_dev_server-args">args</a>, <a href="#webpack_dev_server-data">data</a>, <a href="#webpack_dev_server-_ibazel_webpack_plugin">_ibazel_webpack_plugin</a>, <a href="#webpack_dev_server-_webpack_entry_point">_webpack_entry_point</a>,
                   <a href="#webpack_dev_server-kwargs">kwargs</a>)
</pre>

Use webpack with a development server that provides live reloading. This should be used for development only.

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="webpack_dev_server-name"></a>name |  The name of the dev server target.   |  none |
| <a id="webpack_dev_server-webpack_config"></a>webpack_config |  Webpack configuration file.<br><br>See https://webpack.js.org/configuration/   |  none |
| <a id="webpack_dev_server-args"></a>args |  Command line arguments to pass to Webpack.<br><br>These argument passed on the command line before arguments that are added by the rule. Run <code>bazel</code> with <code>--subcommands</code> to see what Webpack CLI command line was invoked.<br><br>See the [Webpack CLI docs](https://webpack.js.org/api/cli/) for a complete list of supported arguments.   |  <code>[]</code> |
| <a id="webpack_dev_server-data"></a>data |  Runtime dependencies which may be loaded during compliation.   |  <code>[]</code> |
| <a id="webpack_dev_server-_ibazel_webpack_plugin"></a>_ibazel_webpack_plugin |  Inernal use only. Webpack plugin used as a communication layer between ibazel's build event signalling semantics and webpacks file watching semantics.   |  <code>Label("//@aspect-build/webpack/webpack-dev-server:webpack.config.js")</code> |
| <a id="webpack_dev_server-_webpack_entry_point"></a>_webpack_entry_point |  Internal use only. Entry point shim used to launch the webpack-cli in serve mode.   |  <code>Label("//@aspect-build/webpack/webpack-dev-server:entry_point.js")</code> |
| <a id="webpack_dev_server-kwargs"></a>kwargs |  passed through to <code>nodejs_binary</code>   |  none |


