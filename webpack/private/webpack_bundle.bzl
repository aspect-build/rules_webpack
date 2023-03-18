"""Webpack bundle producing rule definition."""

load("@aspect_bazel_lib//lib:copy_to_bin.bzl", "copy_files_to_bin_actions")
load("@aspect_bazel_lib//lib:directory_path.bzl", "directory_path")
load("@aspect_bazel_lib//lib:expand_make_vars.bzl", "expand_locations", "expand_variables")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@aspect_rules_js//js:defs.bzl", "js_binary")
load("@aspect_rules_js//js:libs.bzl", "js_lib_helpers")
load("@aspect_rules_js//js:providers.bzl", "JsInfo", "js_info")

_attrs = {
    "args": attr.string_list(
        default = [],
    ),
    "srcs": attr.label_list(
        # Don't constrain the filenames as sources could be json, svg, etc...
        allow_files = True,
    ),
    "deps": attr.label_list(
        allow_files = True,
        providers = [JsInfo],
    ),
    "chdir": attr.string(),
    "data": attr.label_list(
        allow_files = True,
    ),
    "env": attr.string_dict(),
    "output_dir": attr.bool(),
    "entry_points": attr.label_keyed_string_dict(
        allow_files = True,
    ),
    "supports_workers": attr.bool(),
    "webpack_exec_cfg": attr.label(
        executable = True,
        cfg = "exec",
        default = Label("@webpack"),
    ),
    "webpack_target_cfg": attr.label(
        executable = True,
        cfg = "target",
        default = Label("@webpack"),
    ),
    "webpack_worker_exec_cfg": attr.label(
        doc = "",
        executable = True,
        cfg = "exec",
        default = Label("@webpack//:worker"),
    ),
    "webpack_worker_target_cfg": attr.label(
        doc = "",
        executable = True,
        cfg = "target",
        default = Label("@webpack//:worker"),
    ),
    "webpack_configs": attr.label_list(
        allow_files = True,
        doc = "Internal use only",
    ),
    "use_execroot_entry_point": attr.bool(
        default = True,
    ),
    "allow_execroot_entry_point_with_no_copy_data_to_bin": attr.bool(),
}

_config_attrs = {
    "chdir": attr.string(),
    "entry_points": attr.label_keyed_string_dict(
        allow_files = True,
    ),
    "config_out": attr.output(),
    "output_dir": attr.bool(),
    "_webpack_config_file": attr.label(
        doc = "Internal use only",
        allow_single_file = [".js"],
        default = Label("//webpack/private:webpack.config.js"),
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

def _outs(entry_points, output_dir):
    """Supply some labelled outputs in the common case of a single entry point"""
    result = {}
    entry_point_outs = entry_points.values()
    if output_dir:
        return {}
    else:
        if len(entry_point_outs) > 1:
            fail("Multiple entry points require that output_dir be set")
        out = entry_point_outs[0]

        # TODO: accept other extensions to be output
        result[out] = out + ".js"
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
    devtool = None
    mode = "development"

    if compilation_mode == "fastbuild":
        devtool = "eval"
    elif compilation_mode == "dbg":
        devtool = "eval-source-map"
    elif compilation_mode == "opt":
        mode = "production"

    # Expand webpack config for the entry mapping
    inputs.append(config)
    ctx.actions.expand_template(
        template = ctx.file._webpack_config_file,
        output = ctx.outputs.config_out,
        substitutions = {
            "{ ENTRIES }": json.encode(entry_mapping),
            "devtool: 'DEVTOOL',": "devtool: '{}',".format(devtool) if devtool else "",
            "mode: 'MODE',": "mode: '{}',".format(mode),
        },
    )

def _impl(ctx):
    output_sources = [getattr(ctx.outputs, o) for o in dir(ctx.outputs)]

    inputs = []

    # See CLI documentation at https://webpack.js.org/api/cli/
    args = ctx.actions.args()

    for config in ctx.files.webpack_configs:
        args.add_all(["--config", _relpath(ctx, config)])
        inputs.append(config)

    if len(ctx.files.webpack_configs) > 1:
        args.add("--merge")

    if ctx.attr.output_dir:
        output_sources = [ctx.actions.declare_directory(ctx.attr.name)]
        args.add_all(["--output-path", _relpath(ctx, output_sources[0])])
    else:
        # trim suffix "bundle.js" so that webpack is given a directory to write into
        args.add_all(["--output-path", paths.dirname(_relpath(ctx, output_sources[0]))])

    env = {
        "BAZEL_BINDIR": ctx.bin_dir.path,
    }
    if ctx.attr.use_execroot_entry_point:
        env["JS_BINARY__USE_EXECROOT_ENTRY_POINT"] = "1"
    if ctx.attr.allow_execroot_entry_point_with_no_copy_data_to_bin:
        env["JS_BINARY__ALLOW_EXECROOT_ENTRY_POINT_WITH_NO_COPY_DATA_TO_BIN"] = "1"
    if ctx.attr.chdir:
        env["JS_BINARY__CHDIR"] = ctx.attr.chdir
    entry_points_srcs = ctx.attr.entry_points.keys()
    for (key, value) in ctx.attr.env.items():
        env[key] = " ".join([
            expand_variables(ctx, exp, attribute_name = "env")
            for exp in expand_locations(ctx, value, entry_points_srcs + ctx.attr.srcs + ctx.attr.deps + ctx.attr.data).split(" ")
        ])

    # Add user specified arguments after rule supplied arguments
    args.add_all(ctx.attr.args)

    executable = ctx.executable.webpack_exec_cfg
    execution_requirements = {}

    if ctx.attr.supports_workers:
        executable = ctx.executable.webpack_worker_exec_cfg
        execution_requirements["supports-workers"] = str(int(ctx.attr.supports_workers))

        # Set to use a multiline param-file for worker mode
        args.use_param_file("@%s", use_always = True)
        args.set_param_file_format("multiline")

    webpack_runfiles = depset()
    if ctx.attr.use_execroot_entry_point:
        # Hoist all webpack runfiles to inputs when running from execroot. This is similar
        # to what is done in js_run_binary:
        # https://github.com/aspect-build/rules_js/blob/67c982afd42de970d6356c4ba2989987a10c5086/js/private/js_run_binary.bzl#L306
        webpack_runfiles_inputs = [ctx.attr.webpack_target_cfg]
        if ctx.attr.supports_workers:
            webpack_runfiles_inputs.append(ctx.attr.webpack_worker_target_cfg)
        webpack_runfiles = js_lib_helpers.gather_runfiles(
            ctx = ctx,
            sources = [],
            data = webpack_runfiles_inputs,
            deps = [],
        ).files

    inputs.extend(ctx.files.srcs)
    inputs.extend(ctx.files.deps)
    inputs.extend(ctx.files.entry_points)
    inputs = depset(
        copy_files_to_bin_actions(ctx, inputs),
        transitive = [webpack_runfiles] + [js_lib_helpers.gather_files_from_js_providers(
            targets = ctx.attr.srcs + ctx.attr.deps,
            include_transitive_sources = True,
            # Upstream Type-check actions should not be triggered by bundling
            include_declarations = False,
            include_npm_linked_packages = True,
        )],
    )

    ctx.actions.run(
        progress_message = "Running Webpack [Webpack]",
        executable = executable,
        inputs = inputs,
        outputs = output_sources,
        arguments = [args],
        mnemonic = "Webpack",
        execution_requirements = execution_requirements,
        env = env,
    )

    npm_linked_packages = js_lib_helpers.gather_npm_linked_packages(
        srcs = ctx.attr.srcs,
        deps = [],
    )

    npm_package_store_deps = js_lib_helpers.gather_npm_package_store_deps(
        # Since we're bundling, only propagate `data` npm packages to the direct dependencies of
        # downstream linked `npm_package` targets instead of the common `data` and `deps` pattern.
        targets = ctx.attr.data,
    )

    output_sources_depset = depset(output_sources)

    runfiles = js_lib_helpers.gather_runfiles(
        ctx = ctx,
        sources = output_sources_depset,
        data = ctx.attr.data,
        # Since we're bundling, we don't propagate any transitive runfiles from dependencies
        deps = [],
    )

    return [
        js_info(
            npm_linked_package_files = npm_linked_packages.direct_files,
            npm_linked_packages = npm_linked_packages.direct,
            npm_package_store_deps = npm_package_store_deps,
            sources = output_sources_depset,
            # Since we're bundling, we don't propagate linked npm packages from dependencies since
            # they are bundled and the dependencies are dropped. If a subset of linked npm
            # dependencies are not bundled it is up the the user to re-specify these in `data` if
            # they are runtime dependencies to propagate to binary rules or `srcs` if they are to be
            # propagated to downstream build targets.
            transitive_npm_linked_package_files = npm_linked_packages.transitive_files,
            transitive_npm_linked_packages = npm_linked_packages.transitive,
            # Since we're bundling, we don't propagate any transitive output_sources from dependencies
            transitive_sources = output_sources_depset,
        ),
        DefaultInfo(
            files = output_sources_depset,
            runfiles = runfiles,
        ),
    ]

# Expose a lib here as private API; not intending be exported as public API so we're not bound
# to semver for breaking changes at this level
lib = struct(
    implementation = _impl,
    attrs = _attrs,
    outputs = _outs,
)

_webpack_bundle = rule(
    implementation = lib.implementation,
    attrs = lib.attrs,
    outputs = lib.outputs,
    doc = "",
)

_create_base_config = rule(
    implementation = _create_base_config_impl,
    attrs = _config_attrs,
    doc = "",
)

def webpack_create_configs(name, entry_point, entry_points, webpack_config, chdir, entry_points_mandatory):
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
        chdir = chdir,
        tags = ["manual"],
    )

    # NOTE: generated base config should always come first as it provides sensible defaults under bazel which
    # users might want to override. Also, webpack_worker uses the first webpack config path as the worker key.
    return [default_config] + ([webpack_config] if webpack_config else [])

def webpack_bundle(
        name,
        srcs = [],
        args = [],
        deps = [],
        chdir = None,
        data = [],
        env = {},
        output_dir = False,
        entry_point = None,
        entry_points = {},
        webpack_config = None,
        webpack = Label("@webpack//:webpack"),
        webpack_worker = Label("@webpack//:worker"),
        use_execroot_entry_point = True,
        supports_workers = False,
        allow_execroot_entry_point_with_no_copy_data_to_bin = False,
        **kwargs):
    """Runs the webpack-cli under bazel

    Args:
        name: A unique name for this target.

        srcs: Non-entry point JavaScript source files from the workspace.

            You must not repeat file(s) passed to entry_point/entry_points.

        args: Command line arguments to pass to Webpack.

            These argument passed on the command line before arguments that are added by the rule.
            Run `bazel` with `--subcommands` to see what Webpack CLI command line was invoked.

            See the [Webpack CLI docs](https://webpack.js.org/api/cli/) for a complete list of supported arguments.

        deps: Runtime dependencies which may be loaded during compilation.

        chdir: Working directory to run Webpack under.

            This is needed to workaround some buggy resolvers in webpack loaders, which assume that the
            node_modules tree is located in a parent of the working directory rather than a parent of
            the script with the require statement.

            Note that any relative paths in your configuration may need to be adjusted so they are
            relative to the new working directory.

            See also:
            https://github.com/aspect-build/rules_js/blob/main/docs/js_binary.md#js_binary-chdir

        data: Runtime dependencies to include in binaries/tests that depend on this target.

            The transitive npm dependencies, transitive sources, default outputs and runfiles of targets in the `data` attribute
            are added to the runfiles of this target. They should appear in the '*.runfiles' area of any executable which has
            a runtime dependency on this target.

        env: Environment variables of the action.

            Subject to `$(location)` and make variable expansion.

        output_dir: If True, webpack produces an output directory containing all output files.

        entry_point: The point where to start the application bundling process.

            See https://webpack.js.org/concepts/entry-points/

            Exactly one of `entry_point` to `entry_points` must be specified if `output_dir` is `False`.

        entry_points: The map of entry points to bundle names.

            See https://webpack.js.org/concepts/entry-points/

            Exactly one of `entry_point` to `entry_points` must be specified if `output_dir` is `False`.

        webpack_config: Webpack configuration file.

            See https://webpack.js.org/configuration/

        webpack: Target that executes the webpack-cli binary.

        webpack_worker: Target that executes the webpack-cli binary as a worker.

        use_execroot_entry_point: Use the `entry_point` script of the `webpack` `js_binary` that is in the execroot output tree instead of the copy that is in runfiles.

            `webpack` (and `webpack_worker` if `supports_workers` is one) runfiles are hoisted to the target
            platform when this is configured and included as target platform execroot inputs to the action.

            Using the entry point script that is in the execroot output tree means that there will be no conflicting
            runfiles `node_modules` in the node_modules resolution path which can confuse npm packages such as next and
            react that don't like being resolved in multiple node_modules trees. This more closely emulates the
            environment that tools such as Next.js see when they are run outside of Bazel.

            When True, the `webpack` `js_binary` must have `copy_data_to_bin` set to True (the default) so that all data files
            needed by the binary are available in the execroot output tree. This requirement can be turned off with by
            setting `allow_execroot_entry_point_with_no_copy_data_to_bin` to True.

        supports_workers: Experimental! Use only with caution.

            Allows you to enable the Bazel Worker strategy for this library.

        allow_execroot_entry_point_with_no_copy_data_to_bin: Turn off validation that the `webpack` `js_binary` has `copy_data_to_bin` set to True when `use_execroot_entry_point` is set to True.

            See `use_execroot_entry_point` doc for more info.

        **kwargs: Additional arguments
    """

    webpack_configs = webpack_create_configs(
        name = name,
        entry_point = entry_point,
        entry_points = entry_points,
        webpack_config = webpack_config,
        chdir = chdir,
        entry_points_mandatory = not output_dir,
    )

    _webpack_bundle(
        name = name,
        webpack_configs = webpack_configs,
        srcs = srcs,
        args = args,
        deps = deps,
        chdir = chdir,
        data = data,
        env = env,
        output_dir = output_dir,
        entry_points = {entry_point: name} if entry_point else entry_points,
        webpack_exec_cfg = webpack,
        webpack_target_cfg = webpack,
        webpack_worker_exec_cfg = webpack_worker,
        webpack_worker_target_cfg = webpack_worker,
        use_execroot_entry_point = use_execroot_entry_point,
        supports_workers = supports_workers,
        allow_execroot_entry_point_with_no_copy_data_to_bin = allow_execroot_entry_point_with_no_copy_data_to_bin,
        **kwargs
    )

def webpack_binary(name, node_modules):
    """Create a webpack binary target from linked node_modules in the user's workspace.

    Pass this into the `webpack` attribute of webpack_bundle to use your own linked
    version of webpack rather than rules_webpack's version, which can help to avoid
    certain errors caused by having two copies of webpack. The following three packages
    must be linked into the node_modules virtual store target:

        webpack, webpack-cli, webpack-dev-server

    Args:
        name: Unique name for the binary target
        node_modules: Label pointing to the linked node_modules target where
            webpack is linked, e.g. `//:node_modules`.
    """

    directory_path(
        name = "{}_entrypoint".format(name),
        directory = "{}/webpack/dir".format(node_modules),
        path = "bin/webpack.js",
    )

    js_binary(
        name = name,
        data = [
            "{}/webpack".format(node_modules),
            "{}/webpack-cli".format(node_modules),
            "{}/webpack-dev-server".format(node_modules),
        ],
        entry_point = ":{}_entrypoint".format(name),
        visibility = ["//visibility:public"],
    )
