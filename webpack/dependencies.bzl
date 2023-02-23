"""Declare runtime dependencies

These are needed for local dev, and users must install them as well.
See https://docs.bazel.build/versions/main/skylark/deploying.html#dependencies
"""

load("//webpack/private:maybe.bzl", http_archive = "maybe_http_archive")

def rules_webpack_dependencies():
    # The minimal version of bazel_skylib we require
    http_archive(
        name = "bazel_skylib",
        sha256 = "74d544d96f4a5bb630d465ca8bbcfe231e3594e5aae57e1edbf17a6eb3ca2506",
        urls = ["https://github.com/bazelbuild/bazel-skylib/releases/download/1.3.0/bazel-skylib-1.3.0.tar.gz"],
    )

    http_archive(
        name = "aspect_rules_js",
        sha256 = "3ad6684d744ebbc6592d404cc3aa81d0da634eccb3499f6fd198ae122fa28489",
        strip_prefix = "rules_js-1.19.0",
        url = "https://github.com/aspect-build/rules_js/archive/refs/tags/v1.19.0.tar.gz",
    )

    http_archive(
        name = "aspect_bazel_lib",
        sha256 = "b4cd1114874ab15f794134eefbc254eb89d3e1de640bf4a11f2f402e886ad29e",
        strip_prefix = "bazel-lib-1.27.2",
        url = "https://github.com/aspect-build/bazel-lib/releases/download/v1.27.2/bazel-lib-v1.27.2.tar.gz",
    )

    http_archive(
        name = "rules_nodejs",
        sha256 = "08337d4fffc78f7fe648a93be12ea2fc4e8eb9795a4e6aa48595b66b34555626",
        urls = ["https://github.com/bazelbuild/rules_nodejs/releases/download/5.8.0/rules_nodejs-core-5.8.0.tar.gz"],
    )
