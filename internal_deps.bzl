"""Our "development" dependencies

Users should *not* need to install these. If users see a load()
statement from these, that's a bug in our distribution.
"""

# buildifier: disable=bzl-visibility
load("//webpack/private:maybe.bzl", http_archive = "maybe_http_archive")

def rules_webpack_internal_deps():
    "Fetch repositories used for developing the rules"

    # opt-in to 2.0 without forcing users to do so
    http_archive(
        name = "aspect_bazel_lib",
        sha256 = "c858cc637db5370f6fd752478d1153955b4b4cbec7ffe95eb4a47a48499a79c3",
        strip_prefix = "bazel-lib-2.0.3",
        url = "https://github.com/aspect-build/bazel-lib/releases/download/v2.0.3/bazel-lib-v2.0.3.tar.gz",
    )

    http_archive(
        name = "io_bazel_stardoc",
        sha256 = "3fd8fec4ddec3c670bd810904e2e33170bedfe12f90adf943508184be458c8bb",
        urls = ["https://github.com/bazelbuild/stardoc/releases/download/0.5.3/stardoc-0.5.3.tar.gz"],
    )

    http_archive(
        name = "buildifier_prebuilt",
        sha256 = "e46c16180bc49487bfd0f1ffa7345364718c57334fa0b5b67cb5f27eba10f309",
        strip_prefix = "buildifier-prebuilt-6.1.0",
        urls = [
            "https://github.com/keith/buildifier-prebuilt/archive/6.1.0.tar.gz",
        ],
    )
