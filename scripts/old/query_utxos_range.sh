#!/usr/bin/env bash

# Check if the number of input parameters is correct
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <ITER_NUM> <VU_NUM>"
    exit 1
fi

ITER_NUM=$1
VU_NUM=$2


# Initialize the loop variable
iter=0

# Loop over the range from START to END (inclusive)
while [ "$iter" -le "$ITER_NUM" ]; do
    vu=1
    while [ "$vu" -le "$VU_NUM" ]; do
        echo "iter${iter}vu${vu}"
        echo "$(cardano-cli query utxo --address $(cat cluster/chain_A/utxo-keys/iter${iter}vu${vu}.addr) --testnet-magic 142 --socket-path cluster/chain_A/node-spo1/node.sock)"
        echo "\n"
        vu=$((vu+1))  # Increment the loop variable
    done
    iter=$((iter+1))
done
