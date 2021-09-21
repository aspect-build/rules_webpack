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
        sha256 = "58f558d04a936cade1d4744d12661317e51f6a21e3dd7c50b96dc14f3fa3b87d",
        strip_prefix = "bazel-skylib-df3c9e2735f02a7fe8cd80db4db00fec8e13d25f",
        urls = [
            "https://github.com/bazelbuild/bazel-skylib/archive/df3c9e2735f02a7fe8cd80db4db00fec8e13d25f.tar.gz",
        ],
    )

    maybe(
        http_archive,
        name = "rules_nodejs",
        sha256 = "83505dca19f86eff240d77d1fad1bac0c75121d2918dcfbc570f8b85b33f3975",
        urls = ["https://github.com/bazelbuild/rules_nodejs/releases/download/4.2.0/rules_nodejs-core-4.2.0.tar.gz"],
    )

    maybe(
        http_archive,
        name = "build_bazel_rules_nodejs",
        sha256 = "4e1a5633267a0ca1d550cced2919dd4148575c0bafd47608b88aea79c41b5ca3",
        urls = ["https://github.com/bazelbuild/rules_nodejs/releases/download/4.2.0/rules_nodejs-4.2.0.tar.gz"],
    )
