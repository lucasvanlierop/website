#!/usr/bin/env bash

set -e

assert_page_contains() {
    local test_url="$1";
    local expected_content="$2"
    local test_output

    declare -i timeout=5

    while ! test_output=`docker-compose -f env/ci/docker-compose.yml run --rm --entrypoint=curl sculpin --silent --fail ${test_url}`;
        do sleep 0.1;
    done

    if [[ -z $(echo "${test_output}" | grep "${expected_content}") ]]; then
        echo "Failed asserting that '${test_output}' contains '$expected_content'" && exit 1;
    fi
}

assert_page_contains 'http://app' 'freelance software developer'
assert_page_contains 'http://app/about/' 'About Lucas van Lierop'
assert_page_contains 'http://app/expertise/' 'My expertise'
assert_page_contains 'http://app/public-appearances/' 'Public appearances'
assert_page_contains 'http://app/work/' 'This is some of the work I did at my former employers.'
