#!/usr/bin/env bash

scp -r docker-compose.yml deploy@lucasvanlierop.nl:/home/deploy
ssh deploy@lucasvanlierop.nl <<COMMANDS
    docker-compose pull
    docker-compose up -d --force-recreate --no-build --remove-orphans
COMMANDS
