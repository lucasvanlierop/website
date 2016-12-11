.RECIPEPREFIX +=

SHELL=/bin/bash

all: test

PROD_FILE='docker-compose.yml'

sass:
    docker-compose run sass --update /app/web/sass:/app/web/css

build: sass
    docker-compose -f ${PROD_FILE} up -d --build --force-recreate

test: build
    tests/smoke-test.sh
    tests/validate-html.sh
    docker-compose -f ${PROD_FILE} stop
