.RECIPEPREFIX +=

SHELL=/bin/bash

all: build

CI_FILE='env/ci/docker-compose.yml'
PROD_FILE='env/prod/docker-compose.yml'

spress:
    docker-compose -f ${CI_FILE} run spress site:build

sass:
    docker-compose -f ${CI_FILE} run sass --update /app/src/scss:/app/src/content/css

build: sass spress
    docker-compose -f ${PROD_FILE} up -d --build --force-recreate --remove-orphans

test: build
    tests/smoke-test.sh
    tests/validate-html.sh
    docker-compose -f ${PROD_FILE} stop
