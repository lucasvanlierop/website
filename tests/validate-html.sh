#!/usr/bin/env bash

set -x

VALIDATE_OUTPUT=$(
    docker run \
    --rm \
    --name=html-validator \
    --network=container:lucasvanlierop-website-nginx \
    magnetikonline/html5validator \
    java -jar /root/build/validator.nu/vnu.jar http://nginx \
    2>&1
)

# Catch warnings too
if [[ ! -z "${VALIDATE_OUTPUT}" ]]; then
    echo "HTML NOT VALID ${VALIDATE_OUTPUT}"
    exit 1
fi
