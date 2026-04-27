# Bazel rules for webpack

Note this repository is in early development and may still have breaking changes going forward.

Ask in #javascript in slack.bazel.build if you'd like to contribute.

_Need help?_ This ruleset has support provided by https://aspect.build/services.

## API documentation

- [webpack](https://github.com/aspect-build/rules_webpack/blob/main/docs/rules.md#webpack_bundle)
- [webpack-devserver](https://github.com/aspect-build/rules_webpack/blob/main/docs/rules.md#webpack_devserver)

## Rspack support

This ruleset supports [Rspack](https://rspack.rs/) as a drop-in alternative to webpack.
Set `bundler = "rspack"` on `webpack_bundle` or `webpack_devserver`:

```python
webpack_bundle(
    name = "bundle",
    bundler = "rspack",
    entry_point = "index.js",
    node_modules = "//:node_modules",
    webpack_config = ":rspack.config.js",
)
```

Your `node_modules` must include `@rspack/core` and `@rspack/cli` (plus `@rspack/dev-server` for `webpack_devserver`).

**Config merging:** Rspack CLI does not support `--merge`, so when a custom
`webpack_config` is provided it _replaces_ the generated base config entirely
(you must define entry points, mode, etc. yourself). Without a custom config
the generated base config is used as-is.

## Installation

From the release you wish to use:
<https://github.com/aspect-build/rules_webpack/releases>
copy the WORKSPACE snippet into your `WORKSPACE` file.
