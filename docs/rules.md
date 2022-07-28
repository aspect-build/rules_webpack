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


<a id="#webpack_dev_server_rule"></a>

## webpack_dev_server_rule

<pre>
webpack_dev_server_rule(<a href="#webpack_dev_server_rule-name">name</a>, <a href="#webpack_dev_server_rule-chdir">chdir</a>, <a href="#webpack_dev_server_rule-data">data</a>, <a href="#webpack_dev_server_rule-enable_runfiles">enable_runfiles</a>, <a href="#webpack_dev_server_rule-entry_point">entry_point</a>, <a href="#webpack_dev_server_rule-env">env</a>, <a href="#webpack_dev_server_rule-expected_exit_code">expected_exit_code</a>,
                        <a href="#webpack_dev_server_rule-log_level">log_level</a>, <a href="#webpack_dev_server_rule-node_options">node_options</a>, <a href="#webpack_dev_server_rule-patch_node_fs">patch_node_fs</a>, <a href="#webpack_dev_server_rule-srcs">srcs</a>, <a href="#webpack_dev_server_rule-webpack_config">webpack_config</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="webpack_dev_server_rule-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="webpack_dev_server_rule-chdir"></a>chdir |  Working directory to run the binary or test in, relative to the workspace.<br><br>        By default, <code>js_binary</code> runs in the root of the output tree.<br><br>        To run in the directory containing the <code>js_binary</code> use<br><br>            chdir = package_name()<br><br>        (or if you're in a macro, use <code>native.package_name()</code>)<br><br>        WARNING: this will affect other paths passed to the program, either as arguments or in configuration files,         which are workspace-relative.<br><br>        You may need <code>../../</code> segments to re-relativize such paths to the new working directory.         In a <code>BUILD</code> file you could do something like this to point to the output path:<br><br>        <pre><code>python         js_binary(             ...             chdir = package_name(),             # ../.. segments to re-relative paths from the chdir back to workspace;             # add an additional 3 segments to account for running js_binary running             # in the root of the output tree             args = ["/".join([".."] * len(package_name().split("/")) + "$(rootpath //path/to/some:file)"],         )         </code></pre>   | String | optional | "" |
| <a id="webpack_dev_server_rule-data"></a>data |  Runtime dependencies of the program.<br><br>        The transitive closure of the <code>data</code> dependencies will be available in         the .runfiles folder for this binary/test.<br><br>        You can use the <code>@bazel/runfiles</code> npm library to access these files         at runtime.<br><br>        npm packages are also linked into the <code>.runfiles/node_modules</code> folder         so they may be resolved directly from runfiles.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="webpack_dev_server_rule-enable_runfiles"></a>enable_runfiles |  Whether runfiles are enabled in the current build configuration.<br><br>        Typical usage of this rule is via a macro which automatically sets this         attribute based on a <code>config_setting</code> rule.   | Boolean | required |  |
| <a id="webpack_dev_server_rule-entry_point"></a>entry_point |  Internal use only   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| <a id="webpack_dev_server_rule-env"></a>env |  Environment variables of the action.<br><br>        Subject to <code>$(location)</code> and make variable expansion.   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: String -> String</a> | optional | {} |
| <a id="webpack_dev_server_rule-expected_exit_code"></a>expected_exit_code |  The expected exit code.<br><br>        Can be used to write tests that are expected to fail.   | Integer | optional | 0 |
| <a id="webpack_dev_server_rule-log_level"></a>log_level |  Set the logging level.<br><br>        Log from are written to stderr. They will be supressed on success when running as the tool         of a js_run_binary when silent_on_success is True. In that case, they will be shown         only on a build failure along with the stdout & stderr of the node tool being run.   | String | optional | "error" |
| <a id="webpack_dev_server_rule-node_options"></a>node_options |  Options to pass to the node.<br><br>        https://nodejs.org/api/cli.html   | List of strings | optional | [] |
| <a id="webpack_dev_server_rule-patch_node_fs"></a>patch_node_fs |  Patch the to Node.js <code>fs</code> API (https://nodejs.org/api/fs.html) for this node program         to prevent the program from following symlinks out of the execroot, runfiles and the sandbox.<br><br>        When enabled, <code>js_binary</code> patches the Node.js sync and async <code>fs</code> API functions <code>lstat</code>,         <code>readlink</code>, <code>realpath</code>, <code>readdir</code> and <code>opendir</code> so that the node program being         run cannot resolve symlinks out of the execroot and the runfiles tree. When in the sandbox,         these patches prevent the program being run from resolving symlinks out of the sandbox.<br><br>        When disabled, node programs can leave the execroot, runfiles and sandbox by following symlinks         which can lead to non-hermetic behavior.   | Boolean | optional | True |
| <a id="webpack_dev_server_rule-srcs"></a>srcs |  JavaScript source files from the workspace.   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="webpack_dev_server_rule-webpack_config"></a>webpack_config |  Webpack configuration file.<br><br>See https://webpack.js.org/configuration/   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |


<a id="#webpack_dev_server"></a>

## webpack_dev_server

<pre>
webpack_dev_server(<a href="#webpack_dev_server-webpack_repository">webpack_repository</a>, <a href="#webpack_dev_server-kwargs">kwargs</a>)
</pre>



**PARAMETERS**


| Name  | Description | Default Value |
| :------------- | :------------- | :------------- |
| <a id="webpack_dev_server-webpack_repository"></a>webpack_repository |  <p align="center"> - </p>   |  <code>"webpack"</code> |
| <a id="webpack_dev_server-kwargs"></a>kwargs |  <p align="center"> - </p>   |  none |


