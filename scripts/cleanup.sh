#!/bin/bash

DOCKER_COMPOSE="docker-compose"

if ! command -v docker-compose
then
        DOCKER_COMPOSE="docker compose"
        echo "Docker compose command set to new style $DOCKER_COMPOSE"
fi

$DOCKER_COMPOSE down
docker volume rm --force tak-server_db_data
rm -rf tak
rm -rf /tmp/takserver

# Comment me out to save yourself rebuilding........
docker image rm tak-server-db --force
docker image rm tak-server-tak --force
