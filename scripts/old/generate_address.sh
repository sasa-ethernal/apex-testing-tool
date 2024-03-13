#!/usr/bin/env bash

FILE_NAME=$1

# Check if the number of input parameters is correct
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <FILE_NAME>"
    exit 1
fi

ROOT_A=cluster/chain_A
DIR=$ROOT_A
cd ${DIR}/

#export CARDANO_NODE_SOCKET_PATH=${DIR}/node-spo1/node.sock

# Generate address
cardano-cli address key-gen \
    --verification-key-file utxo-keys/${FILE_NAME}.vkey \
    --signing-key-file utxo-keys/${FILE_NAME}.skey

cardano-cli address build \
    --payment-verification-key-file utxo-keys/${FILE_NAME}.vkey \
    --out-file utxo-keys/${FILE_NAME}.addr \
    --testnet-magic 142

echo "$FILE_NAME"
cat utxo-keys/${FILE_NAME}.addr 
