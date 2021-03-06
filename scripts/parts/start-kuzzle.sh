#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"

. "$SCRIPT_DIR/utils/vars.sh"

vars=($KUZZLE_EXTRA_ENV);
opt=" "
for ((i=0; i<${#vars[@]}; ++i));
do
  # format env vars to docker run options format
  opt="-e ${vars[i]} ${opt}"
done

if [[ -e /etc/kuzzlerc ]]; then
  opt="--volume /etc/kuzzlerc:/etc/kuzzlerc ${opt}"
fi

set +e
while [[ $(docker inspect "proxy" -f "{{ .State.Status }}") != "running" ]];
do
  echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_YELLOW}Still waiting for proxy to be available before starting kuzzle${COLOR_END}"
  sleep 2
done
set -e

for i in $(seq 1 ${KUZZLE_NODES:-1});
do
    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Starting ${i}/${KUZZLE_NODES:-1} kuzzle ...${COLOR_END}"

    docker inspect "kuzzle_${i}" &>/dev/null && sh -c "docker kill kuzzle_${i} || true" && sh -c "docker rm -vf kuzzle_${i} || true"

    docker run --network="bridge" \
               --detach \
               --name "kuzzle_${i}" \
               --link "proxy:proxy" \
               --link "elasticsearch:elasticsearch" \
               --link "redis:redis" \
               --volume "${SANDBOX_DIR}/kuzzle:${SANDBOX_DIR}/app" \
               -e "DEBUG=$DEBUG" \
               -e "DEBUG_EXPAND=$DEBUG_EXPAND" \
               -e "DEBUG_DEPTH=$DEBUG_DEPTH" \
               -e "DEBUG_MAX_ARRAY_LENGTH=$DEBUG_MAX_ARRAY_LENGTH" \
               -e "DEBUG_SHOW_HIDDEN=$DEBUG_SHOW_HIDDEN" \
               -e "DEBUG_COLORS=$DEBUG_COLORS" \
               -e "NODE_ENV=$NODE_ENV" \
               ${opt} \
               tests/kuzzle-base \
                 bash -c 'pm2 start --silent ./docker-compose/config/pm2.json && tail -f /dev/null'
done

echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Kuzzle '${KUZZLE_VERSION}' started ...${COLOR_END}"
