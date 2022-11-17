# Repro for https://github.com/aspect-build/rules_webpack/issues/57

## Steps

### Non Bazel
```
pnpm install
webpack -c webpack.config.cjs --output-path="dist" --mode=development
webpack -c webpack.css.cjs --output-path="dist" --mode=development
```

### Bazel
```
npm run clean
bazel build //...
```

## Issues
When running `bazel build //:basic` it will fail for not finding the `chalk` transitive dependency of `ts-loader`
```
ERROR in ./src/index.ts
Module build failed (from ./node_modules/.aspect_rules_js/ts-loader@9.4.1_h43ssi27zm76fxis5il54ldtye/node_modules/ts-loader/index.js):
Error: Cannot find module 'chalk'
```

For `bazel build //:css` similarly with `schema-utils`
```
[webpack-cli] Error: Cannot find module 'schema-utils'
Require stack:
```

Normally, `srcs` shouldn't need to include these sources as they are dependencies of the webpack config file.
If they are excluded the issues arise from the fact that the symlinks exist in the sandbox but `.aspect_rules_js` does not.
- for `bazel build //:basic_expected --sandbox_debug`:
```
Module build failed (from ./node_modules/.aspect_rules_js/ts-loader@9.4.1_h43ssi27zm76fxis5il54ldtye/node_modules/ts-loader/index.js):
Error: Cannot find module '/private/var/tmp/_bazel_mstoichi/9ebdb03143f9803d5b91038d63187d96/sandbox/darwin-sandbox/760/execroot/__main__/bazel-out/darwin-fastbuild/bin/node_modules/.aspect_rules_js/ts-loader@9.4.1_h43ssi27zm76fxis5il54ldtye/node_modules/ts-loader/index.js'
```

- for `bazel build //:css_expected --sandbox_debug`
```
[webpack-cli] Failed to load '/private/var/tmp/_bazel_mstoichi/9ebdb03143f9803d5b91038d63187d96/sandbox/darwin-sandbox/762/execroot/__main__/bazel-out/darwin-fastbuild/bin/webpack.css.cjs' config
[webpack-cli] TypeError [ERR_INVALID_ARG_TYPE]: The "path" argument must be of type string. Received undefined
```

