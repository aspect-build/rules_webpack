# Declare the local Bazel workspace.
# This is *not* included in the published distribution.
workspace(
    # see https://docs.bazel.build/versions/main/skylark/deploying.html#workspace
    name = "aspect_rules_webpack",
)

load("//:internal_deps.bzl", "rules_webpack_internal_deps")

rules_webpack_internal_deps()

load("//webpack:dependencies.bzl", "rules_webpack_dependencies")

rules_webpack_dependencies()

load("@aspect_rules_js//js:repositories.bzl", "rules_js_dependencies")

rules_js_dependencies()

load("@aspect_bazel_lib//lib:repositories.bzl", "aspect_bazel_lib_dependencies")

aspect_bazel_lib_dependencies(override_local_config_platform = True)

load("@rules_nodejs//nodejs:repositories.bzl", "DEFAULT_NODE_VERSION", "nodejs_register_toolchains")

nodejs_register_toolchains(
    name = "nodejs",
    node_version = DEFAULT_NODE_VERSION,
)

load("@aspect_rules_js//npm:npm_import.bzl", "npm_translate_lock")

npm_translate_lock(
    name = "npm",
    pnpm_lock = "//webpack/tests:pnpm-lock.yaml",
)

load("@npm//:repositories.bzl", "npm_repositories")

npm_repositories()

load("//webpack:repositories.bzl", "webpack_repositories")

webpack_repositories(name = "webpack")

load("@webpack//:npm_repositories.bzl", webpack_npm_repositories = "npm_repositories")

webpack_npm_repositories()

# For running our own unit tests
load("@bazel_skylib//lib:unittest.bzl", "register_unittest_toolchains")

register_unittest_toolchains()

############################################
# Gazelle, for generating bzl_library targets
load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")
load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies")

go_rules_dependencies()

go_register_toolchains(version = "1.19.3")

gazelle_dependencies()
