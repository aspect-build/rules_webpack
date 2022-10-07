<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Public API surface is re-exported here.

Users should not load files under "/internal"


<a id="webpack_bundle"></a>

## webpack_bundle

<pre>
webpack_bundle(<a href="#webpack_bundle-name">name</a>, <a href="#webpack_bundle-args">args</a>, <a href="#webpack_bundle-data">data</a>, <a href="#webpack_bundle-deps">deps</a>, <a href="#webpack_bundle-entry_point">entry_point</a>, <a href="#webpack_bundle-entry_points">entry_points</a>, <a href="#webpack_bundle-output_dir">output_dir</a>, <a href="#webpack_bundle-srcs">srcs</a>,
               <a href="#webpack_bundle-supports_workers">supports_workers</a>, <a href="#webpack_bundle-webpack">webpack</a>, <a href="#webpack_bundle-webpack_config">webpack_config</a>, <a href="#webpack_bundle-webpack_worker">webpack_worker</a>)
</pre>

Runs the webpack-cli under bazel.

**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="webpack_bundle-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="webpack_bundle-args"></a>args |  Command line arguments to pass to Webpack.<br><br>These argument passed on the command line before arguments that are added by the rule. Run <code>bazel</code> with <code>--subcommands</code> to see what Webpack CLI command line was invoked.<br><br>See the [Webpack CLI docs](https://webpack.js.org/api/cli/) for a complete list of supported arguments.   | List of strings | optional | <code>[]</code> |
| <a id="webpack_bundle-data"></a>data |  Runtime dependencies to include in binaries/tests that depend on this target.<br><br>    The transitive npm dependencies, transitive sources, default outputs and runfiles of targets in the <code>data</code> attribute     are added to the runfiles of this taregt. Thery should appear in the '*.runfiles' area of any executable which has     a runtime dependency on this target.<br><br>    If this list contains linked npm packages, npm package store targets or other targets that provide <code>JsInfo</code>,     <code>NpmPackageStoreInfo</code> providers are gathered from <code>JsInfo</code>. This is done directly from the     <code>npm_package_store_deps</code> field of these. For linked npm package targets, the underlying npm_package_store     target(s) that back the links is used.<br><br>    Gathered <code>NpmPackageStoreInfo</code> providers are used downstream as direct dependencies when linking a downstream     <code>npm_package</code> target with <code>npm_link_package</code>.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |
| <a id="webpack_bundle-deps"></a>deps |  Runtime dependencies which may be loaded during compliation.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |
| <a id="webpack_bundle-entry_point"></a>entry_point |  The point or points where to start the application bundling process.<br><br>See https://webpack.js.org/concepts/entry-points/   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="webpack_bundle-entry_points"></a>entry_points |  -   | <a href="https://bazel.build/rules/lib/dict">Dictionary: Label -> String</a> | optional | <code>{}</code> |
| <a id="webpack_bundle-output_dir"></a>output_dir |  -   | Boolean | optional | <code>False</code> |
| <a id="webpack_bundle-srcs"></a>srcs |  Non-entry point JavaScript source files from the workspace. You must not repeat file(s) passed to entry_point/entry_points.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |
| <a id="webpack_bundle-supports_workers"></a>supports_workers |  Experimental! Use only with caution.<br><br>Allows you to enable the Bazel Worker strategy for this library.   | Boolean | optional | <code>False</code> |
| <a id="webpack_bundle-webpack"></a>webpack |  Target that executes the webpack-cli binary   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>@webpack//:webpack</code> |
| <a id="webpack_bundle-webpack_config"></a>webpack_config |  Webpack configuration file.<br><br>See https://webpack.js.org/configuration/   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |
| <a id="webpack_bundle-webpack_worker"></a>webpack_worker |  Target that executes the webpack-cli binary as a worker   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>@webpack//:worker</code> |


<a id="webpack_dev_server_rule"></a>

## webpack_dev_server_rule

<pre>
webpack_dev_server_rule(<a href="#webpack_dev_server_rule-name">name</a>, <a href="#webpack_dev_server_rule-chdir">chdir</a>, <a href="#webpack_dev_server_rule-copy_data_to_bin">copy_data_to_bin</a>, <a href="#webpack_dev_server_rule-data">data</a>, <a href="#webpack_dev_server_rule-enable_runfiles">enable_runfiles</a>, <a href="#webpack_dev_server_rule-entry_point">entry_point</a>, <a href="#webpack_dev_server_rule-env">env</a>,
                        <a href="#webpack_dev_server_rule-expected_exit_code">expected_exit_code</a>, <a href="#webpack_dev_server_rule-include_declarations">include_declarations</a>, <a href="#webpack_dev_server_rule-include_npm_linked_packages">include_npm_linked_packages</a>,
                        <a href="#webpack_dev_server_rule-include_transitive_sources">include_transitive_sources</a>, <a href="#webpack_dev_server_rule-log_level">log_level</a>, <a href="#webpack_dev_server_rule-node_options">node_options</a>, <a href="#webpack_dev_server_rule-patch_node_fs">patch_node_fs</a>,
                        <a href="#webpack_dev_server_rule-preserve_symlinks_main">preserve_symlinks_main</a>, <a href="#webpack_dev_server_rule-webpack_config">webpack_config</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="webpack_dev_server_rule-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/concepts/labels#target-names">Name</a> | required |  |
| <a id="webpack_dev_server_rule-chdir"></a>chdir |  Working directory to run the binary or test in, relative to the workspace.<br><br>        By default, <code>js_binary</code> runs in the root of the output tree.<br><br>        To run in the directory containing the <code>js_binary</code> use<br><br>            chdir = package_name()<br><br>        (or if you're in a macro, use <code>native.package_name()</code>)<br><br>        WARNING: this will affect other paths passed to the program, either as arguments or in configuration files,         which are workspace-relative.<br><br>        You may need <code>../../</code> segments to re-relativize such paths to the new working directory.         In a <code>BUILD</code> file you could do something like this to point to the output path:<br><br>        <pre><code>python         js_binary(             ...             chdir = package_name(),             # ../.. segments to re-relative paths from the chdir back to workspace;             # add an additional 3 segments to account for running js_binary running             # in the root of the output tree             args = ["/".join([".."] * len(package_name().split("/")) + "$(rootpath //path/to/some:file)"],         )         </code></pre>   | String | optional | <code>""</code> |
| <a id="webpack_dev_server_rule-copy_data_to_bin"></a>copy_data_to_bin |  When True, data files and the entry_point file are copied to the Bazel output tree before being passed         as inputs to runfiles.<br><br>        Ideally, the default for this would be False as it is optimal, but there is a yet unresloved issue of ESM imports         skirting the node fs patches and escaping the sandbox: https://github.com/aspect-build/rules_js/issues/362.         This is hit in some test popular runners such as mocha, which use native <code>import()</code> statements         (https://github.com/aspect-build/rules_js/pull/353). <br><br>        A default of True will prevent program such as mocha from following symlinks into the source tree. They will         escape the sandbox but they will end up in the output tree where node_modules and other inputs required will be         available. With this in mind, the default will remain true until issue #362 is resolved.   | Boolean | optional | <code>True</code> |
| <a id="webpack_dev_server_rule-data"></a>data |  Runtime dependencies of the program.<br><br>        The transitive closure of the <code>data</code> dependencies will be available in         the .runfiles folder for this binary/test.<br><br>        You can use the <code>@bazel/runfiles</code> npm library to access these files         at runtime.<br><br>        npm packages are also linked into the <code>.runfiles/node_modules</code> folder         so they may be resolved directly from runfiles.   | <a href="https://bazel.build/concepts/labels">List of labels</a> | optional | <code>[]</code> |
| <a id="webpack_dev_server_rule-enable_runfiles"></a>enable_runfiles |  Whether runfiles are enabled in the current build configuration.<br><br>        Typical usage of this rule is via a macro which automatically sets this         attribute based on a <code>config_setting</code> rule.   | Boolean | required |  |
| <a id="webpack_dev_server_rule-entry_point"></a>entry_point |  Internal use only   | <a href="https://bazel.build/concepts/labels">Label</a> | required |  |
| <a id="webpack_dev_server_rule-env"></a>env |  Environment variables of the action.<br><br>        Subject to <code>$(location)</code> and make variable expansion.   | <a href="https://bazel.build/rules/lib/dict">Dictionary: String -> String</a> | optional | <code>{}</code> |
| <a id="webpack_dev_server_rule-expected_exit_code"></a>expected_exit_code |  The expected exit code.<br><br>        Can be used to write tests that are expected to fail.   | Integer | optional | <code>0</code> |
| <a id="webpack_dev_server_rule-include_declarations"></a>include_declarations |  When True, <code>declarations</code> and <code>transitive_declarations</code> from <code>JsInfo</code> providers in data targets are included in the runfiles of the target.<br><br>        Defaults to false since declarations are generally not needed at runtime and introducing them could slow down developer round trip         time due to having to generate typings on source file changes.   | Boolean | optional | <code>False</code> |
| <a id="webpack_dev_server_rule-include_npm_linked_packages"></a>include_npm_linked_packages |  When True, files in <code>npm_linked_packages</code> and <code>transitive_npm_linked_packages</code> from <code>JsInfo</code> providers in data targets are included in the runfiles of the target.<br><br>        <code>transitive_files</code> from <code>NpmPackageStoreInfo</code> providers in data targets are also included in the runfiles of the target.   | Boolean | optional | <code>True</code> |
| <a id="webpack_dev_server_rule-include_transitive_sources"></a>include_transitive_sources |  When True, <code>transitive_sources</code> from <code>JsInfo</code> providers in data targets are included in the runfiles of the target.   | Boolean | optional | <code>True</code> |
| <a id="webpack_dev_server_rule-log_level"></a>log_level |  Set the logging level.<br><br>        Log from are written to stderr. They will be supressed on success when running as the tool         of a js_run_binary when silent_on_success is True. In that case, they will be shown         only on a build failure along with the stdout & stderr of the node tool being run.   | String | optional | <code>"error"</code> |
| <a id="webpack_dev_server_rule-node_options"></a>node_options |  Options to pass to the node invocation on the command line.<br><br>        https://nodejs.org/api/cli.html<br><br>        These options are passed directly to the node invocation on the command line.         Options passed here will take precendence over options passed via         the NODE_OPTIONS environment variable. Options passed here are not added         to the NODE_OPTIONS environment variable so will not be automatically         picked up by child processes that inherit that enviroment variable.   | List of strings | optional | <code>[]</code> |
| <a id="webpack_dev_server_rule-patch_node_fs"></a>patch_node_fs |  Patch the to Node.js <code>fs</code> API (https://nodejs.org/api/fs.html) for this node program         to prevent the program from following symlinks out of the execroot, runfiles and the sandbox.<br><br>        When enabled, <code>js_binary</code> patches the Node.js sync and async <code>fs</code> API functions <code>lstat</code>,         <code>readlink</code>, <code>realpath</code>, <code>readdir</code> and <code>opendir</code> so that the node program being         run cannot resolve symlinks out of the execroot and the runfiles tree. When in the sandbox,         these patches prevent the program being run from resolving symlinks out of the sandbox.<br><br>        When disabled, node programs can leave the execroot, runfiles and sandbox by following symlinks         which can lead to non-hermetic behavior.   | Boolean | optional | <code>True</code> |
| <a id="webpack_dev_server_rule-preserve_symlinks_main"></a>preserve_symlinks_main |  When True, the --preserve-symlinks-main flag is passed to node.<br><br>        This prevents node from following an ESM entry script out of runfiles and the sandbox. This can happen for <code>.mjs</code>         ESM entry points where the fs node patches, which guard the runfiles and sandbox, are not applied.         See https://github.com/aspect-build/rules_js/issues/362 for more information. Once #362 is resolved,         the default for this attribute can be set to False.<br><br>        This flag was added in Node.js v10.2.0 (released 2018-05-23). If your node toolchain is configured to use a         Node.js version older than this you'll need to set this attribute to False.<br><br>        See https://nodejs.org/api/cli.html#--preserve-symlinks-main for more information.   | Boolean | optional | <code>True</code> |
| <a id="webpack_dev_server_rule-webpack_config"></a>webpack_config |  Webpack configuration file.<br><br>See https://webpack.js.org/configuration/   | <a href="https://bazel.build/concepts/labels">Label</a> | optional | <code>None</code> |


<a id="webpack_dev_server"></a>

## webpack_dev_server

<pre>
webpack_dev_server(<a href="#webpack_dev_server-webpack_repository">webpack_repository</a>, <a href="#webpack_dev_server-kwargs">kwargs</a>)
</pre>



**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="webpack_dev_server-webpack_repository"></a>webpack_repository |  <p align="center"> - </p>   |  <code>"webpack"</code> |
| <a id="webpack_dev_server-kwargs"></a>kwargs |  <p align="center"> - </p>   |  none |


