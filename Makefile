SHELL=/bin/bash

all: build

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

.DELETE_ON_ERROR: \
	docker/sculpin/.built \
	app/source/css/pygments.css
app/source/css/pygments.css:
	docker-compose -f ${CI_FILE} run --rm sculpin sh \
		bin/generate-pygments-css

.DELETE_ON_ERROR: docker/sass/.built
docker/sass/.built: docker/sass/*
	docker-compose -f ${CI_FILE} build sass
	touch $@

.DELETE_ON_ERROR: docker/sculpin/.built
docker/sculpin/.built: docker/sculpin/*
	docker-compose -f ${CI_FILE} build sculpin
	touch $@

# todo fix source/*
.DELETE_ON_ERROR: output_prod
output_prod: \
	source/*  \
	docker/sculpin/.built
	docker-compose -f ${CI_FILE} run --rm sculpin vendor/bin/sculpin generate \
		--env=prod

.DELETE_ON_ERROR: app/source/css
app/source/css: docker/sass/.built
	docker-compose -f ${CI_FILE} run --rm sass --update /app/source/scss:/app/source/css

.PHONY: build
build: \
	docker/sculpin/.built \
	vendor \
	clean \
	app/source/css/pygments.css \
	app/source/css output_prod
	docker-compose -f ${CI_FILE} build app
	docker-compose -f ${CI_FILE} up -d --no-build --force-recreate --remove-orphans

.PHONY: start
start:
	docker-compose up

.PHONY: test
test: build
	tests/smoke-test.sh
	tests/validate-html.sh
	docker-compose -f ${CI_FILE} stop
