.RECIPEPREFIX +=

SHELL=/bin/bash

all: build

PROD_FILE='docker-compose.yml'

spress:
    docker-compose run spress site:build

sass:
    docker-compose run sass --update /app/src/scss:/app/build/css

build: sass spress
    docker-compose -f ${PROD_FILE} up -d --build --force-recreate --remove-orphans

test: build
    tests/smoke-test.sh
    tests/validate-html.sh
    docker-compose -f ${PROD_FILE} stop
