"""rspack_binary helper macro"""

load("@aspect_bazel_lib//lib:directory_path.bzl", "directory_path")
load("@aspect_rules_js//js:defs.bzl", "js_binary")

def rspack_binary(
        name,
        node_modules,
        additional_packages):
    """Create an rspack binary target from linked node_modules in the user's workspace.

    Requires that `@rspack/core` and any additional packages specified are linked into the supplied node_modules tree.

    Args:
        name: Unique name for the binary target
        node_modules: Label pointing to the linked node_modules tree where @rspack/core is linked, e.g. `//:node_modules`.
        additional_packages: list of additional packages required. For example ["@rspack/cli"]
    """

    directory_path(
        name = "{}_entrypoint".format(name),
        directory = "{}/@rspack/cli/dir".format(node_modules),
        path = "bin/rspack.js",
    )

    data = ["{}/@rspack/core".format(node_modules)]
    for p in additional_packages:
        data.append("{}/{}".format(node_modules, p))

    js_binary(
        name = name,
        data = data,
        entry_point = ":{}_entrypoint".format(name),
        visibility = ["//visibility:public"],
    )
