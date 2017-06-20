.RECIPEPREFIX +=

SHELL=/bin/bash

all: build

export CI_FILE='env/ci/docker-compose.yml'

spress:
    docker-compose -f ${CI_FILE} run --rm spress site:build

sass:
    docker-compose -f ${CI_FILE} run --rm sass --update /app/src/scss:/app/src/content/css

build: sass spress
    docker-compose -f ${CI_FILE} up -d --build --force-recreate --remove-orphans

start:
    docker-compose up

test: build
    tests/smoke-test.sh
    tests/validate-html.sh
    docker-compose -f ${CI_FILE} stop
