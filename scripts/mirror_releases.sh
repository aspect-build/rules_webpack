#!/usr/bin/env bash
set -o errexit -o nounset
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

version="${1:-$(curl --silent "https://registry.npmjs.org/webpack/latest" | jq --raw-output ".version")}"
out="$SCRIPT_DIR/../webpack/private/v${version}"
mkdir -p "$out"

cd $(mktemp -d)
npx pnpm install webpack@5.72.1 webpack-cli webpack-dev-server @bazel/worker --lockfile-only
cp pnpm-lock.yaml "$out"
echo "Mirrored webpack version $version to $out. Now add it to webpack/private/versions.bzl"
