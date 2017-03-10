#!/usr/bin/env bash

scp -r docker-compose.prod.yml deploy@lucasvanlierop.nl:/home/deploy
ssh deploy@lucasvanlierop.nl <<COMMANDS
    docker-compose -f docker-compose.prod.yml pull
    docker-compose -f docker-compose.prod.yml up -d --force-recreate --no-build --remove-orphans
COMMANDS
