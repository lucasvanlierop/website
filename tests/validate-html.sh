#!/usr/bin/env bash

docker run \
    --rm \
    --name=html-validator \
    --network=lucasvanlieropwebsite_default \
    magnetikonline/html5validator \
    java -jar /root/build/validator.nu/vnu.jar http://nginx
