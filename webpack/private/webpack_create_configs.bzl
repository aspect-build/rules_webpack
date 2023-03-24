"""webpack_create_configs rule"""

load("@bazel_skylib//lib:paths.bzl", "paths")

_config_attrs = {
    "chdir": attr.string(),
    "entry_points": attr.label_keyed_string_dict(allow_files = True),
    "config_out": attr.output(),
    "output_dir": attr.bool(),
    "configure_mode": attr.bool(),
    "configure_devtool": attr.bool(),
    "_webpack_config_template": attr.label(
        allow_single_file = True,
        default = Label("//webpack/private:webpack.config.js.tmpl"),
    ),
}

def _desugar_entry_points(entry_points):
    """Converts from dict[target: string] to dict[file: string] to a validated dict[file: string] for which every key corresponds to exactly one file.

    Args:
        entry_points: ctx.attr.entry_points
    Returns:
        Dictionary mapping from file to target name.

    See: https://github.com/bazelbuild/bazel/issues/5355
    """
    result = {}
    for ep in entry_points.items():
        entry_point = ep[0]
        name = ep[1]
        f = entry_point.files.to_list()
        if len(f) != 1:
            fail("webpack_bundle entry points must provide one file, but %s has %s" % (entry_point.label, len(f)))
        result[f[0]] = name
    return result

def _relpath(ctx, file):
    """Path from the working directory to a given file object"""
    if type(file) != "File":
        fail("Expected {} to be of type File, not {}".format(file, type(file)))
    return paths.relativize(file.short_path, ctx.attr.chdir)

def _create_base_config_impl(ctx):
    inputs = []

    # Desugar entrypoints
    entry_points = _desugar_entry_points(ctx.attr.entry_points).items()
    entry_mapping = {}
    for entry_point in entry_points:
        entry_mapping[entry_point[1]] = "./%s" % _relpath(ctx, entry_point[0])

    # Change source-map and mode based on compilation mode
    # See: https://docs.bazel.build/versions/main/user-manual.html#flag--compilation_mode
    # See: https://webpack.js.org/configuration/devtool/#devtool
    compilation_mode = ctx.var["COMPILATION_MODE"]

    mode = None
    if ctx.attr.configure_mode:
        if compilation_mode == "opt":
            mode = "production"
        else:
            mode = "development"

    devtool = None
    if ctx.attr.configure_devtool:
        if compilation_mode == "fastbuild":
            devtool = "eval"
        elif compilation_mode == "dbg":
            devtool = "eval-source-map"

    # Expand webpack config for the entry mapping
    inputs.append(config)
    ctx.actions.expand_template(
        template = ctx.file._webpack_config_template,
        output = ctx.outputs.config_out,
        substitutions = {
            "{{ENTRIES}}": "\n  entry: {},".format(json.encode(entry_mapping)) if entry_mapping else "",
            "{{DEVTOOL}}": "\n  devtool: '{}',".format(devtool) if devtool else "",
            "{{MODE}}": "\n  mode: '{}',".format(mode) if mode else "",
        },
    )

_create_base_config = rule(
    implementation = _create_base_config_impl,
    attrs = _config_attrs,
    doc = "",
)

def webpack_create_configs(
        name,
        entry_point,
        entry_points,
        webpack_config,
        configure_mode,
        configure_devtool,
        chdir,
        entry_points_mandatory):
    """
    Internal use only. Not public API.

    Convert the given entry point[s] rule API into a set of webpack config files.

    Args:
        name: the main target name this config is for
        entry_point: a single entry
        entry_points: multiple entries
        webpack_config: a custom webpack config file
        configure_mode: configure `mode` in the generated base webpack config
        configure_devtool: configure `devtool` in the generated base webpack config
        chdir: the dir webpack is run in
        entry_points_mandatory: whether or not entry points must be specified

    Returns:
        A list of config files to pass to webpack
    """

    if entry_point and entry_points:
        fail("Cannot specify both entry_point and entry_points")
    if entry_points_mandatory and not entry_point and not entry_points:
        fail("One of entry_point or entry_points must be specified")

    default_config = "%s.webpack.config.js" % name
    _create_base_config(
        name = "_%s_config" % name,
        config_out = default_config,
        entry_points = {entry_point: name} if entry_point else entry_points,
        configure_mode = configure_mode,
        configure_devtool = configure_devtool,
        chdir = chdir,
        tags = ["manual"],
    )

    # NOTE: generated base config should always come first as it provides sensible defaults under bazel which
    # users might want to override. Also, webpack_worker uses the first webpack config path as the worker key.
    return [default_config] + ([webpack_config] if webpack_config else [])
