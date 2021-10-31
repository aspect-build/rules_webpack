<!-- Generated with Stardoc: http://skydoc.bazel.build -->

Webpack bundle producing rule defintion.

<a id="#webpack"></a>

## webpack

<pre>
webpack(<a href="#webpack-name">name</a>, <a href="#webpack-args">args</a>, <a href="#webpack-data">data</a>, <a href="#webpack-entry_point">entry_point</a>, <a href="#webpack-entry_points">entry_points</a>, <a href="#webpack-output_dir">output_dir</a>, <a href="#webpack-supports_workers">supports_workers</a>, <a href="#webpack-webpack_cli_bin">webpack_cli_bin</a>,
        <a href="#webpack-webpack_config">webpack_config</a>, <a href="#webpack-webpack_worker_bin">webpack_worker_bin</a>)
</pre>



**ATTRIBUTES**


| Name  | Description | Type | Mandatory | Default |
| :------------- | :------------- | :------------- | :------------- | :------------- |
| <a id="webpack-name"></a>name |  A unique name for this target.   | <a href="https://bazel.build/docs/build-ref.html#name">Name</a> | required |  |
| <a id="webpack-args"></a>args |  Command line arguments to pass to Webpack.<br><br>These argument passed on the command line before arguments that are added by the rule. Run <code>bazel</code> with <code>--subcommands</code> to see what Webpack CLI command line was invoked.<br><br>See the &lt;a href="https://webpack.js.org/api/cli/"&gt;Webpack CLI docs&lt;/a&gt; for a complete list of supported arguments.   | List of strings | optional | [] |
| <a id="webpack-data"></a>data |  Other libraries for the webpack compilation   | <a href="https://bazel.build/docs/build-ref.html#labels">List of labels</a> | optional | [] |
| <a id="webpack-entry_point"></a>entry_point |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | None |
| <a id="webpack-entry_points"></a>entry_points |  -   | <a href="https://bazel.build/docs/skylark/lib/dict.html">Dictionary: Label -> String</a> | optional | {} |
| <a id="webpack-output_dir"></a>output_dir |  -   | Boolean | optional | False |
| <a id="webpack-supports_workers"></a>supports_workers |  Experimental! Use only with caution.<br><br>Allows you to enable the Bazel Worker strategy for this library. When enabled, this rule invokes the "webpack_worker_bin" worker aware binary rather than "webpack_bin".   | Boolean | optional | False |
| <a id="webpack-webpack_cli_bin"></a>webpack_cli_bin |  Target that executes the webpack-cli binary   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | //webpack-cli/bin:webpack-cli |
| <a id="webpack-webpack_config"></a>webpack_config |  -   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | required |  |
| <a id="webpack-webpack_worker_bin"></a>webpack_worker_bin |  Internal use only   | <a href="https://bazel.build/docs/build-ref.html#labels">Label</a> | optional | //@bazel/webpack/bin:webpack-worker |


