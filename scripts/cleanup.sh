#!/bin/bash

docker-compose down
docker volume rm --force tak-server_db_data
rm -rf tak
rm -rf /tmp/takserver
