<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Public API surface is re-exported here.

Users should not load files under "/internal"


<a id="webpack_bundle"></a>

## webpack_bundle

<pre>
webpack_bundle(<a href="#webpack_bundle-name">name</a>, <a href="#webpack_bundle-args">args</a>, <a href="#webpack_bundle-chdir">chdir</a>, <a href="#webpack_bundle-data">data</a>, <a href="#webpack_bundle-deps">deps</a>, <a href="#webpack_bundle-entry_point">entry_point</a>, <a href="#webpack_bundle-entry_points">entry_points</a>, <a href="#webpack_bundle-env">env</a>, <a href="#webpack_bundle-output_dir">output_dir</a>, <a href="#webpack_bundle-srcs">srcs</a>,
               <a href="#webpack_bundle-supports_workers">supports_workers</a>, <a href="#webpack_bundle-webpack">webpack</a>, <a href="#webpack_bundle-webpack_config">webpack_config</a>, <a href="#webpack_bundle-webpack_worker">webpack_worker</a>)
</pre>

Runs the webpack-cli under bazel.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="webpack_bundle-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="webpack_bundle-args"></a>args |  Command line arguments to pass to Webpack.<br><br>These argument passed on the command line before arguments that are added by the rule. Run <code>bazel</code> with <code>--subcommands</code> to see what Webpack CLI command line was invoked.<br><br>See the [Webpack CLI docs](https://webpack.js.org/api/cli/) for a complete list of supported arguments.   | List of strings | optional | <code>[]</code> |
| <a id="webpack_bundle-chdir"></a>chdir |  Working directory to run Webpack under.<br><br>        This is needed to workaround some buggy resolvers in webpack loaders, which assume that the         node_modules tree is located in a parent of the working directory rather than a parent of         the script with the require statement.<br><br>        Note that any relative paths in your configuration may need to be adjusted so they are         relative to the new working directory.<br><br>        See also:         https://github.com/aspect-build/rules_js/blob/main/docs/js_binary.md#js_binary-chdir   | String | optional | <code>""</code> |
| <a id="webpack_bundle-data"></a>data |  Runtime dependencies to include in binaries/tests that depend on this target.<br><br>    The transitive npm dependencies, transitive sources, default outputs and runfiles of targets in the <code>data</code> attribute     are added to the runfiles of this target. They should appear in the '*.runfiles' area of any executable which has     a runtime dependency on this target.<br><br>    If this list contains linked npm packages, npm package store targets or other targets that provide <code>JsInfo</code>, <code>NpmPackageStoreInfo</code> providers are gathered from <code>JsInfo</code>. This is done directly from the <code>npm_package_store_deps</code> field of these. For linked npm package targets, the underlying <code>npm_package_store</code> target(s) that back the links is used. Gathered <code>NpmPackageStoreInfo</code> providers are propagated to the direct dependencies of downstream linked <code>npm_package</code> targets.<br><br>NB: Linked npm package targets that are "dev" dependencies do not forward their underlying <code>npm_package_store</code> target(s) through <code>npm_package_store_deps</code> and will therefore not be propagated to the direct dependencies of downstream linked <code>npm_package</code> targets. npm packages that come in from <code>npm_translate_lock</code> are considered "dev" dependencies if they are have <code>dev: true</code> set in the pnpm lock file. This should be all packages that are only listed as "devDependencies" in all <code>package.json</code> files within the pnpm workspace. This behavior is intentional to mimic how <code>devDependencies</code> work in published npm packages.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |
| <a id="webpack_bundle-deps"></a>deps |  Runtime dependencies which may be loaded during compilation.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |
| <a id="webpack_bundle-entry_point"></a>entry_point |  The point or points where to start the application bundling process.<br><br>See https://webpack.js.org/concepts/entry-points/   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="webpack_bundle-entry_points"></a>entry_points |  -   | <a href="https://bazel.build/rules/lib/dict">Dictionary: Label -> String</a> | optional | <code>{}</code> |
| <a id="webpack_bundle-env"></a>env |  Environment variables of the action.<br><br>        Subject to <code>$(location)</code> and make variable expansion.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> String</a> | optional | <code>{}</code> |
| <a id="webpack_bundle-output_dir"></a>output_dir |  -   | Boolean | optional | <code>False</code> |
| <a id="webpack_bundle-srcs"></a>srcs |  Non-entry point JavaScript source files from the workspace. You must not repeat file(s) passed to entry_point/entry_points.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |
| <a id="webpack_bundle-supports_workers"></a>supports_workers |  Experimental! Use only with caution.<br><br>Allows you to enable the Bazel Worker strategy for this library.   | Boolean | optional | <code>False</code> |
| <a id="webpack_bundle-webpack"></a>webpack |  Target that executes the webpack-cli binary   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>@webpack//:webpack</code> |
| <a id="webpack_bundle-webpack_config"></a>webpack_config |  Webpack configuration file.<br><br>See https://webpack.js.org/configuration/   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="webpack_bundle-webpack_worker"></a>webpack_worker |  Target that executes the webpack-cli binary as a worker   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>@webpack//:worker</code> |


<a id="webpack_devserver"></a>

## webpack_devserver

<pre>
webpack_devserver(<a href="#webpack_devserver-name">name</a>, <a href="#webpack_devserver-webpack_config">webpack_config</a>, <a href="#webpack_devserver-args">args</a>, <a href="#webpack_devserver-data">data</a>, <a href="#webpack_devserver-mode">mode</a>, <a href="#webpack_devserver-webpack">webpack</a>, <a href="#webpack_devserver-kwargs">kwargs</a>)
</pre>

Runs the webpack devserver.

This is a macro that uses
[js_run_devserver](https://github.com/aspect-build/rules_js/blob/main/docs/js_run_devserver.md)
under the hood.


**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="webpack_devserver-name"></a>name |  A unique name for this target.   |  none |
| <a id="webpack_devserver-webpack_config"></a>webpack_config |  Webpack configuration file. See https://webpack.js.org/configuration/.   |  none |
| <a id="webpack_devserver-args"></a>args |  Additional arguments to pass to webpack.<br><br>The <code>serve</code> command, the webpack config file (<code>--config</code>) and the mode (<code>--mode</code>) are automatically set.   |  <code>[]</code> |
| <a id="webpack_devserver-data"></a>data |  Runtime dependencies of the program.<br><br>The webpack config is automatically passed to data.   |  <code>[]</code> |
| <a id="webpack_devserver-mode"></a>mode |  The mode to pass to <code>--mode</code>.   |  <code>"development"</code> |
| <a id="webpack_devserver-webpack"></a>webpack |  The webpack js_binary to use.   |  <code>"@webpack//:webpack"</code> |
| <a id="webpack_devserver-kwargs"></a>kwargs |  Additional arguments. See [js_run_devserver](https://github.com/aspect-build/rules_js/blob/main/docs/js_run_devserver.md).   |  none |


