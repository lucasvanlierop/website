.RECIPEPREFIX +=

SHELL=/bin/bash

all: build

CI_FILE='env/ci/docker-compose.yml'
PROD_FILE='env/prod/docker-compose.yml'

sculpin:
    docker-compose -f ${CI_FILE} run --rm sculpin vendor/bin/sculpin generate --env=prod

sass:
    docker-compose -f ${CI_FILE} run --rm sass --update /app/source/scss:/app/source/css

build: sass sculpin
    docker-compose -f ${PROD_FILE} up -d --build --force-recreate --remove-orphans

start:
    docker-compose up

test: build
    tests/smoke-test.sh
    tests/validate-html.sh
    docker-compose -f ${PROD_FILE} stop
