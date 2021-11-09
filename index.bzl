"main entrypoint for the npm package users. Should not be used directly."

load("//@aspect-build/webpack:defs.bzl", _webpack_bundle = "webpack_bundle")

webpack_bundle = _webpack_bundle
