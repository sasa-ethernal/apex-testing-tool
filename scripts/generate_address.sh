#!/usr/bin/env bash

TEST_DIR=test-data
VUS_PREFIX=vus
WALLET_PREFIX=wallet

VUS_ID=$1
WALLET_ID=$2

# Check if the number of input parameters is correct
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <FILE_NAME> <WALLET_ID>"
    exit 1
fi

mkdir -p ${TEST_DIR} && cd ${TEST_DIR}
mkdir -p ${VUS_PREFIX}-${VUS_ID} && cd ${VUS_PREFIX}-${VUS_ID}

WALLET_NAME=${WALLET_PREFIX}-${WALLET_ID}

# Generate address
cardano-cli address key-gen \
    --verification-key-file ${WALLET_NAME}.vkey \
    --signing-key-file ${WALLET_NAME}.skey

cardano-cli address build \
    --payment-verification-key-file ${WALLET_NAME}.vkey \
    --out-file ${WALLET_NAME}.addr \
    --testnet-magic 142

