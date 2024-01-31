"""Declare runtime dependencies

These are needed for local dev, and users must install them as well.
See https://docs.bazel.build/versions/main/skylark/deploying.html#dependencies
"""

load("//webpack/private:maybe.bzl", http_archive = "maybe_http_archive")

def rules_webpack_dependencies():
    "Fetch deps"
    http_archive(
        name = "bazel_skylib",
        sha256 = "cd55a062e763b9349921f0f5db8c3933288dc8ba4f76dd9416aac68acee3cb94",
        urls = ["https://github.com/bazelbuild/bazel-skylib/releases/download/1.5.0/bazel-skylib-1.5.0.tar.gz"],
    )

    http_archive(
        name = "aspect_bazel_lib",
        sha256 = "4b32cf6feab38b887941db022020eea5a49b848e11e3d6d4d18433594951717a",
        strip_prefix = "bazel-lib-2.0.1",
        url = "https://github.com/aspect-build/bazel-lib/releases/download/v2.0.1/bazel-lib-v2.0.1.tar.gz",
    )

    http_archive(
        name = "aspect_rules_js",
        sha256 = "76a04ef2120ee00231d85d1ff012ede23963733339ad8db81f590791a031f643",
        strip_prefix = "rules_js-1.34.1",
        url = "https://github.com/aspect-build/rules_js/releases/download/v1.34.1/rules_js-v1.34.1.tar.gz",
    )

    http_archive(
        name = "rules_nodejs",
        sha256 = "8fc8e300cb67b89ceebd5b8ba6896ff273c84f6099fc88d23f24e7102319d8fd",
        urls = ["https://github.com/bazelbuild/rules_nodejs/releases/download/5.8.4/rules_nodejs-core-5.8.4.tar.gz"],
    )

    http_archive(
        name = "bazel_features",
        sha256 = "b8789c83c893d7ef3041d3f2795774936b27ff61701a705df52fd41d6ddbf692",
        strip_prefix = "bazel_features-1.2.0",
        url = "https://github.com/bazel-contrib/bazel_features/releases/download/v1.2.0/bazel_features-v1.2.0.tar.gz",
    )
