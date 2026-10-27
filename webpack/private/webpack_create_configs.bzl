"""webpack_create_configs rule"""

load("@bazel_lib//lib:paths.bzl", "relative_file")
load("@bazel_skylib//lib:paths.bzl", "paths")

_config_attrs = {
    "chdir": attr.string(),
    "entry_points": attr.label_keyed_string_dict(allow_files = True),
    "config_out": attr.output(),
    "output_dir": attr.bool(),
    "webpack_config": attr.label(allow_files = True),
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
    # Desugar entrypoints
    entry_points = _desugar_entry_points(ctx.attr.entry_points).items()
    entry_mapping = {}
    for entry_point in entry_points:
        entry_mapping[entry_point[1]] = "./%s" % _relpath(ctx, entry_point[0])

    user_config = "null"
    if ctx.attr.webpack_config:
        # Ignore source maps, e.g. from a ts_project with source_map = True.
        configs = [
            f
            for f in ctx.files.webpack_config
            if not f.basename.endswith(".map")
        ]
        if len(configs) != 1:
            fail("webpack_config must provide exactly one config file, but {} provides {}. Wrap the config file in a js_library whose deps provide any modules it requires.".format(
                ctx.attr.webpack_config.label,
                [f.short_path for f in configs],
            ))

        # The generated config loads the user config by a path relative to itself. This holds both in the
        # output tree and in runfiles as long as the user config is in the main repository.
        user_config = json.encode(relative_file(configs[0].short_path, ctx.outputs.config_out.short_path))

    ctx.actions.expand_template(
        template = ctx.file._webpack_config_template,
        output = ctx.outputs.config_out,
        substitutions = {
            "{{ENTRIES}}": "\n    entry: {},".format(json.encode(entry_mapping)) if entry_mapping else "",
            "{{USER_CONFIG}}": user_config,
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
        chdir: the dir webpack is run in
        entry_points_mandatory: whether or not entry points must be specified

    Returns:
        A struct with:
          config: the generated config to pass to webpack (`--config`). It loads the user's config, if
            any, and merges the Bazel defaults into each config it exports.
          files: all config files needed at runtime, starting with `config`.
    """

    if entry_point and entry_points:
        fail("Cannot specify both entry_point and entry_points")
    if entry_points_mandatory and not entry_point and not entry_points:
        fail("One of entry_point or entry_points must be specified")

    default_config = "%s.webpack.config.cjs" % name
    _create_base_config(
        name = "_%s_config" % name,
        config_out = default_config,
        entry_points = {entry_point: name} if entry_point else entry_points,
        webpack_config = webpack_config,
        chdir = chdir,
        tags = ["manual"],
    )

    return struct(
        config = default_config,
        files = [default_config] + ([webpack_config] if webpack_config else []),
    )
