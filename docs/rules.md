<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Public API surface is re-exported here.

Users should not load files under "/internal"

<a id="webpack_bundle"></a>

## webpack_bundle

<pre>
webpack_bundle(<a href="#webpack_bundle-name">name</a>, <a href="#webpack_bundle-node_modules">node_modules</a>, <a href="#webpack_bundle-srcs">srcs</a>, <a href="#webpack_bundle-args">args</a>, <a href="#webpack_bundle-deps">deps</a>, <a href="#webpack_bundle-chdir">chdir</a>, <a href="#webpack_bundle-data">data</a>, <a href="#webpack_bundle-env">env</a>, <a href="#webpack_bundle-output_dir">output_dir</a>, <a href="#webpack_bundle-entry_point">entry_point</a>,
               <a href="#webpack_bundle-entry_points">entry_points</a>, <a href="#webpack_bundle-webpack_config">webpack_config</a>, <a href="#webpack_bundle-configure_mode">configure_mode</a>, <a href="#webpack_bundle-configure_devtool">configure_devtool</a>,
               <a href="#webpack_bundle-use_execroot_entry_point">use_execroot_entry_point</a>, <a href="#webpack_bundle-supports_workers">supports_workers</a>, <a href="#webpack_bundle-kwargs">kwargs</a>)
</pre>

Runs the webpack-cli under bazel

**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="webpack_bundle-name"></a>name |  A unique name for this target.   |  none |
| <a id="webpack_bundle-node_modules"></a>node_modules |  Label pointing to the linked node_modules target where webpack is linked, e.g. `//:node_modules`.<br><br>The following packages must be linked into the node_modules supplied:<br><br>    webpack, webpack-cli   |  none |
| <a id="webpack_bundle-srcs"></a>srcs |  Non-entry point JavaScript source files from the workspace.<br><br>You must not repeat file(s) passed to entry_point/entry_points.   |  `[]` |
| <a id="webpack_bundle-args"></a>args |  Command line arguments to pass to Webpack.<br><br>These argument passed on the command line before arguments that are added by the rule. Run `bazel` with `--subcommands` to see what Webpack CLI command line was invoked.<br><br>See the [Webpack CLI docs](https://webpack.js.org/api/cli/) for a complete list of supported arguments.   |  `[]` |
| <a id="webpack_bundle-deps"></a>deps |  Runtime dependencies which may be loaded during compilation.   |  `[]` |
| <a id="webpack_bundle-chdir"></a>chdir |  Working directory to run Webpack under.<br><br>This is needed to workaround some buggy resolvers in webpack loaders, which assume that the node_modules tree is located in a parent of the working directory rather than a parent of the script with the require statement.<br><br>Note that any relative paths in your configuration may need to be adjusted so they are relative to the new working directory.<br><br>See also: https://github.com/aspect-build/rules_js/blob/main/docs/js_binary.md#js_binary-chdir   |  `None` |
| <a id="webpack_bundle-data"></a>data |  Runtime dependencies to include in binaries/tests that depend on this target.<br><br>The transitive npm dependencies, transitive sources, default outputs and runfiles of targets in the `data` attribute are added to the runfiles of this target. They should appear in the '*.runfiles' area of any executable which has a runtime dependency on this target.   |  `[]` |
| <a id="webpack_bundle-env"></a>env |  Environment variables of the action.<br><br>Subject to `$(location)` and make variable expansion.   |  `{}` |
| <a id="webpack_bundle-output_dir"></a>output_dir |  If True, webpack produces an output directory containing all output files.   |  `False` |
| <a id="webpack_bundle-entry_point"></a>entry_point |  The point where to start the application bundling process.<br><br>See https://webpack.js.org/concepts/entry-points/<br><br>Exactly one of `entry_point` to `entry_points` must be specified if `output_dir` is `False`.   |  `None` |
| <a id="webpack_bundle-entry_points"></a>entry_points |  The map of entry points to bundle names.<br><br>See https://webpack.js.org/concepts/entry-points/<br><br>Exactly one of `entry_point` to `entry_points` must be specified if `output_dir` is `False`.   |  `{}` |
| <a id="webpack_bundle-webpack_config"></a>webpack_config |  Webpack configuration file.<br><br>See https://webpack.js.org/configuration/   |  `None` |
| <a id="webpack_bundle-configure_mode"></a>configure_mode |  Configure `mode` in the generated base webpack config.<br><br>`mode` is set to `production` if the Bazel compilation mode is `opt` otherwise it is set to `development`.<br><br>The configured value will be overridden if it is set in a supplied `webpack_config`.<br><br>See https://bazel.build/docs/user-manual#compilation-mode for more info on how to configure the compilation mode.   |  `True` |
| <a id="webpack_bundle-configure_devtool"></a>configure_devtool |  Configure `devtool` in the generated base webpack config.<br><br>`devtool` is set to `eval` if the Bazel compilation mode is `fastbuild`, `eval-source-map` if the Bazel compilation mode is `dbg`, otherwise it is left unset.<br><br>The configured value will be overridden if it is set in a supplied `webpack_config`.<br><br>See https://bazel.build/docs/user-manual#compilation-mode for more info on how to configure the compilation mode.   |  `True` |
| <a id="webpack_bundle-use_execroot_entry_point"></a>use_execroot_entry_point |  Use the `entry_point` script of the `webpack` `js_binary` that is in the execroot output tree instead of the copy that is in runfiles.<br><br>When set, runfiles are hoisted to the target platform when this is configured and included as target platform execroot inputs to the action.<br><br>Using the entry point script that is in the execroot output tree means that there will be no conflicting runfiles `node_modules` in the node_modules resolution path which can confuse npm packages such as next and react that don't like being resolved in multiple node_modules trees. This more closely emulates the environment that tools such as Next.js see when they are run outside of Bazel.   |  `True` |
| <a id="webpack_bundle-supports_workers"></a>supports_workers |  Experimental! Use only with caution.<br><br>Allows you to enable the Bazel Worker strategy for this library.   |  `False` |
| <a id="webpack_bundle-kwargs"></a>kwargs |  Additional arguments   |  none |


<a id="webpack_devserver"></a>

## webpack_devserver

<pre>
webpack_devserver(<a href="#webpack_devserver-name">name</a>, <a href="#webpack_devserver-node_modules">node_modules</a>, <a href="#webpack_devserver-chdir">chdir</a>, <a href="#webpack_devserver-env">env</a>, <a href="#webpack_devserver-entry_point">entry_point</a>, <a href="#webpack_devserver-entry_points">entry_points</a>, <a href="#webpack_devserver-webpack_config">webpack_config</a>,
                  <a href="#webpack_devserver-configure_mode">configure_mode</a>, <a href="#webpack_devserver-configure_devtool">configure_devtool</a>, <a href="#webpack_devserver-args">args</a>, <a href="#webpack_devserver-data">data</a>, <a href="#webpack_devserver-mode">mode</a>, <a href="#webpack_devserver-kwargs">kwargs</a>)
</pre>

Runs the webpack devserver.

This is a macro that uses
[js_run_devserver](https://github.com/aspect-build/rules_js/blob/main/docs/js_run_devserver.md)
under the hood.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="webpack_devserver-name"></a>name |  A unique name for this target.   |  none |
| <a id="webpack_devserver-node_modules"></a>node_modules |  Label pointing to the linked node_modules target where webpack is linked, e.g. `//:node_modules`.<br><br>The following packages must be linked into the node_modules supplied:<br><br>    webpack, webpack-cli, webpack-dev-server   |  none |
| <a id="webpack_devserver-chdir"></a>chdir |  Working directory to run Webpack under.<br><br>This is needed to workaround some buggy resolvers in webpack loaders, which assume that the node_modules tree is located in a parent of the working directory rather than a parent of the script with the require statement.<br><br>Note that any relative paths in your configuration may need to be adjusted so they are relative to the new working directory.<br><br>See also: https://github.com/aspect-build/rules_js/blob/main/docs/js_binary.md#js_binary-chdir   |  `None` |
| <a id="webpack_devserver-env"></a>env |  Environment variables of the action.<br><br>Subject to `$(location)` and make variable expansion.   |  `{}` |
| <a id="webpack_devserver-entry_point"></a>entry_point |  The point where to start the application bundling process.<br><br>See https://webpack.js.org/concepts/entry-points/<br><br>Only one of `entry_point` to `entry_points` must be specified.   |  `None` |
| <a id="webpack_devserver-entry_points"></a>entry_points |  The map of entry points to bundle names.<br><br>See https://webpack.js.org/concepts/entry-points/<br><br>Only one of `entry_point` to `entry_points` must be specified.   |  `{}` |
| <a id="webpack_devserver-webpack_config"></a>webpack_config |  Webpack configuration file. See https://webpack.js.org/configuration/.   |  `None` |
| <a id="webpack_devserver-configure_mode"></a>configure_mode |  Configure `mode` in the generated base webpack config.<br><br>`mode` is set to `production` if the Bazel compilation mode is `opt` otherwise it is set to `development`.<br><br>The configured value will be overridden if it is set in a supplied `webpack_config`.<br><br>See https://bazel.build/docs/user-manual#compilation-mode for more info on how to configure the compilation mode.   |  `True` |
| <a id="webpack_devserver-configure_devtool"></a>configure_devtool |  Configure `devtool` in the generated base webpack config.<br><br>`devtool` is set to `eval` if the Bazel compilation mode is `fastbuild`, `eval-source-map` if the Bazel compilation mode is `dbg`, otherwise it is left unset.<br><br>The configured value will be overridden if it is set in a supplied `webpack_config`.<br><br>See https://bazel.build/docs/user-manual#compilation-mode for more info on how to configure the compilation mode.   |  `True` |
| <a id="webpack_devserver-args"></a>args |  Additional arguments to pass to webpack.<br><br>The `serve` command, the webpack config file (`--config`) and the mode (`--mode`) are automatically set.   |  `[]` |
| <a id="webpack_devserver-data"></a>data |  Bundle and runtime dependencies of the program.<br><br>Should include the `webpack_bundle` rule `srcs` and `deps`.<br><br>The webpack config and entry_point[s] are automatically passed to data and should not be repeated.   |  `[]` |
| <a id="webpack_devserver-mode"></a>mode |  The mode to pass to `--mode`.   |  `"development"` |
| <a id="webpack_devserver-kwargs"></a>kwargs |  Additional arguments. See [js_run_devserver](https://github.com/aspect-build/rules_js/blob/main/docs/js_run_devserver.md).   |  none |


