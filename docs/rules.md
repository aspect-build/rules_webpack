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
| <a id="webpack_bundle-node_modules"></a>node_modules |  Label pointing to the linked node_modules target where webpack is linked, e.g. <code>//:node_modules</code>.<br><br>The following packages must be linked into the node_modules supplied:<br><br>    webpack, webpack-cli   |  none |
| <a id="webpack_bundle-srcs"></a>srcs |  Non-entry point JavaScript source files from the workspace.<br><br>You must not repeat file(s) passed to entry_point/entry_points.   |  <code>[]</code> |
| <a id="webpack_bundle-args"></a>args |  Command line arguments to pass to Webpack.<br><br>These argument passed on the command line before arguments that are added by the rule. Run <code>bazel</code> with <code>--subcommands</code> to see what Webpack CLI command line was invoked.<br><br>See the [Webpack CLI docs](https://webpack.js.org/api/cli/) for a complete list of supported arguments.   |  <code>[]</code> |
| <a id="webpack_bundle-deps"></a>deps |  Runtime dependencies which may be loaded during compilation.   |  <code>[]</code> |
| <a id="webpack_bundle-chdir"></a>chdir |  Working directory to run Webpack under.<br><br>This is needed to workaround some buggy resolvers in webpack loaders, which assume that the node_modules tree is located in a parent of the working directory rather than a parent of the script with the require statement.<br><br>Note that any relative paths in your configuration may need to be adjusted so they are relative to the new working directory.<br><br>See also: https://github.com/aspect-build/rules_js/blob/main/docs/js_binary.md#js_binary-chdir   |  <code>None</code> |
| <a id="webpack_bundle-data"></a>data |  Runtime dependencies to include in binaries/tests that depend on this target.<br><br>The transitive npm dependencies, transitive sources, default outputs and runfiles of targets in the <code>data</code> attribute are added to the runfiles of this target. They should appear in the '*.runfiles' area of any executable which has a runtime dependency on this target.   |  <code>[]</code> |
| <a id="webpack_bundle-env"></a>env |  Environment variables of the action.<br><br>Subject to <code>$(location)</code> and make variable expansion.   |  <code>{}</code> |
| <a id="webpack_bundle-output_dir"></a>output_dir |  If True, webpack produces an output directory containing all output files.   |  <code>False</code> |
| <a id="webpack_bundle-entry_point"></a>entry_point |  The point where to start the application bundling process.<br><br>See https://webpack.js.org/concepts/entry-points/<br><br>Exactly one of <code>entry_point</code> to <code>entry_points</code> must be specified if <code>output_dir</code> is <code>False</code>.   |  <code>None</code> |
| <a id="webpack_bundle-entry_points"></a>entry_points |  The map of entry points to bundle names.<br><br>See https://webpack.js.org/concepts/entry-points/<br><br>Exactly one of <code>entry_point</code> to <code>entry_points</code> must be specified if <code>output_dir</code> is <code>False</code>.   |  <code>{}</code> |
| <a id="webpack_bundle-webpack_config"></a>webpack_config |  Webpack configuration file.<br><br>See https://webpack.js.org/configuration/   |  <code>None</code> |
| <a id="webpack_bundle-configure_mode"></a>configure_mode |  Configure <code>mode</code> in the generated base webpack config.<br><br><code>mode</code> is set to <code>production</code> if the Bazel compilation mode is <code>opt</code> otherwise it is set to <code>development</code>.<br><br>The configured value will be overridden if it is set in a supplied <code>webpack_config</code>.<br><br>See https://bazel.build/docs/user-manual#compilation-mode for more info on how to configure the compilation mode.   |  <code>True</code> |
| <a id="webpack_bundle-configure_devtool"></a>configure_devtool |  Configure <code>devtool</code> in the generated base webpack config.<br><br><code>devtool</code> is set to <code>eval</code> if the Bazel compilation mode is <code>fastbuild</code>, <code>eval-source-map</code> if the Bazel compilation mode is <code>dbg</code>, otherwise it is left unset.<br><br>The configured value will be overridden if it is set in a supplied <code>webpack_config</code>.<br><br>See https://bazel.build/docs/user-manual#compilation-mode for more info on how to configure the compilation mode.   |  <code>True</code> |
| <a id="webpack_bundle-use_execroot_entry_point"></a>use_execroot_entry_point |  Use the <code>entry_point</code> script of the <code>webpack</code> <code>js_binary</code> that is in the execroot output tree instead of the copy that is in runfiles.<br><br>When set, runfiles are hoisted to the target platform when this is configured and included as target platform execroot inputs to the action.<br><br>Using the entry point script that is in the execroot output tree means that there will be no conflicting runfiles <code>node_modules</code> in the node_modules resolution path which can confuse npm packages such as next and react that don't like being resolved in multiple node_modules trees. This more closely emulates the environment that tools such as Next.js see when they are run outside of Bazel.   |  <code>True</code> |
| <a id="webpack_bundle-supports_workers"></a>supports_workers |  Experimental! Use only with caution.<br><br>Allows you to enable the Bazel Worker strategy for this library.   |  <code>False</code> |
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

When using ibazel, the devserver will automatically reload when the source files change. Note that
ibazel does not work when using bazel `alias` targets, see https://github.com/bazelbuild/bazel-watcher/issues/100.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="webpack_devserver-name"></a>name |  A unique name for this target.   |  none |
| <a id="webpack_devserver-node_modules"></a>node_modules |  Label pointing to the linked node_modules target where webpack is linked, e.g. <code>//:node_modules</code>.<br><br>The following packages must be linked into the node_modules supplied:<br><br>    webpack, webpack-cli, webpack-dev-server   |  none |
| <a id="webpack_devserver-chdir"></a>chdir |  Working directory to run Webpack under.<br><br>This is needed to workaround some buggy resolvers in webpack loaders, which assume that the node_modules tree is located in a parent of the working directory rather than a parent of the script with the require statement.<br><br>Note that any relative paths in your configuration may need to be adjusted so they are relative to the new working directory.<br><br>See also: https://github.com/aspect-build/rules_js/blob/main/docs/js_binary.md#js_binary-chdir   |  <code>None</code> |
| <a id="webpack_devserver-env"></a>env |  Environment variables of the action.<br><br>Subject to <code>$(location)</code> and make variable expansion.   |  <code>{}</code> |
| <a id="webpack_devserver-entry_point"></a>entry_point |  The point where to start the application bundling process.<br><br>See https://webpack.js.org/concepts/entry-points/<br><br>Only one of <code>entry_point</code> to <code>entry_points</code> must be specified.   |  <code>None</code> |
| <a id="webpack_devserver-entry_points"></a>entry_points |  The map of entry points to bundle names.<br><br>See https://webpack.js.org/concepts/entry-points/<br><br>Only one of <code>entry_point</code> to <code>entry_points</code> must be specified.   |  <code>{}</code> |
| <a id="webpack_devserver-webpack_config"></a>webpack_config |  Webpack configuration file. See https://webpack.js.org/configuration/.   |  <code>None</code> |
| <a id="webpack_devserver-configure_mode"></a>configure_mode |  Configure <code>mode</code> in the generated base webpack config.<br><br><code>mode</code> is set to <code>production</code> if the Bazel compilation mode is <code>opt</code> otherwise it is set to <code>development</code>.<br><br>The configured value will be overridden if it is set in a supplied <code>webpack_config</code>.<br><br>See https://bazel.build/docs/user-manual#compilation-mode for more info on how to configure the compilation mode.   |  <code>True</code> |
| <a id="webpack_devserver-configure_devtool"></a>configure_devtool |  Configure <code>devtool</code> in the generated base webpack config.<br><br><code>devtool</code> is set to <code>eval</code> if the Bazel compilation mode is <code>fastbuild</code>, <code>eval-source-map</code> if the Bazel compilation mode is <code>dbg</code>, otherwise it is left unset.<br><br>The configured value will be overridden if it is set in a supplied <code>webpack_config</code>.<br><br>See https://bazel.build/docs/user-manual#compilation-mode for more info on how to configure the compilation mode.   |  <code>True</code> |
| <a id="webpack_devserver-args"></a>args |  Additional arguments to pass to webpack.<br><br>The <code>serve</code> command, the webpack config file (<code>--config</code>) and the mode (<code>--mode</code>) are automatically set.   |  <code>[]</code> |
| <a id="webpack_devserver-data"></a>data |  Bundle and runtime dependencies of the program.<br><br>Should include the <code>webpack_bundle</code> rule <code>srcs</code> and <code>deps</code>.<br><br>The webpack config and entry_point[s] are automatically passed to data and should not be repeated.   |  <code>[]</code> |
| <a id="webpack_devserver-mode"></a>mode |  The mode to pass to <code>--mode</code>.   |  <code>"development"</code> |
| <a id="webpack_devserver-kwargs"></a>kwargs |  Additional arguments. See [js_run_devserver](https://github.com/aspect-build/rules_js/blob/main/docs/js_run_devserver.md).   |  none |


