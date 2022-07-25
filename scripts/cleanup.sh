#!/bin/bash

docker-compose down
docker system prune --volumes
rm -rf tak