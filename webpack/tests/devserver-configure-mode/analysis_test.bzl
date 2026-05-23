"""Analysis tests for webpack_devserver configure_mode behavior."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")

_RuleArgsInfo = provider(fields = ["args"])

def _rule_args_aspect_impl(target, ctx):
    return [_RuleArgsInfo(args = ctx.rule.attr.args)]

_rule_args_aspect = aspect(implementation = _rule_args_aspect_impl)

def _devserver_mode_test_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)
    args = target[_RuleArgsInfo].args

    if ctx.attr.expect_mode:
        asserts.true(
            env,
            "--mode" in args,
            "Expected --mode in devserver args but it was absent. Args: " + str(args),
        )
    else:
        asserts.false(
            env,
            "--mode" in args,
            "configure_mode = False should not pass --mode to webpack. Args: " + str(args),
        )

    return analysistest.end(env)

devserver_mode_test = analysistest.make(
    _devserver_mode_test_impl,
    attrs = {"expect_mode": attr.bool(mandatory = True)},
    extra_target_under_test_aspects = [_rule_args_aspect],
)
