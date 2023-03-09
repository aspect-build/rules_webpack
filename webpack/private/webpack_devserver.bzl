"""Webpack devserver rule definition."""

load("@aspect_rules_js//js:defs.bzl", "js_run_devserver")

load(":webpack_bundle.bzl", _webpack_create_configs = "webpack_create_configs")

def webpack_devserver(
        name,
        chdir = None,
        env = {},
        entry_point = None,
        entry_points = [],
        webpack_config = None,
        args = [],
        data = [],
        mode = "development",
        webpack = Label("@webpack//:webpack"),
        **kwargs):
    """Runs the webpack devserver.

    This is a macro that uses
    [js_run_devserver](https://github.com/aspect-build/rules_js/blob/main/docs/js_run_devserver.md)
    under the hood.

    Args:
        name: A unique name for this target.

        entry_point: The point where to start the application bundling process.

            See https://webpack.js.org/concepts/entry-points/

            Exactly one of `entry_point` to `entry_points` must be specified.

        entry_points: The map of entry points to bundle names.

            See https://webpack.js.org/concepts/entry-points/

            Exactly one of `entry_point` to `entry_points` must be specified.

        webpack_config: Webpack configuration file. See https://webpack.js.org/configuration/.

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

        webpack: The webpack js_binary to use.

        **kwargs: Additional arguments. See [js_run_devserver](https://github.com/aspect-build/rules_js/blob/main/docs/js_run_devserver.md).
    """
    if kwargs.pop("command", None):
        fail("command attribute is invalid in webpack_devserver. Use js_run_devserver directly instead.")
    if kwargs.pop("tool", None):
        fail("tool attribute is invalid in webpack_devserver. Use js_run_devserver directly instead.")

    unwind_chdir_prefix = ""
    if chdir:
        unwind_chdir_prefix = "/".join([".."] * len(chdir.split("/"))) + "/"

    webpack_configs = _webpack_create_configs(name, entry_point, entry_points, webpack_config, chdir)

    config_args = []
    for config in webpack_configs:
        config_args.append("--config")
        config_args.append("{}$(rootpath {})".format(unwind_chdir_prefix, config))

    if len(webpack_configs) > 1:
        config_args.append("--merge")

    js_run_devserver(
        name = name,
        tool = webpack,
        args = ["serve"] + config_args + ["--mode", mode] + args,
        data = data + webpack_configs + ([entry_point] if entry_point else []) + entry_points.keys(),
        chdir = chdir,
        env = env,
        **kwargs
    )
