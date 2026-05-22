"""Transition rule for testing under specific Bazel compilation modes."""

def _compilation_mode_impl(settings, attr):
    _ignore = (settings)
    return {"//command_line_option:compilation_mode": attr.compilation_mode}

_compilation_mode_transition = transition(
    implementation = _compilation_mode_impl,
    inputs = [],
    outputs = ["//command_line_option:compilation_mode"],
)

def _with_compilation_mode_impl(ctx):
    target = ctx.attr.target[0]
    executable = target[DefaultInfo].files_to_run.executable
    return [DefaultInfo(
        files = depset([executable]),
        runfiles = ctx.runfiles(files = [executable]),
    )]

with_compilation_mode = rule(
    implementation = _with_compilation_mode_impl,
    attrs = {
        "target": attr.label(
            cfg = _compilation_mode_transition,
            mandatory = True,
        ),
        "compilation_mode": attr.string(
            mandatory = True,
            values = ["fastbuild", "dbg", "opt"],
        ),
    },
)
