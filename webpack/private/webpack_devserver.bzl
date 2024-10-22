"""Webpack devserver rule definition."""

load("@aspect_rules_js//js:defs.bzl", "js_run_devserver")
load(":webpack_binary.bzl", "webpack_binary")
load(":webpack_create_configs.bzl", "webpack_create_configs")

def webpack_devserver(
        name,
        node_modules,
        chdir = None,
        env = {},
        entry_point = None,
        entry_points = {},
        webpack_config = None,
        configure_mode = True,
        configure_devtool = True,
        args = [],
        data = [],
        mode = "development",
        **kwargs):
    """Runs the webpack devserver.

    This is a macro that uses
    [js_run_devserver](https://github.com/aspect-build/rules_js/blob/main/docs/js_run_devserver.md)
    under the hood.

    When using ibazel, the devserver will automatically reload when the source files change. Note that
    ibazel does not work when using bazel `alias` targets, see https://github.com/bazelbuild/bazel-watcher/issues/100.

    Args:
        name: A unique name for this target.

        node_modules: Label pointing to the linked node_modules target where
            webpack is linked, e.g. `//:node_modules`.

            The following packages must be linked into the node_modules supplied:

                webpack, webpack-cli, webpack-dev-server

        entry_point: The point where to start the application bundling process.

            See https://webpack.js.org/concepts/entry-points/

            Only one of `entry_point` to `entry_points` must be specified.

        entry_points: The map of entry points to bundle names.

            See https://webpack.js.org/concepts/entry-points/

            Only one of `entry_point` to `entry_points` must be specified.

        webpack_config: Webpack configuration file. See https://webpack.js.org/configuration/.

        configure_mode: Configure `mode` in the generated base webpack config.

            `mode` is set to `production` if the Bazel compilation mode is `opt` otherwise it is set to `development`.

            The configured value will be overridden if it is set in a supplied `webpack_config`.

            See https://bazel.build/docs/user-manual#compilation-mode for more info on how to configure the compilation mode.

        configure_devtool: Configure `devtool` in the generated base webpack config.

            `devtool` is set to `eval` if the Bazel compilation mode is `fastbuild`, `eval-source-map` if the Bazel
            compilation mode is `dbg`, otherwise it is left unset.

            The configured value will be overridden if it is set in a supplied `webpack_config`.

            See https://bazel.build/docs/user-manual#compilation-mode for more info on how to configure the compilation mode.

        args: Additional arguments to pass to webpack.

            The `serve` command, the webpack config file (`--config`) and the mode (`--mode`) are
            automatically set.

        chdir: Working directory to run Webpack under.

            This is needed to workaround some buggy resolvers in webpack loaders, which assume that the
            node_modules tree is located in a parent of the working directory rather than a parent of
            the script with the require statement.

            Note that any relative paths in your configuration may need to be adjusted so they are
            relative to the new working directory.

            See also:
            https://github.com/aspect-build/rules_js/blob/main/docs/js_binary.md#js_binary-chdir

        data: Bundle and runtime dependencies of the program.

            Should include the `webpack_bundle` rule `srcs` and `deps`.

            The webpack config and entry_point[s] are automatically passed to data and should not be repeated.

        env: Environment variables of the action.

            Subject to `$(location)` and make variable expansion.

        mode: The mode to pass to `--mode`.

        **kwargs: Additional arguments. See [js_run_devserver](https://github.com/aspect-build/rules_js/blob/main/docs/js_run_devserver.md).
    """
    if kwargs.pop("command", None):
        fail("command attribute is invalid in webpack_devserver. Use js_run_devserver directly instead.")
    if kwargs.pop("tool", None):
        fail("tool attribute is invalid in webpack_devserver. Use js_run_devserver directly instead.")

    unwind_chdir_prefix = ""
    if chdir:
        unwind_chdir_prefix = "/".join([".."] * len(chdir.split("/"))) + "/"

    webpack_configs = webpack_create_configs(
        name = name,
        entry_point = entry_point,
        entry_points = entry_points,
        webpack_config = webpack_config,
        configure_mode = configure_mode,
        configure_devtool = configure_devtool,
        chdir = chdir,
        entry_points_mandatory = False,  # devserver rule doesn't have outputs so entry points are not needed to predict output files
    )

    config_args = []
    for config in webpack_configs:
        config_args.append("--config")
        config_args.append("{}$(rootpath {})".format(unwind_chdir_prefix, config))

    if len(webpack_configs) > 1:
        config_args.append("--merge")

    webpack_binary_target = "_{}_webpack_binary".format(name)

    webpack_binary(
        name = webpack_binary_target,
        node_modules = node_modules,
        additional_packages = ["webpack-cli", "webpack-dev-server"],
    )

    js_run_devserver(
        name = name,
        tool = webpack_binary_target,
        args = ["serve"] + config_args + ["--mode", mode] + args,
        data = data + webpack_configs + ([entry_point] if entry_point else []) + entry_points.keys(),
        chdir = chdir,
        env = env,
        **kwargs
    )
