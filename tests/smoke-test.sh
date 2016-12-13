#!/usr/bin/env bash

set -e
#set -x

assert_page_contains() {
    local test_url="$1";
    local expected_content="$2"
    local test_output

    declare -i timeout=5

    while ! test_output=`curl -s --fail ${test_url}`;
        do sleep 0.1;
    done

    if grep -q '$expected_content' <<<$test_output; then
        echo "Failed asserting that '${test_output}' contains '$expected_content'" && exit 1;
    fi
}

assert_page_contains 'http://localhost' 'Lucas van Lierop | freelance software engineer'
assert_page_contains 'http://localhost/about/' 'Contact'
assert_page_contains 'http://localhost/about/' 'About Lucas van Lierop'
assert_page_contains 'http://localhost/expertise/' 'My expertise'
assert_page_contains 'http://localhost/public-appearances/' 'Public appearances'
assert_page_contains 'http://localhost/work/' 'My work'
