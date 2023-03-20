"""Webpack bundle producing rule definition."""

load("@aspect_bazel_lib//lib:copy_file.bzl", "copy_file")
load("@aspect_bazel_lib//lib:copy_to_bin.bzl", "copy_files_to_bin_actions")
load("@aspect_bazel_lib//lib:expand_make_vars.bzl", "expand_locations", "expand_variables")
load("@aspect_rules_js//js:defs.bzl", "js_binary")
load("@aspect_rules_js//js:libs.bzl", "js_lib_helpers")
load("@aspect_rules_js//js:providers.bzl", "JsInfo", "js_info")
load("@bazel_skylib//lib:paths.bzl", "paths")
load(":webpack_binary.bzl", "webpack_binary")
load(":webpack_create_configs.bzl", "webpack_create_configs")

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
    ),
    "webpack_target_cfg": attr.label(
        executable = True,
        cfg = "target",
    ),
    "webpack_worker_exec_cfg": attr.label(
        doc = "",
        executable = True,
        cfg = "exec",
    ),
    "webpack_worker_target_cfg": attr.label(
        doc = "",
        executable = True,
        cfg = "target",
    ),
    "webpack_configs": attr.label_list(
        allow_files = True,
        doc = "Internal use only",
    ),
    "use_execroot_entry_point": attr.bool(
        default = True,
    ),
    "_worker_js": attr.label(
        allow_single_file = True,
        default = "@aspect_rules_js//js/private/worker:worker.js",
    ),
}

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

    no_copy_bin_inputs = []
    if ctx.attr.supports_workers:
        executable = ctx.executable.webpack_worker_exec_cfg
        execution_requirements["supports-workers"] = str(int(ctx.attr.supports_workers))

        no_copy_bin_inputs.append(ctx.file._worker_js)

        path_to_execroot = ("/".join([".."] * len(ctx.label.package.split("/"))) if ctx.label.package else ".") + "/"
        if ctx.attr.use_execroot_entry_point:
            env["JS_BINARY__ALLOW_EXECROOT_ENTRY_POINT_WITH_NO_COPY_DATA_TO_BIN"] = "1"
            env["RULES_JS_WORKER"] = path_to_execroot + "../../../" + ctx.file._worker_js.path
        else:
            env["RULES_JS_WORKER"] = path_to_execroot + ctx.file._worker_js.short_path

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
        copy_files_to_bin_actions(ctx, inputs) + no_copy_bin_inputs,
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

def webpack_bundle(
        name,
        node_modules,
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
        use_execroot_entry_point = True,
        supports_workers = False,
        **kwargs):
    """Runs the webpack-cli under bazel

    Args:
        name: A unique name for this target.

        node_modules: Label pointing to the linked node_modules target where
            webpack is linked, e.g. `//:node_modules`.

            The following packages must be linked into the node_modules supplied:

                webpack, webpack-cli

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

        use_execroot_entry_point: Use the `entry_point` script of the `webpack` `js_binary` that is in the execroot output tree instead of the copy that is in runfiles.

            When set, runfiles are hoisted to the target platform when this is configured and included as target
            platform execroot inputs to the action.

            Using the entry point script that is in the execroot output tree means that there will be no conflicting
            runfiles `node_modules` in the node_modules resolution path which can confuse npm packages such as next and
            react that don't like being resolved in multiple node_modules trees. This more closely emulates the
            environment that tools such as Next.js see when they are run outside of Bazel.

        supports_workers: Experimental! Use only with caution.

            Allows you to enable the Bazel Worker strategy for this library.

        **kwargs: Additional arguments
    """

    webpack_binary_target = "_{}_webpack_binary".format(name)

    webpack_binary(
        name = webpack_binary_target,
        node_modules = node_modules,
        additional_packages = ["webpack-cli"],
    )

    webpack_configs = webpack_create_configs(
        name = name,
        entry_point = entry_point,
        entry_points = entry_points,
        webpack_config = webpack_config,
        chdir = chdir,
        entry_points_mandatory = not output_dir,
    )

    webpack_worker_binary_target = None
    if supports_workers:
        webpack_worker_binary_target = "_{}_webpack_worker_binary".format(name)
        copy_file(
            name = "_{}_copy_webpack_worker".format(name),
            src = "@aspect_rules_webpack//webpack/private:webpack_worker.js",
            out = "_{}_webpack_worker.js".format(name),
        )
        js_binary(
            name = webpack_worker_binary_target,
            data = [
                "{}/webpack".format(node_modules),
                "{}/webpack-cli".format(node_modules),
                "{}/webpack-dev-server".format(node_modules),
                "@aspect_rules_js//js/private/worker:worker.js",
            ],
            copy_data_to_bin = False,
            entry_point = "_{}_webpack_worker.js".format(name),
            visibility = ["//visibility:public"],
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
        webpack_exec_cfg = webpack_binary_target,
        webpack_target_cfg = webpack_binary_target,
        webpack_worker_exec_cfg = webpack_worker_binary_target,
        webpack_worker_target_cfg = webpack_worker_binary_target,
        use_execroot_entry_point = use_execroot_entry_point,
        supports_workers = supports_workers,
        **kwargs
    )
