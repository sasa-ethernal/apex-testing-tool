#!/usr/bin/env bash

TRANS=$(cardano-cli query utxo --address $(cat cluster/chain_A/utxo-keys/utxo2.addr) --testnet-magic 142 --socket-path cluster/chain_A/node-spo1/node.sock | tail -n1)
AMOUNT=$(echo ${TRANS} | awk '{print $3}')

echo $AMOUNT