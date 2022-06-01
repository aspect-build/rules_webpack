<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Public API surface is re-exported here.

Users should not load files under "/internal"


<a id="#webpack_bundle"></a>

## webpack_bundle

<pre>
webpack_bundle(<a href="#webpack_bundle-name">name</a>, <a href="#webpack_bundle-args">args</a>, <a href="#webpack_bundle-deps">deps</a>, <a href="#webpack_bundle-entry_point">entry_point</a>, <a href="#webpack_bundle-entry_points">entry_points</a>, <a href="#webpack_bundle-output_dir">output_dir</a>, <a href="#webpack_bundle-srcs">srcs</a>, <a href="#webpack_bundle-supports_workers">supports_workers</a>,
               <a href="#webpack_bundle-webpack">webpack</a>, <a href="#webpack_bundle-webpack_config">webpack_config</a>, <a href="#webpack_bundle-webpack_worker">webpack_worker</a>)
</pre>

Runs the webpack-cli under bazel.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="webpack_bundle-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="webpack_bundle-args"></a>args |  Command line arguments to pass to Webpack.<br><br>These argument passed on the command line before arguments that are added by the rule. Run <code>bazel</code> with <code>--subcommands</code> to see what Webpack CLI command line was invoked.<br><br>See the [Webpack CLI docs](https://webpack.js.org/api/cli/) for a complete list of supported arguments.   | List of strings | optional | [] |
| <a id="webpack_bundle-deps"></a>deps |  Runtime dependencies which may be loaded during compliation.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="webpack_bundle-entry_point"></a>entry_point |  The point or points where to start the application bundling process.<br><br>See https://webpack.js.org/concepts/entry-points/   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| <a id="webpack_bundle-entry_points"></a>entry_points |  -   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: Label -> String</a> | optional | {} |
| <a id="webpack_bundle-output_dir"></a>output_dir |  -   | Boolean | optional | False |
| <a id="webpack_bundle-srcs"></a>srcs |  Non-entry point JavaScript source files from the workspace. You must not repeat file(s) passed to entry_point/entry_points.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="webpack_bundle-supports_workers"></a>supports_workers |  Experimental! Use only with caution.<br><br>Allows you to enable the Bazel Worker strategy for this library.   | Boolean | optional | False |
| <a id="webpack_bundle-webpack"></a>webpack |  Target that executes the webpack-cli binary   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | @webpack//:webpack |
| <a id="webpack_bundle-webpack_config"></a>webpack_config |  Webpack configuration file.<br><br>See https://webpack.js.org/configuration/   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| <a id="webpack_bundle-webpack_worker"></a>webpack_worker |  Target that executes the webpack-cli binary as a worker   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | @webpack//:worker |


<a id="#webpack_dev_server"></a>

## webpack_dev_server

<pre>
webpack_dev_server(<a href="#webpack_dev_server-name">name</a>, <a href="#webpack_dev_server-deps">deps</a>, <a href="#webpack_dev_server-srcs">srcs</a>, <a href="#webpack_dev_server-webpack">webpack</a>, <a href="#webpack_dev_server-webpack_config">webpack_config</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="webpack_dev_server-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="webpack_dev_server-deps"></a>deps |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="webpack_dev_server-srcs"></a>srcs |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="webpack_dev_server-webpack"></a>webpack |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | @webpack |
| <a id="webpack_dev_server-webpack_config"></a>webpack_config |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |


