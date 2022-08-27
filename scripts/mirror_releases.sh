#!/usr/bin/env bash
set -o errexit -o nounset
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

version="$(curl --silent "https://registry.npmjs.org/webpack/latest" | jq --raw-output ".version")"
out="$SCRIPT_DIR/../webpack/private/v${version}"
mkdir -p "$out"

cd $(mktemp -d)
npx pnpm install webpack@5.72.1 webpack-cli webpack-dev-server @bazel/worker --lockfile-only
touch BUILD
cat >WORKSPACE <<EOF
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "aspect_rules_js",
    sha256 = "25bcb082d49616ac2da538bf7bdd33a9730c8884edbec787fec83db07e4f7f16",
    strip_prefix = "rules_js-1.1.0",
    url = "https://github.com/aspect-build/rules_js/archive/refs/tags/v1.1.0.tar.gz",
)

load("@aspect_rules_js//js:repositories.bzl", "rules_js_dependencies")

rules_js_dependencies()

load("@rules_nodejs//nodejs:repositories.bzl", "nodejs_register_toolchains")

nodejs_register_toolchains(
    name = "nodejs",
    node_version = "16.9.0",
)

load("@aspect_bazel_lib//lib:repositories.bzl", "DEFAULT_YQ_VERSION", "register_yq_toolchains")

register_yq_toolchains(
    version = DEFAULT_YQ_VERSION,
)

load("@aspect_rules_js//npm:npm_import.bzl", "npm_translate_lock")

npm_translate_lock(
    name = "npm_aspect_rules_webpack",
    pnpm_lock = "//:pnpm-lock.yaml",
)

load("@npm_aspect_rules_webpack//:repositories.bzl", "npm_repositories")

npm_repositories()
EOF
bazel fetch @npm_aspect_rules_webpack//:all
cp $(bazel info output_base)/external/npm_aspect_rules_webpack/{defs,repositories}.bzl "$out"
echo "Mirrored webpack version $version to $out. Now add it to webpack/private/versions.bzl"