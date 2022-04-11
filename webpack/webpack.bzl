"""Webpack bundle producing rule definition."""

load("@build_bazel_rules_nodejs//:providers.bzl", "DeclarationInfo", "ExternalNpmPackageInfo", "JSModuleInfo", "node_modules_aspect", "run_node")
load("@build_bazel_rules_nodejs//internal/linker:link_node_modules.bzl", "module_mappings_aspect")

_ATTRS = {
    "args": attr.string_list(
        doc = """Command line arguments to pass to Webpack.

These argument passed on the command line before arguments that are added by the rule.
Run `bazel` with `--subcommands` to see what Webpack CLI command line was invoked.

See the [Webpack CLI docs](https://webpack.js.org/api/cli/) for a complete list of supported arguments.""",
        default = [],
    ),
    "data": attr.label_list(
        doc = """Runtime dependencies which may be loaded during compliation.""",
        aspects = [module_mappings_aspect, node_modules_aspect],
        allow_files = True,
    ),
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

Allows you to enable the Bazel Worker strategy for this library.
When enabled, this rule invokes the "_webpack_worker_bin"
worker aware binary rather than "webpack_bin".""",
        default = False,
    ),
    "webpack_cli_bin": attr.label(
        doc = "Target that executes the webpack-cli binary",
        executable = True,
        cfg = "exec",
        default = Label("//webpack-cli/bin:webpack-cli"),
    ),
    "webpack_config": attr.label(
        doc = """Webpack configuration file.
        
See https://webpack.js.org/configuration/""",
        allow_single_file = [".js"],
        mandatory = True,
    ),
    "_webpack_worker_bin": attr.label(
        doc = "Internal use only",
        executable = True,
        cfg = "exec",
        default = Label("//@aspect-build/webpack/bin:webpack-worker"),
    ),
    "_webpack_config_file": attr.label(
        doc = "Internal use only",
        allow_single_file = [".js"],
        default = "//@aspect-build/webpack/webpack:webpack.config.js",
    ),
    "_link_modules_script": attr.label(
        default = Label("@build_bazel_rules_nodejs//internal/linker:index.js"),
        allow_single_file = True,
    ),
}

def _desugar_entry_point_names(name, entry_point, entry_points):
    """Users can specify entry_point (sugar) or entry_points (long form).

    This function allows our code to treat it like they always used the long form.

    It also performs validation:
    - exactly one of these attributes should be specified
    """
    if entry_point and entry_points:
        fail("Cannot specify both entry_point and entry_points")
    if not entry_point and not entry_points:
        fail("One of entry_point or entry_points must be specified")
    if entry_point:
        return [name]
    return entry_points.values()

def _desugar_entry_points(name, entry_point, entry_points, inputs):
    """Like above, but used by the implementation function, where the types differ.

    It also performs validation:
    - attr.label_keyed_string_dict doesn't accept allow_single_file
      so we have to do validation now to be sure each key is a label resulting in one file

    It converts from dict[target: string] to dict[file: string]
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

def _no_ext(f):
    return f.short_path[:-len(f.extension) - 1]

def _webpack_outs(name, entry_point, entry_points, output_dir):
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

def _webpack_impl(ctx):
    inputs = _inputs(ctx)
    outputs = [getattr(ctx.outputs, o) for o in dir(ctx.outputs)]

    # See CLI documentation at https://webpack.js.org/api/cli/
    args = ctx.actions.args()

    if ctx.attr.supports_workers:
        # Set to use a multiline param-file for worker mode
        args.use_param_file("@%s", use_always = True)
        args.set_param_file_format("multiline")

    # Add user specified arguments *before* rule supplied arguments
    args.add_all(ctx.attr.args)

    # Desugar entrypoints
    entry_points = _desugar_entry_points(ctx.label.name, ctx.attr.entry_point, ctx.attr.entry_points, inputs).items()

    entry_mapping = {}

    for entry_point in entry_points:
        inputs.append(entry_point[0])

        # TODO: find an idiomatic way to do this.
        entry_mapping[entry_point[1]] = "./%s" % (entry_point[0].path)

    # Expand webpack config for the entry mapping
    config = ctx.actions.declare_file("_%s.webpack.config.js" % ctx.label.name)

    ctx.actions.expand_template(
        template = ctx.file._webpack_config_file,
        output = config,
        substitutions = {
            "{ ENTRIES }": json.encode(entry_mapping),
        },
    )

    # Add generated config
    args.add_all(["-c", config.path])
    inputs.append(config)

    # Add user defined config as an input and argument
    args.add_all(["-c", ctx.file.webpack_config.path])
    inputs.append(ctx.file.webpack_config)

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

    executable = "webpack_cli_bin"
    execution_requirements = {}
    env = {
        "COMPILATION_MODE": ctx.var["COMPILATION_MODE"],
    }

    if ctx.attr.supports_workers:
        executable = "_webpack_worker_bin"
        execution_requirements["supports-workers"] = str(int(ctx.attr.supports_workers))
        env["_LINKER_PATH"] = ctx.file._link_modules_script.path
        env["MODULES_MANIFEST"] = "/".join([ctx.bin_dir.path, ctx.label.package, "_%s.module_mappings.json" % ctx.label.name])

    if ctx.attr.output_dir:
        outputs = [ctx.actions.declare_directory(ctx.attr.name)]
        args.add_all(["--output-path", outputs[0].path])
    else:
        args.add_all(["--output-path", outputs[0].dirname])

    # Merge all webpack configs
    args.add("--merge")

    run_node(
        ctx,
        progress_message = "Running Webpack [webpack-cli]",
        executable = executable,
        inputs = inputs,
        outputs = outputs,
        tools = [ctx.file._link_modules_script],
        arguments = [args],
        mnemonic = "webpack",
        execution_requirements = execution_requirements,
        env = env,
    )

    return [DefaultInfo(files = depset(outputs))]

def _expand_locations(ctx, s):
    # `.split(" ")` is a work-around https://github.com/bazelbuild/bazel/issues/10309
    # _expand_locations returns an array of args to support $(execpaths) expansions.
    # TODO: If the string has intentional spaces or if one or more of the expanded file
    # locations has a space in the name, we will incorrectly split it into multiple arguments
    return ctx.expand_location(s, targets = ctx.attr.data).split(" ")

def _inputs(ctx):
    # Also include files from npm fine grained deps as inputs.
    # These deps are identified by the ExternalNpmPackageInfo provider.
    inputs_depsets = []
    for d in ctx.attr.data:
        if ExternalNpmPackageInfo in d:
            inputs_depsets.append(d[ExternalNpmPackageInfo].sources)
        if JSModuleInfo in d:
            inputs_depsets.append(d[JSModuleInfo].sources)
        if DeclarationInfo in d:
            inputs_depsets.append(d[DeclarationInfo].declarations)
    return depset(ctx.files.data, transitive = inputs_depsets).to_list()

webpack = rule(
    implementation = _webpack_impl,
    attrs = _ATTRS,
    outputs = _webpack_outs,
    doc = "Runs the webpack-cli under bazel.",
)
