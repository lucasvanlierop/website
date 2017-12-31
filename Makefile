TARGET=$@
SHELL=/bin/bash

all: docker/app/.built

export COMPOSE_PROJECT_NAME=lucasvanlierop-website
export CI_FILE='env/ci/docker-compose.yml'

~/.composer:
	mkdir -p ~/.composer

vendor: \
	docker/sculpin/.built \
	~/.composer \
	composer.json \
	composer.lock
	docker-compose -f ${CI_FILE} run --rm sculpin composer install

.PHONY:
clean:
	rm -rfv source/css/*
	rm -rfv output_prod/*

.DELETE_ON_ERROR: source/css/pygments.css
source/css/pygments.css: docker/sculpin/.built
	docker-compose -f ${CI_FILE} run --rm sculpin sh \
		bin/generate-pygments-css

.DELETE_ON_ERROR: docker/sass/.built
docker/sass/.built: \
	$(shell find docker/sass/* | grep .built)
	docker-compose -f ${CI_FILE} build sass
	touch $@

.DELETE_ON_ERROR: docker/sculpin/.built
docker/sculpin/.built: docker/sculpin/*
	docker-compose -f ${CI_FILE} build sculpin
	touch $@

output_dev:
	mkdir -p $(TARGET)

# todo fix source/*
.DELETE_ON_ERROR: output_prod
output_prod: \
	$(shell find source/) \
	source/css \
    docker/sculpin/.built \
    vendor
	docker-compose -f ${CI_FILE} run --rm sculpin vendor/bin/sculpin generate \
		--env=prod

.DELETE_ON_ERROR: source/css
source/css: \
	docker/sass/.built \
	source/css/pygments.css \
	$(shell find source/scss/ | grep .built)
	docker-compose -f ${CI_FILE} run --rm sass --update /app/source/scss:/app/source/css
	touch $@

.DELETE_ON_ERROR: docker/app/.built
docker/app/.built: \
	docker/app/* \
	output_prod
	docker-compose -f ${CI_FILE} build app
	touch $@

.PHONY: start
start: output_dev
	docker-compose up

.PHONY: test
test: docker/app/.built
	docker-compose -f ${CI_FILE} up -d --no-build --force-recreate --remove-orphans
	tests/smoke-test.sh
	tests/validate-html.sh
	docker-compose -f ${CI_FILE} stop
