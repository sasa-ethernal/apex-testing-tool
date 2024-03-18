#!/usr/bin/env bash

DOCKER_RELAY_CONTAINER=$(docker ps --format "{{.Names}}" --filter "name=apex-relay")
DOCKER_PREFIX="docker exec ${DOCKER_RELAY_CONTAINER}"

TEST_DIR=test-data
VUS_PREFIX=vus
WALLET_PREFIX=wallet

CARDANO_NET_PREFIX="--testnet-magic 1177"
NODE_SOCKET_PREFIX="--socket-path /ipc/node.socket"

VUS_ID="$1"
WALLET_ID="$2"

# Check if the number of arguments provided is greater than 2
if [ $# -gt 2 ]; then
    echo "Too many arguments provided."
    usage
fi

process_vus_directory() {
    local DIR=$1
    cd ${DIR}
    echo ${DIR}
    
    if ! [ -z "$WALLET_ID" ]; then
    	process_wallet_file "${WALLET_PREFIX}-${WALLET_ID}.addr"
    else
        for WALLET in ${WALLET_PREFIX}-[0-9]*.addr; do
            process_wallet_file "${WALLET}"
        done
    fi
    
    cd ..    
}

process_wallet_file() {
    local WALLET=$1
    echo "${WALLET} [$(cat ${WALLET})]"
    echo "$(${DOCKER_PREFIX} cardano-cli query utxo --address $(cat ${WALLET}) ${CARDANO_NET_PREFIX} ${NODE_SOCKET_PREFIX})"
    echo --------------------------------------------------------------------------------------
}

mkdir -p ${TEST_DIR} && cd ${TEST_DIR}

if ! [ -z "$VUS_ID" ]; then
    if [ -d "${VUS_PREFIX}-${VUS_ID}" ]; then
        process_vus_directory "${VUS_PREFIX}-${VUS_ID}"
    fi
else
    if [ -n "$(find . -maxdepth 1 -type d -name "${VUS_PREFIX}-*")" ]; then
        if [ -z "$VUS_ID" ]; then
            for DIR in ${VUS_PREFIX}-*; do
                process_vus_directory "${DIR}"
                echo ""
            done
        fi
    fi
fi

cd ..



