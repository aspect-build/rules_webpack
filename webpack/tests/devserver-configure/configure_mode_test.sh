#!/usr/bin/env bash
set -euo pipefail

# $1 is the rootpath to the devserver launcher script
launcher="${TEST_SRCDIR}/${TEST_WORKSPACE}/${1}"
pass=true

if grep -q 'export WEBPACK_MODE=' "${launcher}"; then
    echo "PASS: WEBPACK_MODE is exported in the devserver launcher"
else
    echo "FAIL: WEBPACK_MODE not found in devserver launcher"
    echo "      configure_mode = True should set the WEBPACK_MODE env var"
    pass=false
fi

if grep -q 'export WEBPACK_DEVTOOL=' "${launcher}"; then
    echo "PASS: WEBPACK_DEVTOOL is exported in the devserver launcher"
else
    echo "FAIL: WEBPACK_DEVTOOL not found in devserver launcher"
    echo "      configure_devtool = True should set the WEBPACK_DEVTOOL env var"
    pass=false
fi

${pass} || exit 1
