"""Webpack devserver rule definition."""

load("@aspect_rules_js//js:defs.bzl", "js_run_devserver")

def webpack_devserver(
        name,
        webpack_config,
        args = [],
        data = [],
        mode = "development",
        webpack = "@webpack//:webpack",
        **kwargs):
    """Runs the webpack devserver.

    This is a macro that uses
    [js_run_devserver](https://github.com/aspect-build/rules_js/blob/main/docs/js_run_devserver.md)
    under the hood.

    Args:
        name: A unique name for this target.

        webpack_config: Webpack configuration file. See https://webpack.js.org/configuration/.

        args: Additional arguments to pass to webpack.

            The `serve` command, the webpack config file (`--config`) and the mode (`--mode`) are
            automatically set.

        data: Runtime dependencies of the program.

            The webpack config is automatically passed to data.

        mode: The mode to pass to `--mode`.

        webpack: The webpack js_binary to use.

        **kwargs: Additional arguments. See [js_run_devserver](https://github.com/aspect-build/rules_js/blob/main/docs/js_run_devserver.md).
    """
    if kwargs.pop("command", None):
        fail("command attribute is invalid in webpack_devserver. Use js_run_devserver directly instead.")
    if kwargs.pop("tool", None):
        fail("tool attribute is invalid in webpack_devserver. Use js_run_devserver directly instead.")

    chdir = kwargs.pop("chdir", None)
    unwind_chdir_prefix = ""
    if chdir:
        unwind_chdir_prefix = "/".join([".."] * len(chdir.split("/"))) + "/"

    js_run_devserver(
        name = "devserver",
        tool = webpack,
        args = [
            "serve",
            "--config",
            "{}$(rootpath {})".format(unwind_chdir_prefix, webpack_config),
            "--mode",
            mode,
        ] + args,
        data = data + [webpack_config],
        chdir = chdir,
        **kwargs
    )
