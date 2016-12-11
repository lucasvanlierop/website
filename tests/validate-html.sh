#!/usr/bin/env bash

# Pull image first so no docker output ends up in stderr later on.
docker pull magnetikonline/html5validator:latest

assert_valid_html() {
    local url=$1
    local validation_errors


    # Note that in order to capture the commands stderr its' redirected to stdout
    # While stdout itself is redirected to a third filedescriptor which is outputted afterwards.
    { validation_errors=$(
        docker run \
        --rm \
        --name=html-validator \
        --network=container:lucasvanlierop-website \
        magnetikonline/html5validator \
        java -jar /root/build/validator.nu/vnu.jar $url \
        2>&1 1>&3-
    ) ;} 3>&1

    # Catch warnings too
    if [[ ! -z "${validation_errors}" ]]; then
        echo "HTML NOT VALID ${validation_errors}"
        exit 1
    fi
}

assert_valid_html 'http://app'
assert_valid_html 'http://app/about/'
assert_valid_html 'http://app/expertise/'
assert_valid_html 'http://app/public-appearances/'
assert_valid_html 'http://app/work/'
