#!/bin/bash

echo -e "${Cyan}Start s3 server configuretion.${Color_Off}"

if ! test -f .docker/garage/garage.toml; then
  echo -e "${Green}-> Config file does not exist. Creating...${Color_Off}"

  export RPC_SECRET="$(openssl rand -hex 32)"
  export ADMIN_TOKEN="$(openssl rand -base64 32)"
  export METRICS_TOKEN="$(openssl rand -base64 32)"

  envsubst < .docker/garage/garage_template.toml > .docker/garage/garage.toml

  echo -e "${Green}-> Config file created.${Color_Off}"
else
  echo -e "${Red}-> Config file exist. Skip this step...${Color_Off}"
fi

echo -e "${Cyan}Start S3 server initialization.${Color_Off}"

echo -e "${Cyan}Start S3 server${Color_Off}"

docker compose --profile regular --profile s3 up --quiet-pull --wait -d s3 2>/dev/null

until docker compose exec s3 /garage status > /dev/null; do
    echo -e "-> Waiting S3 server to be operational"
    sleep 5
done

echo -e "${Green}-> S3 server started.${Color_Off}"

echo -e "${Cyan}Get S3 node ID${Color_Off}"
NODE_ID=$(docker compose exec s3 /garage status | awk '{if (($1!="====") && ($1!="ID")) print $1 }')

echo -e "${Green}-> Node ID is: ${NODE_ID}${Color_Off}"

echo -e "${Cyan}Assign layout for s3 node${Color_Off}"

read -r -p "$(echo -e "${Cyan}-> Do you want set S3 storage size? Default size 5G [Y/n]: ${Color_Off}")" RESPONSE
RESPONSE=${RESPONSE,,} # tolower
if [[ $RESPONSE =~ ^(y| ) ]] || [[ -z $RESPONSE ]]; then
  while true
  do
  read -r -p "$(echo -e "${Cyan}--> Enter size of storage (Examples 1G or 500M): ${Color_Off}")" STORAGE_SIZE
  if [[ $STORAGE_SIZE =~ [0-9]{1,}[G,M] ]]; then
    echo -e "${Green}-> Storage size set to $STORAGE_SIZE${Color_Off}"
    break
  else
    echo -e "${Red}--> Wrong format(Needs <number>G or <number>M)${Color_Off}"
  fi
  done
else
  STORAGE_SIZE="5G"
  echo -e "${Green}-> Storage size set to $STORAGE_SIZE${Color_Off}"
fi

if [ $(docker compose exec s3 /garage layout show | grep "No nodes currently have a role in the cluster." |wc -l) -eq 0 ]
then
   echo -e "${Red}-> Layout already exists. Skip this step...${Color_Off}"
else
   docker compose exec s3 /garage layout assign -z dc1 -c ${STORAGE_SIZE} ${NODE_ID} > /dev/null
   docker compose exec s3 /garage layout apply --version 1 > /dev/null
   echo -e "${Green}-> Layout for s3 node assigned.${Color_Off}"
#   docker compose exec s3 /garage layout show
fi

echo -e "${Cyan}Create S3 bucket${Color_Off}"
if [ $(docker compose exec s3 /garage bucket list| grep "skillsteam" |wc -l) -eq 0 ]
then
  docker compose exec s3 /garage bucket create skillsteam > /dev/null
  echo -e "${Green}-> Bucket created.${Color_Off}"
#  docker compose exec s3 /garage bucket list
else
  echo -e "${Red}-> Bucket already exists. Skip this step...${Color_Off}"
fi

echo -e "${Cyan}Create an S3 key${Color_Off}"
if [ $(docker compose exec s3 /garage key list| grep "skillsteam-app-key" |wc -l) -eq 0 ]
then
  docker compose exec s3 /garage key create skillsteam-app-key > /dev/null
  echo -e "${Green}-> S3 key created.${Color_Off}"
else
  echo -e "${Red}-> S3 key already exists. Skip this step...${Color_Off}"
fi

echo -e "${Cyan}Bind S3 key to bucket${Color_Off}"
if [ $(docker compose exec s3 /garage bucket info skillsteam| grep "skillsteam-app-key" |wc -l) -eq 0 ]
then
  docker compose exec s3 /garage bucket allow --read --write skillsteam --key skillsteam-app-key > /dev/null
  echo -e "${Green}-> S3 key binded to bucket.${Color_Off}"
#  docker compose exec s3 /garage bucket info skillsteam
else
  echo -e "${Red}-> S3 key already binded to bucket. Skip this step...${Color_Off}"
fi


S3_ACCESS_KEY=$(docker compose exec s3 /garage key info --show-secret skillsteam-app-key | awk '{ if (($1=="Key") && ($2=="ID:")) print $3 }')
S3_SECRET_KEY=$(docker compose exec s3 /garage key info --show-secret skillsteam-app-key | awk '{ if (($1=="Secret") && ($2=="key:")) print $3 }')
S3_REGION="garage"
S3_BUCKET_NAME="skillsteam"
S3_PUBLIC_URL="http://127.0.0.1:3902"
S3_ENDPOINT_URL="http://s3:3900"

read -r -p "$(echo -e "${Cyan}-> Define the public url for s3 bucket(Example: http://skillsteam.s3.example.com): ${Color_Off}")" RESPONSE
RESPONSE=${RESPONSE,,} # tolower
if [[ $RESPONSE =~ http* ]]; then
  S3_PUBLIC_URL=$RESPONSE
else
  echo -e "wrong format"
fi

read -r -p "$(echo -e "${Cyan}-> Do you want set S3 storage configuration to .env file? [y/N]: ${Color_Off}")" RESPONSE
RESPONSE=${RESPONSE,,} # tolower
if [[ $RESPONSE =~ ^(y| ) ]]; then
  sed -i "s|S3_ACCESS_KEY=.*|S3_ACCESS_KEY=$S3_ACCESS_KEY|g" .env
  sed -i "s|S3_SECRET_KEY=.*|S3_SECRET_KEY=$S3_SECRET_KEY|g" .env
  sed -i "s|S3_REGION=.*|S3_REGION=$S3_REGION|g" .env
  sed -i "s|S3_BUCKET_NAME=.*|S3_BUCKET_NAME=$S3_BUCKET_NAME|g" .env
  sed -i "s|S3_PUBLIC_URL=.*|S3_PUBLIC_URL=$S3_PUBLIC_URL|g" .env
  sed -i "s|S3_ENDPOINT_URL=.*|S3_ENDPOINT_URL=$S3_ENDPOINT_URL|g" .env
  echo -e "${Green}-> S3 storage configuration set to .env${Color_Off}"
else
  echo -e "Your S3 credentials:"
  echo -e "S3 access key: ${Green}${S3_ACCESS_KEY}${Color_Off}"
  echo -e "S3 secret key: ${Green}${S3_SECRET_KEY}${Color_Off}"
  echo -e "S3 region: ${Green}${S3_REGION}${Color_Off}"
  echo -e "S3 bucket name: ${Green}${S3_BUCKET_NAME}${Color_Off}"
  echo -e "S3 public endpoint URL: ${Green}${S3_PUBLIC_URL}${Color_Off}"
  echo -e "S3 endpoint URL: ${Green}${S3_ENDPOINT_URL}${Color_Off}"
fi

echo -e "${Cyan}Stop S3 server${Color_Off}"
docker compose --profile regular --profile s3 down s3 2>/dev/null