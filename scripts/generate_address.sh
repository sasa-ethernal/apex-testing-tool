#!/usr/bin/env bash

VUS_ID=$1
WALLET_ID=$2

# Check if the number of input parameters is correct
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <FILE_NAME> <WALLET_ID>"
    exit 1
fi

mkdir -p test-data
cd test-data
mkdir -p vus-${VUS_ID}
cd vus-${VUS_ID}

WALLET_NAME=wallet-${WALLET_ID}

# Generate address
cardano-cli address key-gen \
    --verification-key-file ${WALLET_NAME}.vkey \
    --signing-key-file ${WALLET_NAME}.skey

cardano-cli address build \
    --payment-verification-key-file ${WALLET_NAME}.vkey \
    --out-file ${WALLET_NAME}.addr \
    --testnet-magic 142

