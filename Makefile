TARGET=$@
SHELL=/bin/bash
.DELETE_ON_ERROR:

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
	docker-compose -f $(CI_FILE) run --rm sculpin composer install

.PHONY:
clean:
	rm -rfv source/css/*
	rm -rfv output_prod/*

source/css/pygments.css: docker/sculpin/.built
	docker-compose -f $(CI_FILE) run --rm sculpin sh \
		bin/generate-pygments-css

docker/sass/.built: \
	$(shell find docker/sass/* | grep .built)
	docker-compose -f $(CI_FILE) build sass
	touch $@

docker/sculpin/.built: docker/sculpin/*
	docker-compose -f $(CI_FILE) build sculpin
	touch $@

output_dev:
	mkdir -p $(TARGET)

# todo fix source/*
output_prod: \
	$(shell find source/) \
	source/css \
    docker/sculpin/.built \
    vendor
	docker-compose -f $(CI_FILE) run --rm sculpin vendor/bin/sculpin generate \
		--env=prod

source/css: \
	docker/sass/.built \
	source/css/pygments.css \
	$(shell find source/scss/ | grep .built)
	docker-compose -f $(CI_FILE) run --rm sass --update /app/source/scss:/app/source/css
	touch $@

docker/app/.built: \
	docker/app/* \
	output_prod
	docker-compose -f $(CI_FILE) build app
	touch $@

.PHONY: up
up: output_dev
	docker-compose up

.PHONY: down
down:
	docker-compose down

.PHONY: test
test: docker/app/.built
	docker-compose -f $(CI_FILE) up -d --no-build --force-recreate --remove-orphans
	tests/smoke-test.sh
	tests/validate-html.sh
	docker-compose -f $(CI_FILE) stop

DOCKER_TUNNEL_CONTAINER=docker_swarm_ssh_tunnel
DOCKER_TUNNEL_PORT=12374
DOCKER_SWARM_HOST=lucasvanlierop.nl
DOCKER_TUNNEL_USER=deploy
DOCKER_STACK_FILE=env/prod/docker-compose.yml
DOCKER_STACK_NAME=lucasvanlierop-website
.PHONY: deploy
.SILENT: deploy
deploy:
	# Create SSH tunnel to Docker Swarm cluster
	docker run \
		-d \
		--name $(DOCKER_TUNNEL_CONTAINER) \
		-p $(DOCKER_TUNNEL_PORT):$(DOCKER_TUNNEL_PORT) \
		-v $(SSH_AUTH_SOCK):/ssh-agent \
		kingsquare/tunnel \
		*:$(DOCKER_TUNNEL_PORT):/var/run/docker.sock \
		$(DOCKER_TUNNEL_USER)@$(DOCKER_SWARM_HOST)

	# Wait until tunnel is available
	until docker -H localhost:$(DOCKER_TUNNEL_PORT) version 2>/dev/null 1>/dev/null > /dev/null; do \
		echo "Waiting for docker tunnel"; \
		sleep 1; \
	done

	# Deploy
	docker \
		-H localhost:$(DOCKER_TUNNEL_PORT) \
		stack deploy \
		--with-registry-auth \
		-c $(DOCKER_STACK_FILE) \
		--prune \
		$(DOCKER_STACK_NAME)

	# Close tunnel
	docker stop $(DOCKER_TUNNEL_CONTAINER)
	docker rm $(DOCKER_TUNNEL_CONTAINER)
