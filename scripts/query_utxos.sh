#!/usr/bin/env bash

TEST_DIR=test-data
VUS_PREFIX=vus
WALLET_PREFIX=wallet

CARDANO_NET_PREFIX="--testnet-magic 142"
SOCKET_PATH=cluster/chain_A/node-spo1/node.sock

VUS_ID="$1"
WALLET_ID="$2"

# Check if the number of arguments provided is greater than 2
if [ $# -gt 2 ]; then
    echo "Too many arguments provided."
    usage
fi

mkdir -p ${TEST_DIR} && cd ${TEST_DIR}

process_vus_directory() {
    local DIR="${VUS_PREFIX}-$1"
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
    echo "$(cardano-cli query utxo --address $(cat ${WALLET}) ${CARDANO_NET_PREFIX} --socket-path ../../${SOCKET_PATH})"
    echo --------------------------------------------------------------------------------------
}

if ! [ -z "$VUS_ID" ]; then
    if [ -d "${VUS_PREFIX}-${VUS_ID}" ]; then
        process_vus_directory "$VUS_ID"
    fi
else
    if [ -n "$(find . -maxdepth 1 -type d -name "${VUS_PREFIX}-*")" ]; then
        if [ -z "$VUS_ID" ]; then
            for DIR in ${VUS_PREFIX}-*; do
                process_vus_directory "${DIR#${VUS_PREFIX}-}"
                echo ""
            done
        fi
    fi
fi

cd ..



