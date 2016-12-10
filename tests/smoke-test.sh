#!/usr/bin/env bash

declare -i timeout=5

while ! TEST_OUTPUT=`curl -s --fail http://localhost`;
    do sleep 0.1;
done

EXPECTED_CONTENT='Lucas van Lierop | freelance software engineer'

## Assert server response
if grep -q "$EXPECTED_CONTENT" <<<$TEST_OUTPUT; then
    echo "Failed asserting that '${TEST_OUTPUT}' contains '$EXPECTED_CONTENT'" && exit 1;
fi
