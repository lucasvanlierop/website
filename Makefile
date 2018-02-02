export HOST_UID=$(shell id -u)
export HOST_GID=$(shell id -g)

ifeq ($(PLATFORM),Darwin)
export DOCKER_HOST_IP_OR_NAME = docker.for.mac.localhost
else ifeq ($(PLATFORM),Linux)
export DOCKER_HOST_IP_OR_NAME=$(shell ip -f inet addr show docker0 | grep -Po 'inet \K[\d.]+')
endif

TARGET=$@
SHELL=/bin/bash
.DELETE_ON_ERROR:

include make/travis.mk

all: docker/app/.built

export COMPOSE_PROJECT_NAME=lucasvanlierop-website
export CI_FILE='env/ci/docker-compose.yml'

~/.composer:
	$(TARGET_MARKER_START)
	mkdir -p ~/.composer
	$(TARGET_MARKER_END)

vendor: \
	docker/sculpin/.built \
	~/.composer \
	composer.json \
	composer.lock
	$(TARGET_MARKER_START)
	docker-compose -f $(CI_FILE) run --rm sculpin composer install
	$(TARGET_MARKER_END)

.PHONY:
clean:
	$(TARGET_MARKER_START)
	rm -rfv source/css/*
	rm -rfv output_prod/*
	$(TARGET_MARKER_END)

source/css/pygments.css: docker/sculpin/.built
	$(TARGET_MARKER_START)
	docker-compose -f $(CI_FILE) run --rm sculpin sh \
		bin/generate-pygments-css
	$(TARGET_MARKER_END)

docker/sass/.built: \
	$(shell find docker/sass/* | grep .built)
	$(TARGET_MARKER_START)
	docker-compose -f $(CI_FILE) build sass
	touch $@
	$(TARGET_MARKER_END)

docker/sculpin/.built: docker/sculpin/*
	$(TARGET_MARKER_START)
	docker-compose -f $(CI_FILE) build sculpin
	touch $@
	$(TARGET_MARKER_END)

output_dev:
	$(TARGET_MARKER_START)
	mkdir -p $(TARGET)
	$(TARGET_MARKER_END)

# todo fix source/*
output_prod: \
	$(shell find source/) \
	source/css \
    docker/sculpin/.built \
    vendor
	$(TARGET_MARKER_START)
	docker-compose -f $(CI_FILE) run --rm sculpin vendor/bin/sculpin generate \
		--env=prod
	$(TARGET_MARKER_END)

source/css: \
	docker/sass/.built \
	source/css/pygments.css \
	$(shell find source/scss/ | grep .built)
	$(TARGET_MARKER_START)
	docker-compose -f $(CI_FILE) run --rm sass --update /app/source/scss:/app/source/css
	touch $@
	$(TARGET_MARKER_END)

docker/app/.built: \
	docker/app/* \
	output_prod
	$(TARGET_MARKER_START)
	docker-compose -f $(CI_FILE) build app
	touch $@
	$(TARGET_MARKER_END)

.PHONY: up
up: output_dev
	docker-compose up

.PHONY: down
down:
	docker-compose down

.PHONY: test
test: docker/app/.built
	$(TARGET_MARKER_START)
	docker-compose -f $(CI_FILE) up -d --no-build --force-recreate --remove-orphans
	tests/smoke-test.sh
	tests/validate-html.sh
	docker-compose -f $(CI_FILE) stop
	$(TARGET_MARKER_END)

DOCKER_TUNNEL_CONTAINER=docker_swarm_ssh_tunnel
DOCKER_TUNNEL_PORT=12374
DOCKER_SWARM_HOST=lucasvanlierop.nl
DEPLOY_USER=deploy
DOCKER_STACK_FILE=env/prod/docker-compose.yml
DOCKER_STACK_NAME=lucasvanlierop-website

.PHONY: deploy
.SILENT: deploy
deploy: \
	traefik-production-certificate-store \
	traefik-production-config \
	tunnel-to-production-docker-socket
	$(TARGET_MARKER_START)
	docker \
		-H localhost:$(DOCKER_TUNNEL_PORT) \
		stack deploy \
		--with-registry-auth \
		-c $(DOCKER_STACK_FILE) \
		--prune \
		$(DOCKER_STACK_NAME)
	$(TARGET_MARKER_END)

.PHONY: traefik-production-certificate-store
.SILENT: traefik-production-certificate-store
traefik-production-certificate-store:
	$(TARGET_MARKER_START)
	# Create file Where Traefik can store it's certificates
	ssh $(DEPLOY_USER)@$(DOCKER_SWARM_HOST) "(umask 600; touch /opt/traefik/acme.json)"
	$(TARGET_MARKER_END)

.PHONY: traefik-production-config
.SILENT: traefik-production-config
traefik-production-config:
	$(TARGET_MARKER_START)
	# Copy Traefik config file (Todo: this should be Swarm secret since this does not trigger a restart)
	scp env/prod/traefik.toml $(DEPLOY_USER)@$(DOCKER_SWARM_HOST):/opt/traefik/traefik.toml
	$(TARGET_MARKER_END)

.SILENT: tunnel-to-production-docker-socket
tunnel-to-production-docker-socket:
	$(TARGET_MARKER_START)
	# Create SSH tunnel to Docker Swarm cluster
	@(docker ps | grep $(DOCKER_TUNNEL_CONTAINER)) || docker run \
		-d \
		--name $(DOCKER_TUNNEL_CONTAINER) \
		-p $(DOCKER_TUNNEL_PORT):$(DOCKER_TUNNEL_PORT) \
		-v $(SSH_AUTH_SOCK):/ssh-agent \
		kingsquare/tunnel \
		*:$(DOCKER_TUNNEL_PORT):/var/run/docker.sock \
		$(DEPLOY_USER)@$(DOCKER_SWARM_HOST)

	# Wait until tunnel is available
	until docker -H localhost:$(DOCKER_TUNNEL_PORT) version 2>/dev/null 1>/dev/null > /dev/null; do \
		echo "Waiting for docker tunnel"; \
		sleep 1; \
	done
	$(TARGET_MARKER_END)
