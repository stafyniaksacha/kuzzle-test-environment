#!/bin/bash

#-------------------------------------------------------------------------------
#
#   Kuzzle end-to-end test sandbox
#
#   Script aim: install and start sandbox
#   - clean previous sandbox if any
#   - install and start proxy
#   - install and start kuzzle core
#   - install and start backoffice
#
#-------------------------------------------------------------------------------


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

. "$SCRIPT_DIR/utils/vars.sh"

START_INSTALL="$(date +%s)"
TIMEOUT_INSTALL=$START_INSTALL+60*10

trap kill_process INT

function kill_process() {
  # kill remaining process
  ps aux | grep /scripts/install-proxy.sh | awk '{print $2}' | xargs kill -9 > /dev/null
  ps aux | grep /scripts/install-kuzzle.sh | awk '{print $2}' | xargs kill -9 > /dev/null
  ps aux | grep /scripts/install-backoffice.sh | awk '{print $2}' | xargs kill -9 > /dev/null
  ps aux | grep /scripts/start-proxy.sh | awk '{print $2}' | xargs kill -9 > /dev/null
  ps aux | grep /scripts/start-kuzzle.sh | awk '{print $2}' | xargs kill -9 > /dev/null
  ps aux | grep /scripts/start-backoffice.sh | awk '{print $2}' | xargs kill -9 > /dev/null
  ps aux | grep gyp | awk '{print $2}' | xargs kill -9 > /dev/null
  ps aux | grep npm | awk '{print $2}' | xargs kill -9 > /dev/null

  exit 1
}

echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Starting kuzzle environment installation...${COLOR_END}"

if [ ! -d "${SANDBOX_DIR}" ]; then
  mkdir -p "${SANDBOX_DIR}"
fi

pushd "${SANDBOX_DIR}" > /dev/null
  export CC="gcc-${GCC_VERSION}" CXX="g++-${GCC_VERSION}"

  echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Install projects...${COLOR_END}"
  echo "INSTALL PROJECTS" > /tmp/sandbox-status

  PIDS=""
  RESULT=""

  bash -c "${SCRIPT_DIR}/parts/install-proxy.sh" &
  PIDS="$PIDS $!"

  bash -c "${SCRIPT_DIR}/parts/install-kuzzle.sh" &
  PIDS="$PIDS $!"

  bash -c "${SCRIPT_DIR}/parts/install-backoffice.sh" &
  PIDS="$PIDS $!"

  for PID in $PIDS; do
      wait $PID || let "RESULT=1"
  done

  if [ "$RESULT" == "1" ];
      then
         exit 1
  fi

  echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Start projects...${COLOR_END}"

  echo "START PROXY" > /tmp/sandbox-status
  bash -c "${SCRIPT_DIR}/parts/start-proxy.sh"
  sleep 10

  echo "START KUZZLE" > /tmp/sandbox-status
  bash -c "${SCRIPT_DIR}/parts/start-kuzzle.sh"

  echo "START BACKOFFICE" > /tmp/sandbox-status
  bash -c "${SCRIPT_DIR}/parts/start-backoffice.sh"
popd > /dev/null

echo -e

# wait for kuzzle to be available to exit
echo "WAIT KUZZLE AVAILABLE" > /tmp/sandbox-status
echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_YELLOW}Waiting for kuzzle to be available${COLOR_END}"
while [[ "$(date +%s)" -lt "${TIMEOUT_INSTALL}" ]] && ! curl -f -s -o /dev/null "${SANDBOX_ENDPOINT}"
do
    echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_YELLOW}Still trying to connect to kuzzle at ${SANDBOX_ENDPOINT}${COLOR_END}"
    sleep 10
done

if ! curl -f -s -o /dev/null "${SANDBOX_ENDPOINT}"; then
  echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Kuzzle installation timed out (> 10min)${COLOR_END}"

  kill_process

  exit 1
else
  echo -e "[$(date --rfc-3339 seconds)] - ${COLOR_BLUE}Kuzzle available at ${SANDBOX_ENDPOINT}${COLOR_END}"

  echo "KUZZLE STARTED" > /tmp/sandbox-status

  exit 0
fi
