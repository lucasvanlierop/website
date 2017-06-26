.RECIPEPREFIX +=

SHELL=/bin/bash

all: build

export CI_FILE='env/ci/docker-compose.yml'

install-dependencies:
    mkdir -p ~/.composer
    docker-compose -f ${CI_FILE} run --rm sculpin composer install

clean:
    rm -rfv source/css/*
    rm -rfv output_prod/*

pygments-css:
    docker-compose -f ${CI_FILE} run --rm sculpin sh \
        bin/generate-pygments-css

docker-tool-images:
    docker-compose -f ${CI_FILE} build sass sculpin

sculpin:
    docker-compose -f ${CI_FILE} run --rm sculpin vendor/bin/sculpin generate \
        --env=prod \
        --url=http://lucasvanlierop.nl

sass:
    docker-compose -f ${CI_FILE} run --rm sass --update /app/source/scss:/app/source/css

build: docker-tool-images install-dependencies clean pygments-css sass sculpin
    docker-compose -f ${CI_FILE} build app
    docker-compose -f ${CI_FILE} up -d --force-recreate --remove-orphans

start:
    docker-compose up

test: build
    tests/smoke-test.sh
    tests/validate-html.sh
    docker-compose -f ${CI_FILE} stop
