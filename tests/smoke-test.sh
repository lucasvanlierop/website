#!/usr/bin/env bash

set -e

assert_page_contains() {
    local test_url="$1";
    local expected_content="$2"
    local test_output

    declare -i timeout=5

    while ! test_output=`docker-compose -f env/ci/docker-compose.yml run --rm --entrypoint=curl sculpin -s --fail ${test_url}`;
        do sleep 0.1;
    done

    if grep -q '$expected_content' <<<$test_output; then
        echo "Failed asserting that '${test_output}' contains '$expected_content'" && exit 1;
    fi
}

assert_page_contains 'http://app' 'Lucas van Lierop | freelance software developer'
assert_page_contains 'http://app/about/' 'About Lucas van Lierop'
assert_page_contains 'http://app/expertise/' 'My expertise'
assert_page_contains 'http://app/public-appearances/' 'Public appearances'
assert_page_contains 'http://app/work/' 'My work'
