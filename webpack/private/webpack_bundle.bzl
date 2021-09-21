"Webpack rule for bundling as an action"

load("expand_variables.bzl", "expand_variables")

_DOC = """Webpack bundling rule"""

_ATTRS = {
    "args": attr.string_list(),
    "data": attr.label_list(allow_files = True),
    "out": attr.output(),
    "webpack_entry": attr.string(default = "./node_modules/webpack-cli/bin/cli.js"),
    "_npm_deps": attr.label(default = "//:deps"),
}

def _expand_locations(ctx, s):
    # `.split(" ")` is a work-around https://github.com/bazelbuild/bazel/issues/10309
    # _expand_locations returns an array of args to support $(execpaths) expansions.
    # TODO: If the string has intentional spaces or if one or more of the expanded file
    # locations has a space in the name, we will incorrectly split it into multiple arguments
    return ctx.expand_location(s, targets = ctx.attr.data).split(" ")

def _webpack_bundle_impl(ctx):
    args = ctx.actions.args()
    args.add(ctx.attr.webpack_entry)
    for a in ctx.attr.args:
        args.add_all([expand_variables(ctx, e, outs = [ctx.outputs.out], output_dir = False) for e in _expand_locations(ctx, a)])

    toolchain = ctx.toolchains["@rules_nodejs//nodejs:toolchain_type"].nodeinfo
    ctx.actions.run(
        inputs = toolchain.tool_files + ctx.files.data + ctx.files._npm_deps,
        executable = toolchain.target_tool_path,
        arguments = [args],
        outputs = [ctx.outputs.out],
    )
    return []

webpack_bundle = rule(
    implementation = _webpack_bundle_impl,
    attrs = _ATTRS,
    doc = _DOC,
    toolchains = ["@rules_nodejs//nodejs:toolchain_type"],
)
