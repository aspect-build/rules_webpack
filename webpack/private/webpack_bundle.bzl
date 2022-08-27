"""Webpack bundle producing rule definition."""

load("@aspect_bazel_lib//lib:copy_to_bin.bzl", "copy_file_to_bin_action", "copy_files_to_bin_actions")
load("@aspect_rules_js//js:libs.bzl", "js_lib_helpers")
load("@aspect_rules_js//js:providers.bzl", "JsInfo", "js_info")

_attrs = {
    "args": attr.string_list(
        doc = """Command line arguments to pass to Webpack.

These argument passed on the command line before arguments that are added by the rule.
Run `bazel` with `--subcommands` to see what Webpack CLI command line was invoked.

See the [Webpack CLI docs](https://webpack.js.org/api/cli/) for a complete list of supported arguments.""",
        default = [],
    ),
    "srcs": attr.label_list(
        doc = """Non-entry point JavaScript source files from the workspace.
You must not repeat file(s) passed to entry_point/entry_points.
""",
        # Don't try to constrain the filenames, could be json, svg, whatever
        allow_files = True,
    ),
    "deps": attr.label_list(
        doc = """Runtime dependencies which may be loaded during compliation.""",
        allow_files = True,
        providers = [JsInfo],
    ),
    "data": js_lib_helpers.JS_LIBRARY_DATA_ATTR,
    "output_dir": attr.bool(),
    "entry_point": attr.label(
        doc = """The point or points where to start the application bundling process.
        
See https://webpack.js.org/concepts/entry-points/""",
        allow_single_file = True,
    ),
    "entry_points": attr.label_keyed_string_dict(
        allow_files = True,
    ),
    "supports_workers": attr.bool(
        doc = """Experimental! Use only with caution.

Allows you to enable the Bazel Worker strategy for this library.""",
        default = False,
    ),
    "webpack": attr.label(
        doc = "Target that executes the webpack-cli binary",
        executable = True,
        cfg = "exec",
        default = Label("@webpack"),
    ),
    "webpack_worker": attr.label(
        doc = "Target that executes the webpack-cli binary as a worker",
        executable = True,
        cfg = "exec",
        default = Label("@webpack//:worker"),
    ),
    "webpack_config": attr.label(
        doc = """Webpack configuration file.
        
See https://webpack.js.org/configuration/""",
        allow_single_file = True,
        mandatory = False,
    ),
    "_webpack_config_file": attr.label(
        doc = "Internal use only",
        allow_single_file = [".js"],
        default = Label("//webpack/private:webpack.config.js"),
    ),
    "_windows_constraint": attr.label(default = "@platforms//os:windows"),
}

def _desugar_entry_point_names(name, entry_point, entry_points):
    """Users can specify entry_point (sugar) or entry_points (long form).

    Args:
        name: ctx.attr.name
        entry_point: ctx.attr.entry_point
        entry_points: ctx.attr.entry_points
    Returns:
        A list of entry point names to pass to webpack
    """
    if entry_point and entry_points:
        fail("Cannot specify both entry_point and entry_points")
    if not entry_point and not entry_points:
        fail("One of entry_point or entry_points must be specified")
    if entry_point:
        return [name]
    return entry_points.values()

def _desugar_entry_points(name, entry_point, entry_points):
    """Converts from dict[target: string] to dict[file: string] to a validated dict[file: string] for which every key corresponds to exactly one file.

    Args:
        name: ctx.attr.name
        entry_point: ctx.attr.entry_point
        entry_points: ctx.attr.entry_points
    Returns:
        Dictionary mapping from file to target name.

    See: https://github.com/bazelbuild/bazel/issues/5355
    """
    names = _desugar_entry_point_names(name, entry_point.label if entry_point else None, entry_points)

    if entry_point:
        return {entry_point.files.to_list()[0]: names[0]}

    result = {}
    for ep in entry_points.items():
        entry_point = ep[0]
        name = ep[1]
        f = entry_point.files.to_list()
        if len(f) != 1:
            fail("keys in webpack_bundle#entry_points must provide one file, but %s has %s" % (entry_point.label, len(f)))
        result[f[0]] = name
    return result

def _filter_js(files):
    return [f for f in files if f.extension == "js" or f.extension == "cjs" or f.extension == "mjs" or f.extension == "jsx"]

def _outs(name, entry_point, entry_points, output_dir):
    """Supply some labelled outputs in the common case of a single entry point"""
    result = {}
    entry_point_outs = _desugar_entry_point_names(name, entry_point, entry_points)
    if output_dir:
        return {}
    else:
        if len(entry_point_outs) > 1:
            fail("Multiple entry points require that output_dir be set")
        out = entry_point_outs[0]

        # TODO: accept other extensions to be output
        result[out] = out + ".js"
    return result

def _impl(ctx):
    is_windows = ctx.target_platform_has_constraint(ctx.attr._windows_constraint[platform_common.ConstraintValueInfo])

    input_sources = copy_files_to_bin_actions(ctx, ctx.files.srcs, is_windows = is_windows)
    entry_point = copy_files_to_bin_actions(ctx, _filter_js(ctx.files.entry_point), is_windows = is_windows)
    entry_points = copy_files_to_bin_actions(ctx, _filter_js(ctx.files.entry_points), is_windows = is_windows)
    inputs = entry_point + entry_points + input_sources + ctx.files.deps
    output_sources = [getattr(ctx.outputs, o) for o in dir(ctx.outputs)]

    # See CLI documentation at https://webpack.js.org/api/cli/
    args = ctx.actions.args()

    # Desugar entrypoints
    entry_points = _desugar_entry_points(ctx.label.name, ctx.attr.entry_point, ctx.attr.entry_points).items()

    entry_mapping = {}

    for entry_point in entry_points:
        inputs.append(entry_point[0])

        # TODO: find an idiomatic way to do this.
        entry_mapping[entry_point[1]] = "./%s" % (entry_point[0].short_path)

    # Expand webpack config for the entry mapping
    # NOTE: generated config should always come first as it provides sensible defaults under bazel which
    # users might want to override. Also, webpack_worker uses the first webpack config path as the worker key.
    config = ctx.actions.declare_file("%s.webpack.config.js" % ctx.label.name)
    ctx.actions.expand_template(
        template = ctx.file._webpack_config_file,
        output = config,
        substitutions = {
            "{ ENTRIES }": json.encode(entry_mapping),
        },
    )

    args.add_all(["-c", config.short_path])
    inputs.append(config)

    # Add user defined config as an input and argument
    if ctx.attr.webpack_config:
        webpack_config_file = copy_file_to_bin_action(ctx, ctx.file.webpack_config, is_windows = is_windows)
        args.add_all(["-c", webpack_config_file.short_path])
        inputs.append(webpack_config_file)

        # Merge all webpack configs
        args.add("--merge")

    # Change source-map and mode based on compilation mode
    # See: https://docs.bazel.build/versions/main/user-manual.html#flag--compilation_mode
    # See: https://webpack.js.org/configuration/devtool/#devtool
    compilation_mode = ctx.var["COMPILATION_MODE"]

    if compilation_mode == "fastbuild":
        args.add_all(["--devtool", "eval", "--mode", "development"])
    elif compilation_mode == "dbg":
        args.add_all(["--devtool", "eval-source-map", "--mode", "development"])
    elif compilation_mode == "opt":
        args.add_all(["--no-devtool", "--mode", "production"])

    if ctx.attr.output_dir:
        output_sources = [ctx.actions.declare_directory(ctx.attr.name)]
        args.add_all(["--output-path", output_sources[0].short_path])
    else:
        args.add_all(["--output-path", output_sources[0].short_path[:-len(output_sources[0].basename)]])

    # Add user specified arguments after rule supplied arguments
    args.add_all(ctx.attr.args)

    executable = ctx.executable.webpack
    execution_requirements = {}

    if ctx.attr.supports_workers:
        executable = ctx.executable.webpack_worker
        execution_requirements["supports-workers"] = str(int(ctx.attr.supports_workers))

        # Set to use a multiline param-file for worker mode
        args.use_param_file("@%s", use_always = True)
        args.set_param_file_format("multiline")

    ctx.actions.run(
        progress_message = "Running Webpack [Webpack]",
        executable = executable,
        inputs = inputs,
        outputs = output_sources,
        arguments = [args],
        mnemonic = "Webpack",
        execution_requirements = execution_requirements,
        env = {
            "BAZEL_BINDIR": ctx.bin_dir.path,
        },
    )

    npm_linked_packages = js_lib_helpers.gather_npm_linked_packages(
        srcs = ctx.attr.srcs,
        deps = [],
    )

    npm_package_store_deps = js_lib_helpers.gather_npm_package_store_deps(
        targets = ctx.attr.data,
    )

    output_sources_depset = depset(output_sources)

    runfiles = js_lib_helpers.gather_runfiles(
        ctx = ctx,
        sources = output_sources_depset,
        data = ctx.attr.data,
        # Since we're bundling, we don't propogate any transitive runfiles from dependencies
        deps = [],
    )

    return [
        js_info(
            npm_linked_package_files = npm_linked_packages.direct_files,
            npm_linked_packages = npm_linked_packages.direct,
            npm_package_store_deps = npm_package_store_deps,
            sources = output_sources_depset,
            # Since we're bundling, we don't propogate linked npm packages from dependencies since
            # they are bundled and the dependencies are dropped. If a subset of linked npm
            # dependencies are not bundled it is up the the user to re-specify these in `data` if
            # they are runtime dependencies to progagate to binary rules or `srcs` if they are to be
            # propagated to downstream build targets.
            transitive_npm_linked_package_files = npm_linked_packages.transitive_files,
            transitive_npm_linked_packages = npm_linked_packages.transitive,
            # Since we're bundling, we don't propogate any transitive output_sources from dependencies
            transitive_sources = output_sources_depset,
        ),
        DefaultInfo(
            files = output_sources_depset,
            runfiles = runfiles,
        ),
    ]

def _expand_locations(ctx, s):
    # `.split(" ")` is a work-around https://github.com/bazelbuild/bazel/issues/10309
    # _expand_locations returns an array of args to support $(execpaths) expansions.
    # TODO: If the string has intentional spaces or if one or more of the expanded file
    # locations has a space in the name, we will incorrectly split it into multiple arguments
    return ctx.expand_location(s, targets = ctx.attr.deps).split(" ")

lib = struct(
    implementation = _impl,
    attrs = _attrs,
    outputs = _outs,
)
