#!/usr/bin/env bash

DOCKER_STACK_NAME=lucasvanlierop-website
DOCKER_COMPOSE_FILE_PROD=env/prod/docker-compose.yml

deploy_stack() {
    local stack_name=$1
    local stack_file=$2

    eval $(docker-machine env ${stack_name})

    docker stack deploy -c ${stack_file} ${stack_name}

    eval $(docker-machine env --unset)
}

deploy_stack ${DOCKER_STACK_NAME} ${DOCKER_COMPOSE_FILE_PROD}
