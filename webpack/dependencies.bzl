"""Declare runtime dependencies

These are needed for local dev, and users must install them as well.
See https://docs.bazel.build/versions/main/skylark/deploying.html#dependencies
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

# WARNING: any changes in this function may be BREAKING CHANGES for users
# because we'll fetch a dependency which may be different from one that
# they were previously fetching later in their WORKSPACE setup, and now
# ours took precedence. Such breakages are challenging for users, so any
# changes in this function should be marked as BREAKING in the commit message
# and released only in semver majors.
def rules_webpack_dependencies():
    # The minimal version of bazel_skylib we require
    maybe(
        http_archive,
        name = "bazel_skylib",
        sha256 = "74d544d96f4a5bb630d465ca8bbcfe231e3594e5aae57e1edbf17a6eb3ca2506",
        urls = [
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.3.0/bazel-skylib-1.3.0.tar.gz",
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.3.0/bazel-skylib-1.3.0.tar.gz",
        ],
    )
    maybe(
        http_archive,
        name = "aspect_rules_js",
        sha256 = "db9f446752fe4100320cf8487e8fd476b9af0adf6b99b601bcfd70b289bb0598",
        strip_prefix = "rules_js-1.1.2",
        url = "https://github.com/aspect-build/rules_js/archive/refs/tags/v1.1.2.tar.gz",
    )

    maybe(
        http_archive,
        name = "aspect_bazel_lib",
        sha256 = "79381b0975ba7d2d5653239e5bab12cf54d89b10217fe771b8edd95047a2e44b",
        strip_prefix = "bazel-lib-1.12.1",
        url = "https://github.com/aspect-build/bazel-lib/archive/refs/tags/v1.12.1.tar.gz",
    )

    maybe(
        http_archive,
        name = "rules_nodejs",
        sha256 = "404fb7ee034671eb30cc04c59d217adf0a8bd04b311ece17e052fc7ecb60ac32",
        urls = ["https://github.com/bazelbuild/rules_nodejs/releases/download/5.5.4/rules_nodejs-core-5.5.4.tar.gz"],
    )
