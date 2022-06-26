"webpack_dev_server macro"
load("@aspect_rules_js//js:defs.bzl", "js_binary_lib")
load("@bazel_skylib//lib:dicts.bzl", "dicts")


_attrs = dicts.add(js_binary_lib.attrs, {
    "entry_point": attr.label(
        doc = "Internal use only",
        mandatory = True,
    ),
    "srcs": attr.label_list(
        doc = "JavaScript source files from the workspace.",
        allow_files = True
    ),
	"webpack_config": attr.label(
        doc = """Webpack configuration file.
        
See https://webpack.js.org/configuration/""",
		allow_single_file = [".js"],
        mandatory = False
	),
    "_webpack_devserver_config": attr.label(
        doc = "Internal use only",
        allow_single_file = [".js"], 
        default = Label("//webpack/private/devserver:webpack.config.js")
    ),
})


def _impl(ctx):

    fixed_args = [
        "serve",
        "--output-path",
        "./dist",
        "-c", 
        ctx.file._webpack_devserver_config.short_path
    ]

    files = ctx.files.srcs + ctx.files.data + [
        ctx.file._webpack_devserver_config
    ]

    if ctx.attr.webpack_config:
        files.append(ctx.file.webpack_config)
        fixed_args.extend(["-c", ctx.file.webpack_config.short_path, "--merge"])


    launcher = js_binary_lib.create_launcher(
        ctx,
        log_prefix_rule_set = "aspect_rules_webpack",
        log_prefix_rule = "webpack_devserver",
        fixed_args = fixed_args,
    )

    runfiles = launcher.runfiles.merge(ctx.runfiles(
        files = files,
    ))

    return [DefaultInfo(
        executable = launcher.executable,
        runfiles = runfiles
    )]

lib = struct(
    attrs = _attrs,
    implementation = _impl,
    toolchains = js_binary_lib.toolchains,
)