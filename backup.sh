#!/bin/bash

Green='\033[0;32m'
Red='\033[0;31m'
Color_Off='\033[0m'
Cyan='\033[0;36m'

if command -v docker-compose > /dev/null 2>&1; then
    DOCKER_COMPOSE="docker-compose"
elif docker compose version > /dev/null 2>&1; then
    DOCKER_COMPOSE="docker compose"
else
    echo -e "${Red}Please install docker compose plugin${Color_Off}"
    exit 1
fi

function backup() {
    $DOCKER_COMPOSE exec postgres bash -c 'pg_dump -Fc -U$POSTGRES_USER $POSTGRES_DB > /skillsteam.backup'
    container_name=$($DOCKER_COMPOSE ps | grep postgres | awk '{print $1}')
    docker cp $container_name:/skillsteam.backup ./skillsteam.backup
}

function restore() {
    if [ -f "skillsteam.backup" ]; then
        container_name=$($DOCKER_COMPOSE ps | grep postgres | awk '{print $1}')
        docker cp ./skillsteam.backup $container_name:/skillsteam.backup
        $DOCKER_COMPOSE exec postgres bash -c 'pg_restore -U$POSTGRES_USER -d $POSTGRES_DB -x /skillsteam.backup'
    else
        echo "Файл для восстановления базы данных (skillsteam.backup) не найден."
        exit 2
    fi
}

case "$1" in
    backup)
        backup
        ;;
    restore)
        restore
        ;;
esac