#!/usr/bin/env bash

TEST_DIR=test-data
VUS_PREFIX=vus
WALLET_PREFIX=wallet
SCRIPTS_DIR=scripts

DESTINATION=$1

# Check if the number of input parameters is correct
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <DESTINATION>"
    exit 1
fi

process_vus_directory() {
    local DIR=$1
    cd ${DIR}
    
    for WALLET in ${WALLET_PREFIX}-[0-9]*.addr; do
        process_wallet_file "${TEST_DIR}/${DIR}/${WALLET%.addr}"
    done
    
    cd ..
}

process_wallet_file() {
    local WALLET=$1
    WALLETS+=("${WALLET}")
}

declare -a WALLETS

# Collecto all wallets from TEST_DIR
mkdir -p ${TEST_DIR} && cd ${TEST_DIR}
if [ -n "$(find . -maxdepth 1 -type d -name "${VUS_PREFIX}-*")" ]; then
    if [ -z "$VUS_ID" ]; then
        for DIR in ${VUS_PREFIX}-*; do
            process_vus_directory "${DIR}"
        done
    fi
fi
cd ..

# Call return_all_utxos script for each wallet
for WALLET in "${WALLETS[@]}"
do
    echo "${WALLET} -> ${DESTINATION}"
    ./"${SCRIPTS_DIR}"/return_all_utxos.sh "$WALLET" "$DESTINATION"
done
