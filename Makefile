.RECIPEPREFIX +=

SHELL=/bin/bash

all: test

PROD_FILE='docker-compose.yml'

test:
    docker-compose -f ${PROD_FILE} up -d --build --force-recreate
    tests/smoke-test.sh
    docker-compose -f ${PROD_FILE} stop
