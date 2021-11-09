"webpack_dev_server macro"

load("@build_bazel_rules_nodejs//:index.bzl", "nodejs_binary")
load("@bazel_skylib//rules:copy_file.bzl", "copy_file")

def webpack_dev_server(
        name,
        webpack_config,
        args = [],
        data = [],
        _ibazel_webpack_plugin = Label("//@aspect-build/webpack/webpack-dev-server:webpack.config.js"),
        _webpack_entry_point = Label("//@aspect-build/webpack/webpack-dev-server:entry_point.js"),
        **kwargs):
    """Use webpack with a development server that provides live reloading. This should be used for development only.

    Args:
      name: The name of the dev server target.
      webpack_config: Webpack configuration file.

        See https://webpack.js.org/configuration/
      args: Command line arguments to pass to Webpack.

        These argument passed on the command line before arguments that are added by the rule.
        Run `bazel` with `--subcommands` to see what Webpack CLI command line was invoked.

        See the [Webpack CLI docs](https://webpack.js.org/api/cli/) for a complete list of supported arguments.
      data: Runtime dependencies which may be loaded during compliation.
      _ibazel_webpack_plugin: Inernal use only. Webpack plugin used as a communication layer between ibazel's build event signalling semantics and webpacks file watching semantics.
      _webpack_entry_point: Internal use only. Entry point shim used to launch the webpack-cli in serve mode.
      **kwargs: passed through to `nodejs_binary`
    """

    copied_entry_point_name = name + "_entry_point"
    copy_file(
        name = copied_entry_point_name,
        src = _webpack_entry_point,
        out = copied_entry_point_name + ".js",
    )

    nodejs_binary(
        name = name,
        entry_point = ":" + copied_entry_point_name,
        tags = ["ibazel_notify_changes"] + kwargs.pop("tags", []),
        args = [
            "serve",
            "-c",
            "./$(rootpath %s)" % _ibazel_webpack_plugin,
            "--merge",
            "-c",
            "./$(rootpath %s)" % webpack_config,
        ] + args,
        data = [
            webpack_config,
            _ibazel_webpack_plugin,
            _webpack_cli,
            _webpack_dev_server,
            _webpack,
        ] + data,
        **kwargs
    )

_webpack_cli = Label(
    "//webpack-cli",
)

_webpack_dev_server = Label(
    "//webpack-dev-server",
)

_webpack = Label(
    "//webpack",
)
