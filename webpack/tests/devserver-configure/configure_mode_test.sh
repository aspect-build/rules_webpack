#!/usr/bin/env bash
set -euo pipefail

# $1 is the rootpath to the devserver launcher script
# $2 is the expected WEBPACK_DEVTOOL value, or "unset" if it should not be present
launcher="${TEST_SRCDIR}/${TEST_WORKSPACE}/${1}"
expected_devtool="${2}"
pass=true

if grep -q 'export WEBPACK_MODE="development"' "${launcher}"; then
    echo "PASS: WEBPACK_MODE=development is exported in the devserver launcher"
else
    echo "FAIL: WEBPACK_MODE=development not found in devserver launcher"
    echo "      configure_mode = True should set WEBPACK_MODE to 'development'"
    pass=false
fi

if [[ "${expected_devtool}" == "unset" ]]; then
    if grep -q 'export WEBPACK_DEVTOOL=' "${launcher}"; then
        echo "FAIL: WEBPACK_DEVTOOL should not be set but was found in devserver launcher"
        grep 'WEBPACK_DEVTOOL' "${launcher}" || true
        pass=false
    else
        echo "PASS: WEBPACK_DEVTOOL is correctly not exported"
    fi
else
    if grep -q "export WEBPACK_DEVTOOL=\"${expected_devtool}\"" "${launcher}"; then
        echo "PASS: WEBPACK_DEVTOOL=\"${expected_devtool}\" is exported in the devserver launcher"
    else
        echo "FAIL: WEBPACK_DEVTOOL does not have expected value '${expected_devtool}'"
        grep 'WEBPACK_DEVTOOL' "${launcher}" || echo "      (WEBPACK_DEVTOOL not found at all)"
        pass=false
    fi
fi

${pass} || exit 1
