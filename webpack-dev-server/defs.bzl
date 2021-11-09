"webpack_dev_server macro"

load("@build_bazel_rules_nodejs//:index.bzl", "nodejs_binary")
load("@bazel_skylib//rules:copy_file.bzl", "copy_file")

def webpack_dev_server(
        name,
        webpack_config,
        args = [],
        data = [],
        tags = [],
        ibazel_webpack_plugin = Label("//@aspect-build/webpack/webpack-dev-server:webpack.config.js"),
        webpack_entry_point = Label("//@aspect-build/webpack/webpack-dev-server:entry_point.js"),
        **kwargs):
    copied_entry_point_name = name + "_entry_point"
    copy_file(
        name = copied_entry_point_name,
        src = webpack_entry_point,
        out = copied_entry_point_name + ".js",
    )

    nodejs_binary(
        name = name,
        entry_point = ":" + copied_entry_point_name,
        tags = ["ibazel_notify_changes"] + tags,
        args = [
            "serve",
            "-c",
            "./$(rootpath %s)" % ibazel_webpack_plugin,
            "--merge",
            "-c",
            "./$(rootpath %s)" % webpack_config,
        ] + args,
        data = [
            ibazel_webpack_plugin,
            webpack_config,
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
