# Declare the local Bazel workspace.
# This is *not* included in the published distribution.
workspace(
    # see https://docs.bazel.build/versions/main/skylark/deploying.html#workspace
    name = "aspect_rules_webpack",
)

load("//:internal_deps.bzl", "rules_webpack_internal_deps")

rules_webpack_internal_deps()

load("//webpack:repositories.bzl", "rules_webpack_dependencies")

rules_webpack_dependencies()

load("@build_bazel_rules_nodejs//:index.bzl", "node_repositories", "npm_install")

node_repositories(
    node_version = "16.0.0",
)

npm_install(
    name = "npm",
    package_json = "//:package.json",
    package_lock_json = "//:package-lock.json",
)
