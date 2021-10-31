# This target is used locally by the repository to access webpack-cli.
# directory is designed to match the userland external repository so that
# we don't have to do label substitution in release packages.
# this target represent the webpack entry in bin section of webpack-cli npm package.
# This is a npm_package_bin target in userland repository.
# NOTE: this file is not meant to be released in the npm package. be careful
alias(
    name = "webpack-dev-server",
    actual = "@npm//webpack-dev-server",
    visibility = ["//visibility:public"],
)

exports_files([
    "webpack.config.js",
    "entry_point.js",
])
