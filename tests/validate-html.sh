#!/usr/bin/env bash

# Note that in order to capture the commands stderr its' redirected to stdout
# While stdout itself is redirected to a third filedescriptor which is outputted later on.
{ VALIDATE_ERRORS=$(
    docker run \
    --rm \
    --name=html-validator \
    --network=container:lucasvanlierop-website-nginx \
    magnetikonline/html5validator \
    java -jar /root/build/validator.nu/vnu.jar http://nginx \
    2>&1 1>&3-
) ;} 3>&1

# Catch warnings too
if [[ ! -z "${VALIDATE_ERRORS}" ]]; then
    echo "HTML NOT VALID ${VALIDATE_ERRORS}"
    exit 1
fi
