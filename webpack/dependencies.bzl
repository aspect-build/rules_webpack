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
        name = "aspect_bazel_lib",
        sha256 = "d1d712d115b908eaaa22aa899fa0e9016d70347debdafe295059e79adda93b02",
        strip_prefix = "bazel-lib-0.12.0",
        url = "https://github.com/aspect-build/bazel-lib/archive/refs/tags/v0.12.0.tar.gz",
    )

    maybe(
        http_archive,
        name = "aspect_rules_js",
        sha256 = "5c839b68b862c293de0f3ae3ebe38cd9678ca3fb24182d16ddfe75988c3e83b6",
        strip_prefix = "rules_js-0.7.2",
        url = "https://github.com/aspect-build/rules_js/archive/refs/tags/v0.7.2.tar.gz",
    )
