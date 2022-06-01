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
load("//webpack/private/devserver:devserver.bzl", _webpack_dev_server = "webpack_dev_server")

webpack_bundle = rule(
    implementation = _webpack_lib.implementation,
    attrs = _webpack_lib.attrs,
    outputs = _webpack_lib.outputs,
    doc = "Runs the webpack-cli under bazel.",
)


webpack_dev_server = _webpack_dev_server