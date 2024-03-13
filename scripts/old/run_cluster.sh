#!/usr/bin/env bash

ROOT_A=cluster/chain_A

SCRIPT_A=cardano-scripts/mkfiles_chain1.sh

# Remove Chain_A data
rm -rf cluster/

# Execute mkfiles_A mkfiles_B
bash ${SCRIPT_A}

# Run nodes
bash ${ROOT_A}/node-spo1.sh &
bash ${ROOT_A}/node-spo2.sh &
bash ${ROOT_A}/node-spo3.sh &

cd ${ROOT_A}/

sleep 15

PROTOCOL_PARAMETERS=protocol-parameters.json
export CARDANO_NODE_SOCKET_PATH=node-spo1/node.sock
CARDANO_NET_PREFIX="--testnet-magic 142"

cardano-cli query protocol-parameters --out-file ${PROTOCOL_PARAMETERS} ${CARDANO_NET_PREFIX}

# Generate .addr files for all addresses
for N in 1 2 3; do
    cardano-cli address build \
    --payment-verification-key-file utxo-keys/utxo${N}.vkey \
    --out-file utxo-keys/utxo${N}.addr \
    --testnet-magic 142
done

echo "CLUSTER READY"
