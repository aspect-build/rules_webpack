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
    sha256 = "b82da82edf64ba7e07e568193d645fc09b0a4ec92e0d82bd4e53d1a0e28ff681",
    strip_prefix = "rules_js-1.0.0-rc.3",
    url = "https://github.com/aspect-build/rules_js/archive/refs/tags/v1.0.0-rc.3.tar.gz",
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
    name = "npm_webpack",
    pnpm_lock = "//:pnpm-lock.yaml",
)
EOF
bazel fetch @npm_webpack//:all
cp $(bazel info output_base)/external/npm_webpack/{defs,repositories}.bzl "$out"
echo "Mirrored webpack version $version to $out. Now add it to webpack/private/versions.bzl"