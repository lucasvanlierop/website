#!/usr/bin/env bash

scp -r env/default env/prod  deploy@lucasvanlierop.nl:/home/deploy/env
ssh deploy@lucasvanlierop.nl <<COMMANDS
    docker-compose -f env/prod/docker-compose.yml pull
    docker-compose -f env/prod/docker-compose.yml up -d --force-recreate --no-build --remove-orphans
COMMANDS
