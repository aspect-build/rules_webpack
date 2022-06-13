# Copyright 2017 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Public API surface is re-exported here.

Users should not load files under "/internal"
"""

load("//webpack/private:webpack_bundle.bzl", _webpack_lib = "lib")
load("//webpack/private/devserver:devserver.bzl", _devserver_lib = "lib")

webpack_bundle = rule(
    implementation = _webpack_lib.implementation,
    attrs = _webpack_lib.attrs,
    outputs = _webpack_lib.outputs,
    doc = "Runs the webpack-cli under bazel.",
)


webpack_dev_server_rule = rule(
	implementation = _devserver_lib.implementation,
	attrs = _devserver_lib.attrs,
	executable = True,
    toolchains = _devserver_lib.toolchains
)


def webpack_dev_server(webpack_repository = "webpack", **kwargs):
    webpack_entry_point = "@{}//:entrypoint".format(webpack_repository)
    deps = [
        "@{}//:node_modules/webpack".format(webpack_repository),
        "@{}//:node_modules/webpack-cli".format(webpack_repository),
        "@{}//:node_modules/webpack-dev-server".format(webpack_repository),
    ]
    webpack_dev_server_rule(
        enable_runfiles = select({
            "@aspect_rules_js//js/private:enable_runfiles": True,
            "//conditions:default": False,
        }),
        entry_point = webpack_entry_point,
        data = kwargs.pop("data", []) + deps,
        **kwargs
    )
