set -o errexit

cd $( dirname -- "$BASH_SOURCE"; )

message() {
    echo "###########################"
    echo "$1"
}

exit_with_message() {
    message "FAIL: $1"
    exit 1
}


message "Case 1: Test passes"
bazel test //... || exit_with_message "Case 1: Expected bazel test //... to pass"


message "Case 2: Warmed up worker caughts changes"
cp ./module.js ./module.js.bk
cp ./expected.js_ ./expected.js_.bk

trap "mv ./module.js.bk ./module.js && mv ./expected.js_.bk ./expected.js_" EXIT

echo console.log\(\"$(date)\"\) > ./module.js
bazel test //... && exit_with_message "Case 2: Expected bazel test //.. to fail because bundle should have differ after the change."
bazel run //:write_bundle
bazel test //...


message "All tests have passed"