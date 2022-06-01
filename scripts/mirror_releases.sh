#!/usr/bin/env bash
set -o errexit -o nounset
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

version="$(curl --silent "https://registry.npmjs.org/webpack/latest" | jq --raw-output ".version")"
out="$SCRIPT_DIR/../webpack/private/v${version}"
mkdir -p "$out"

cd $(mktemp -d)
npx pnpm install webpack webpack-cli webpack-dev-server @bazel/worker --lockfile-only
touch BUILD
cat >WORKSPACE <<EOF
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
http_archive(
    name = "aspect_rules_js",
    sha256 = "5c839b68b862c293de0f3ae3ebe38cd9678ca3fb24182d16ddfe75988c3e83b6",
    strip_prefix = "rules_js-0.7.2",
    url = "https://github.com/aspect-build/rules_js/archive/refs/tags/v0.7.2.tar.gz",
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
load("@aspect_rules_js//js:npm_import.bzl", "translate_pnpm_lock")
translate_pnpm_lock(
    name = "npm_webpack",
    pnpm_lock = "//:pnpm-lock.yaml",
)
EOF
bazel fetch @npm_webpack//:all
cp $(bazel info output_base)/external/npm_webpack/{defs,repositories}.bzl "$out"
echo "Mirrored webpack version $version to $out. Now add it to webpack/private/versions.bzl"