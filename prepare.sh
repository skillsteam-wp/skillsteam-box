#!/bin/bash

set -eou pipefail

Green='\033[0;32m'
Red='\033[0;31m'
Color_Off='\033[0m'
Cyan='\033[0;36m'

echo -e "${Cyan}Check if file .env exist.${Color_Off}"

if ! test -f .env; then
  cp -f .env_example .env
  echo -e "${Green}-> .env file created.${Color_Off}"
else
  echo -e "${Red}-> .env file exist. Skip this step...${Color_Off}"
fi



echo -e "${Cyan}All done.${Color_Off}"

