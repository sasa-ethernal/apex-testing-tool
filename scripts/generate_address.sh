#!/usr/bin/env bash

DOCKER_RELAY_CONTAINER=$(docker ps --format "{{.Names}}" --filter "name=apex-relay")
DOCKER_PREFIX="docker exec -it ${DOCKER_RELAY_CONTAINER}"

TEST_DIR=test-data
VUS_PREFIX=vus
WALLET_PREFIX=wallet

CARDANO_NET_PREFIX="--testnet-magic 1177"

VUS_ID=$1
WALLET_ID=$2

# Check if the number of input parameters is correct
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <FILE_NAME> <WALLET_ID>"
    exit 1
fi

VUS_DIR=${VUS_PREFIX}-${VUS_ID}
WALLET_NAME=${WALLET_PREFIX}-${WALLET_ID}

mkdir -p ${TEST_DIR} && cd ${TEST_DIR} && mkdir -p ${VUS_DIR}

# Generate address
${DOCKER_PREFIX} cardano-cli address key-gen \
    --verification-key-file ${TEST_DIR}/${VUS_DIR}/${WALLET_NAME}.vkey \
    --signing-key-file ${TEST_DIR}/${VUS_DIR}/${WALLET_NAME}.skey

${DOCKER_PREFIX} cardano-cli address build \
    --payment-verification-key-file ${TEST_DIR}/${VUS_DIR}/${WALLET_NAME}.vkey \
    --out-file ${TEST_DIR}/${VUS_DIR}/${WALLET_NAME}.addr \
    ${CARDANO_NET_PREFIX}

