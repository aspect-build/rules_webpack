"""Declare runtime dependencies

These are needed for local dev, and users must install them as well.
See https://docs.bazel.build/versions/main/skylark/deploying.html#dependencies
"""

load("//webpack/private:versions.bzl", "TOOL_VERSIONS")
load("@aspect_rules_js//npm:npm_import.bzl", _npm_translate_lock = "npm_translate_lock")

LATEST_VERSION = TOOL_VERSIONS[0]

def webpack_repositories(name, webpack_version = LATEST_VERSION):
    """
    Fetch external tools needed for webpack

    Args:
        name: Unique name for this webpack tools repository
        webpack_version: The webpack version to fetch.

            See /webpack/private/versions.bzl for available versions.
    """
    if webpack_version not in TOOL_VERSIONS:
        fail("""
webpack version {} is not currently mirrored into aspect_rules_webpack.
Please instead choose one of these available versions: {}""".format(webpack_version, TOOL_VERSIONS))

    _npm_translate_lock(
        name = name,
        pnpm_lock = "@aspect_rules_webpack//webpack/private:{version}/pnpm-lock.yaml".format(version = webpack_version),
        # We'll be linking in the @foo repository and not the repository where the pnpm-lock file is located
        link_workspace = name,
        # Override the Bazel package where pnpm-lock.yaml is located and link to the specified package instead
        root_package = "",
        defs_bzl_filename = "npm_link_all_packages.bzl",
        repositories_bzl_filename = "npm_repositories.bzl",
        additional_file_contents = {
            "BUILD.bazel": [
                """load("@bazel_skylib//rules:copy_file.bzl", "copy_file")""",
                """load("@aspect_bazel_lib//lib:directory_path.bzl", "directory_path")""",
                """load("@aspect_rules_js//js:defs.bzl", "js_binary")""",
                """load("//:npm_link_all_packages.bzl", "npm_link_all_packages")""",
                """npm_link_all_packages(name = "node_modules")""",
                """directory_path(
    name = "entrypoint",
    directory = ":node_modules/webpack/dir",
    path = "bin/webpack.js",
    visibility = ["//visibility:public"],
)""",
                """js_binary(
    name = "{name}",
    data = [":node_modules/webpack", ":node_modules/webpack-dev-server", ":node_modules/webpack-cli"],
    entry_point = ":entrypoint",
    visibility = ["//visibility:public"],
)""".format(name = name),
                """copy_file(
    name = "copy_webpack_worker",
    src = "@aspect_rules_webpack//webpack/private:webpack_worker.js",
    out = "webpack_worker.js"
)""",
                """js_binary(
    name = "worker",
    data = [":node_modules/webpack", ":node_modules/webpack-cli", ":node_modules/@bazel/worker"],
    entry_point = "copy_webpack_worker",
    visibility = ["//visibility:public"],
)""",
            ],
        },
    )
