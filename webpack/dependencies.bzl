"""Declare runtime dependencies

These are needed for local dev, and users must install them as well.
See https://docs.bazel.build/versions/main/skylark/deploying.html#dependencies
"""

load("//webpack/private:maybe.bzl", http_archive = "maybe_http_archive")

# buildifier: disable=function-docstring
def rules_webpack_dependencies():
    http_archive(
        name = "bazel_skylib",
        sha256 = "cd55a062e763b9349921f0f5db8c3933288dc8ba4f76dd9416aac68acee3cb94",
        urls = ["https://github.com/bazelbuild/bazel-skylib/releases/download/1.5.0/bazel-skylib-1.5.0.tar.gz"],
    )

    http_archive(
        name = "aspect_bazel_lib",
        sha256 = "b59781939f40c8bf148f4a71bd06e3027e15e40e98143ea5688b83531ec8528f",
        strip_prefix = "bazel-lib-2.7.6",
        url = "https://github.com/aspect-build/bazel-lib/releases/download/v2.7.6/bazel-lib-v2.7.6.tar.gz",
    )

    http_archive(
        name = "aspect_rules_js",
        sha256 = "389021e29b3aeed2f6fb3a7a1478f8fc52947a6500b198a7ec0f3358c2842415",
        strip_prefix = "rules_js-2.0.0-rc0",
        url = "https://github.com/aspect-build/rules_js/releases/download/v2.0.0-rc0/rules_js-v2.0.0-rc0.tar.gz",
    )

    http_archive(
        name = "rules_nodejs",
        sha256 = "dddd60acc3f2f30359bef502c9d788f67e33814b0ddd99aa27c5a15eb7a41b8c",
        strip_prefix = "rules_nodejs-6.1.0",
        url = "https://github.com/bazelbuild/rules_nodejs/releases/download/v6.1.0/rules_nodejs-v6.1.0.tar.gz",
    )

    http_archive(
        name = "bazel_features",
        sha256 = "f3082bfcdca73dc77dcd68faace806135a2e08c230b02b1d9fbdbd7db9d9c450",
        strip_prefix = "bazel_features-0.1.0",
        url = "https://github.com/bazel-contrib/bazel_features/releases/download/v0.1.0/bazel_features-v0.1.0.tar.gz",
    )
