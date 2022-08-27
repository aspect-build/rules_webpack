"webpack_dev_server macro"

load("@aspect_rules_js//js:libs.bzl", "js_binary_lib", "js_lib_helpers")
load("@bazel_skylib//lib:dicts.bzl", "dicts")

_attrs = dicts.add(js_binary_lib.attrs, {
    "entry_point": attr.label(
        doc = "Internal use only",
        mandatory = True,
    ),
    "webpack_config": attr.label(
        doc = """Webpack configuration file.
        
See https://webpack.js.org/configuration/""",
        allow_single_file = [".js"],
        mandatory = False,
    ),
    "_webpack_devserver_config": attr.label(
        doc = "Internal use only",
        allow_single_file = [".js"],
        default = Label("//webpack/private/devserver:webpack.config.js"),
    ),
})

def _impl(ctx):
    fixed_args = [
        "serve",
        "--output-path",
        "./dist",
        "-c",
        ctx.file._webpack_devserver_config.short_path,
    ]

    files = ctx.files.data[:]
    files.append(ctx.file._webpack_devserver_config)

    if ctx.attr.webpack_config:
        files.append(ctx.file.webpack_config)
        fixed_args.extend(["-c", ctx.file.webpack_config.short_path, "--merge"])

    launcher = js_binary_lib.create_launcher(
        ctx,
        log_prefix_rule_set = "aspect_rules_webpack",
        log_prefix_rule = "webpack_devserver",
        fixed_args = fixed_args,
    )

    runfiles = ctx.runfiles(
        files = files,
        transitive_files = js_lib_helpers.gather_files_from_js_providers(
            targets = ctx.attr.data,
            include_transitive_sources = ctx.attr.include_transitive_sources,
            include_declarations = ctx.attr.include_declarations,
            include_npm_linked_packages = ctx.attr.include_npm_linked_packages,
        ),
    ).merge(launcher.runfiles).merge_all([
        target[DefaultInfo].default_runfiles
        for target in ctx.attr.data
    ])

    return [
        DefaultInfo(
            executable = launcher.executable,
            runfiles = runfiles,
        ),
    ]

lib = struct(
    attrs = _attrs,
    implementation = _impl,
    toolchains = js_binary_lib.toolchains,
)
