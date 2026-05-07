# Bazel rules for webpack

Note this repository is in early development and may still have breaking changes going forward.

Ask in #javascript in slack.bazel.build if you'd like to contribute.

_Need help?_ This ruleset has support provided by https://aspect.build/services.

## API documentation

- [webpack](https://github.com/aspect-build/rules_webpack/blob/main/docs/rules.md#webpack_bundle)
- [webpack-devserver](https://github.com/aspect-build/rules_webpack/blob/main/docs/rules.md#webpack_devserver)

## Installation

Add to your `MODULE.bazel`:

```starlark
bazel_dep(name = "aspect_rules_webpack", version = "x.y.z")
```

See the [Bazel Central
Registry](https://registry.bazel.build/modules/aspect_rules_webpack) for the latest
version and the full setup snippet.
