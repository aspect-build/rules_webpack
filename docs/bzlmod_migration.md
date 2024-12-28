# Snippet example for MODULE.bazel file
```bazel
# Repo name: aspect_rules_webpack
# Release tag (example): https://github.com/aspect-build/rules_webpack/releases/tag/v0.16.0
bazel_dep(name = "aspect_rules_webpack", version = "0.16.0")
webpack = use_extension("@aspect_rules_webpack//webpack:dependencies.bzl", "webpack", dev_dependency = True)
use_repo(webpack, "webpack")
```
