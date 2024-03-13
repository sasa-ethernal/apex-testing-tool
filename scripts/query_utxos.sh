#!/usr/bin/env bash

VUS_ID="$1"
WALLET_ID="$2"

# Check if the number of arguments provided is greater than 2
if [ $# -gt 2 ]; then
    echo "Too many arguments provided."
    usage
fi

TEST_DIR=test-data
CARDANO_NET_PREFIX="--testnet-magic 142"
SOCKET_PATH=cluster/chain_A/node-spo1/node.sock

cd ${TEST_DIR}

process_vus_directory() {
    local DIR="vus-$1"
    cd ${DIR}
    echo ${DIR}
    
    if [ -z "$WALLET_ID" ]; then
	for WALLET in wallet-[0-9]*.addr; do
	    process_wallet_file "${WALLET#wallet-}"
	done
    else
    	process_wallet_file "$WALLET_ID"
    fi
    
    cd ..    
}

process_wallet_file() {
    local WALLET="wallet-$1"
    echo ${WALLET}
    echo "$(cardano-cli query utxo --address $(cat ${WALLET}) ${CARDANO_NET_PREFIX} --socket-path ../../${SOCKET_PATH})"
    echo --------------------------------------------------------------------------------------
}

if [ -z "$VUS_ID" ]; then
    for DIR in vus-*; do
        process_vus_directory "${DIR#vus-}"
    done
else
    process_vus_directory "$VUS_ID"
fi

cd ..



