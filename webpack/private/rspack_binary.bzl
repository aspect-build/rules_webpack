"""rspack_binary helper macro"""

load("@aspect_rules_js//js:defs.bzl", "js_binary")
load("@bazel_lib//lib:directory_path.bzl", "directory_path")

def rspack_binary(
        name,
        node_modules,
        additional_packages,
        data = [],
        fixed_args = []):
    """Create an rspack binary target from linked node_modules in the user's workspace.

    Requires that `@rspack/core` and any additional packages specified are linked into the supplied node_modules tree.

    Args:
        name: Unique name for the binary target
        node_modules: Label pointing to the linked node_modules tree where @rspack/core is linked, e.g. `//:node_modules`.
        additional_packages: list of additional packages required. For example ["@rspack/cli"]
        data: data dependencies for the binary
        fixed_args: arguments that will be baked into the binary
    """

    directory_path(
        name = "{}_entrypoint".format(name),
        directory = "{}/@rspack/cli/dir".format(node_modules),
        path = "bin/rspack.js",
    )

    packages = ["{}/@rspack/core".format(node_modules)]
    for p in additional_packages:
        packages.append("{}/{}".format(node_modules, p))

    js_binary(
        name = name,
        data = data + packages,
        entry_point = ":{}_entrypoint".format(name),
        fixed_args = fixed_args,
        visibility = ["//visibility:public"],
    )
