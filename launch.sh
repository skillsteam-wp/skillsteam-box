#!/bin/bash
set -eou pipefail

Green='\033[0;32m'
Red='\033[0;31m'
Color_Off='\033[0m'
Cyan='\033[0;36m'

function up() {
  if docker compose version
  then
    docker compose up -d
  elif docker-compose version
  then
    docker-compose up -d
  else
    echo -e "${Red}Please install docker compose plugin${Color_Off}"
  fi
}

function up-s3() {
  if docker compose version
  then
    docker compose --profile s3 up -d
  elif docker-compose version
  then
    docker-compose --profile s3 up -d
  else
    echo -e "${Red}Please install docker compose plugin${Color_Off}"
  fi
}

function down() {
  if docker compose version
  then
    docker compose down
  elif docker-compose version
  then
    docker-compose down
  else
    echo -e "${Red}Please install docker compose plugin${Color_Off}"
  fi
}

function down-s3() {
  if docker compose version
  then
    docker compose --profile s3 down
  elif docker-compose version
  then
    docker-compose --profile s3 down
  else
    echo -e "${Red}Please install docker compose plugin${Color_Off}"
  fi
}

"$@"