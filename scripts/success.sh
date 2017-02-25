#!/bin/bash

COLOR_END="\e[39m"
COLOR_BLUE="\e[34m"
COLOR_YELLOW="\e[33m"

echo -e "${COLOR_BLUE}Tests passed successfully$COLOR_END"

echo -e "-> ${COLOR_BLUE}kuzzle version:$COLOR_END"
echo "${KUZZLE_REPO}#${KUZZLE_VERSION}"

if [[ "$KUZZLE_COMMON_OBJECT_VERSION" == "" ]]; then
  echo -e "--> ${COLOR_BLUE}overrided kuzzle common object:$COLOR_END"
  echo "${KUZZLE_COMMON_OBJECT_VERSION}"
fi

echo -e "-> ${COLOR_BLUE}proxy version:$COLOR_END"
echo "${PROXY_REPO}#${PROXY_VERSION}"

if [[ "$PROXY_COMMON_OBJECT_VERSION" == "" ]]; then
  echo -e "--> ${COLOR_BLUE}overrided proxy common object:$COLOR_END"
  echo "${PROXY_COMMON_OBJECT_VERSION}"
fi

echo -e "-> ${COLOR_BLUE}node version:$COLOR_END"
node --version

echo -e "-> ${COLOR_BLUE}npm version:$COLOR_END"
npm --version

echo -e "-> ${COLOR_BLUE}pm2 version:$COLOR_END"
pm2 --version

echo -e "-> ${COLOR_BLUE}python version:$COLOR_END"
python --version

echo -e "-> ${COLOR_BLUE}gcc version:$COLOR_END"
gcc --version

echo -e "-> ${COLOR_BLUE}elasticsearch version:$COLOR_END"
curl -XGET http://localhost:9200

echo -e "-> ${COLOR_BLUE}kuzzle info:$COLOR_END"
curl -XGET http://localhost:7512?pretty
