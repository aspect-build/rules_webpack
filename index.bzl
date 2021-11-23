"main entrypoint for the npm package users. Should not be used directly."

load("//@aspect-build/webpack/webpack:defs.bzl", _webpack_bundle = "webpack_bundle")
load("//@aspect-build/webpack/webpack-dev-server:defs.bzl", _webpack_dev_server = "webpack_dev_server")

webpack_bundle = _webpack_bundle
webpack_dev_server = _webpack_dev_server
