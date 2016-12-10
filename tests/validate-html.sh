#!/usr/bin/env bash

set -x

VALIDATE_ERRORS=$(
    docker run \
    --rm \
    --name=html-validator \
    --network=container:lucasvanlierop-website-nginx \
    magnetikonline/html5validator \
    java -jar /root/build/validator.nu/vnu.jar http://nginx \
    2>&1 > /dev/null
)

# Catch warnings too
if [[ ! -z "${VALIDATE_ERRORS}" ]]; then
    echo "HTML NOT VALID ${VALIDATE_ERRORS}"
    exit 1
fi
