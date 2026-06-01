"""webpack_binary helper macro"""

load("@aspect_rules_js//js:defs.bzl", "js_binary")
load("@bazel_lib//lib:directory_path.bzl", "directory_path")

def webpack_binary(
        name,
        node_modules,
        additional_packages,
        additional_data = [],
        fixed_args = []):
    """Create a webpack binary target from linked node_modules in the user's workspace.

    Requires that `webpack` and any additional packages specified are linked into the supplied node_modules tree.

    Args:
        name: Unique name for the binary target
        node_modules: Label pointing to the linked node_modules tree where webpack is linked, e.g. `//:node_modules`.
        additional_packages: list of additional packages required. For example ["webpack-cli", "webpack-dev-server"]
        additional_data: additional data for the binary
        fixed_args: arguments that will be baked into the binary
    """

    directory_path(
        name = "{}_entrypoint".format(name),
        directory = "{}/webpack/dir".format(node_modules),
        path = "bin/webpack.js",
    )

    data = ["{}/webpack".format(node_modules)]
    for p in additional_packages:
        data.append("{}/{}".format(node_modules, p))

    js_binary(
        name = name,
        data = data + additional_data,
        entry_point = ":{}_entrypoint".format(name),
        fixed_args = fixed_args,
        visibility = ["//visibility:public"],
    )
