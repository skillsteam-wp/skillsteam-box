#!/bin/bash

set -eou pipefail

Green='\033[0;32m'
Red='\033[0;31m'
Color_Off='\033[0m'
Cyan='\033[0;36m'

function update() {
  echo "Текущая версия приложения: ${CURRENT_VERSION}"
  echo "Доступная версия приложения: ${AVAILABLE_VERSION}"
  echo "Обновитесь"
  read -r -p "$(echo -e "${Cyan}-> Хотите обновить версию приложения? ВНИМАНИЕ приложение будет перезапущено [Y/n]: ${Color_Off}")" RESPONSE
  RESPONSE=${RESPONSE,,} # tolower
  if [[ $RESPONSE =~ ^(y| ) ]] || [[ -z $RESPONSE ]]; then
    sed -i "s|VERSION=.*|VERSION=$AVAILABLE_VERSION|g" .env
    pull && down && up
    echo -e "${Green}-> Готово.${Color_Off}"
  fi
}

function pull() {
  if docker compose version
  then
    docker compose pull front
  elif docker-compose version
  then
    docker-compose pull front
  else
    echo -e "${Red}Please install docker compose plugin${Color_Off}"
  fi
}

function up() {
  if docker compose version
  then
    docker compose up -d front
  elif docker-compose version
  then
    docker-compose up -d front
  else
    echo -e "${Red}Please install docker compose plugin${Color_Off}"
  fi
}

function down() {
  if docker compose version
  then
    docker compose down front
  elif docker-compose version
  then
    docker-compose down front
  else
    echo -e "${Red}Please install docker compose plugin${Color_Off}"
  fi
}

CURRENT_VERSION=$(grep VERSION= .env | cut -f2 -d "=")
AVAILABLE_VERSION=$(curl -s https://storage.yandexcloud.net/skillsteam-version/index.html)

CUR_PREP_NUMBER=$(echo $CURRENT_VERSION | sed 's/[^0-9,\.]*//g')

CURRENT_MAJOR_VERSION=$(cut -d '.' -f 1 <<< "$CUR_PREP_NUMBER")
CURRENT_MINOR_VERSION=$(cut -d '.' -f 2 <<< "$CUR_PREP_NUMBER")
CURRENT_PATCH_VERSION=$(cut -d '.' -f 3 <<< "$CUR_PREP_NUMBER")

AVA_PREP_NUMBER=$(echo $AVAILABLE_VERSION | sed 's/[^0-9,\.]*//g')
AVAILABLE_MAJOR_VERSION=$(cut -d '.' -f 1 <<< "$AVA_PREP_NUMBER")
AVAILABLE_MINOR_VERSION=$(cut -d '.' -f 2 <<< "$AVA_PREP_NUMBER")
AVAILABLE_PATCH_VERSION=$(cut -d '.' -f 3 <<< "$AVA_PREP_NUMBER")

if [[ "$CURRENT_MAJOR_VERSION" < "$AVAILABLE_MAJOR_VERSION" ]]
then
  update
elif [[ "$CURRENT_MINOR_VERSION" < "$AVAILABLE_MINOR_VERSION" ]]
  then
    update
  elif [[ "$CURRENT_PATCH_VERSION" < "$AVAILABLE_PATCH_VERSION" ]]
  then
    update
else
  echo -e "Текущая версия приложения: ${Cyan}${CURRENT_VERSION}${Color_Off}"
  echo -e "Доступная версия приложения: ${Green}${AVAILABLE_VERSION}${Color_Off}"
  echo -e "${Green}У вас актуальная версия.${Color_Off}"
fi