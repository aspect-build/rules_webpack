# How to Contribute

## Formatting

Starlark files should be formatted by buildifier.
We suggest using a pre-commit hook to automate this.
First [install pre-commit](https://pre-commit.com/#installation),
then run

```shell
pre-commit install
```

Otherwise later tooling on CI may yell at you about formatting/linting violations.

## Using this as a development dependency of other rules

You'll commonly find that you develop in another module, such as
some other ruleset that depends on rules_webpack, or in a nested
module in the `e2e/` folder.

To tell Bazel to use this directory rather than a released artifact
or a version fetched from the registry, add a `local_path_override` to
the consumer's `MODULE.bazel`:

```starlark
bazel_dep(name = "aspect_rules_webpack", version = "0.0.0")
local_path_override(
    module_name = "aspect_rules_webpack",
    path = "/path/to/aspect_rules_webpack",
)
```

The `e2e/*/MODULE.bazel` files in this repo demonstrate this pattern.

## Releasing

1. npm version [patch|minor|major]
1. npm publish
