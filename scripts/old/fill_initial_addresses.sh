#!/usr/bin/env bash

ROOT_A=cluster/chain_A
DIR=$ROOT_A
cd ${DIR}/

export CARDANO_NODE_SOCKET_PATH=node-spo1/node.sock
CARDANO_NET_PREFIX="--testnet-magic 142"
PROTOCOL_PARAMETERS=protocol-parameters.json
SENDER=$(cat utxo-keys/utxo2.addr)

ADDRESSES=()

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <NUM_OF_ADDRESSES>"
    exit 1
fi

# Initialize the loop variable
i=1
NUM_OF_ADDRESSES=$1

# Loop over the range from START to END (inclusive)
while [ "$i" -le "$NUM_OF_ADDRESSES" ]; do
    ADDRESS=$(cat utxo-keys/iter0vu${i}.addr)
    ADDRESSES+=("$ADDRESS")
    i=$((i+1))  # Increment the loop variable
done

# Prepare tx input of sender
TRANS=$(cardano-cli query utxo ${CARDANO_NET_PREFIX} --address ${SENDER} | tail -n1)
UTXO=$(echo ${TRANS} | awk '{print $1}')
ID=$(echo ${TRANS} | awk '{print $2}')
AMOUNT_SENDER=$(echo ${TRANS} | awk '{print $3}')
TXIN1=${UTXO}#${ID}

#change
#--tx-out $SENDER+0 \

# Build raw transaction
cardano-cli transaction build-raw \
    --tx-in $TXIN1 \
    $(for ((i=0; i<NUM_OF_ADDRESSES; i++)); do echo "--tx-out ${ADDRESSES[$i]}+0"; done) \
    --invalid-hereafter 0 \
    --fee 0 \
    --out-file tx.draft
#change
# --tx-out-count $((NUM_OF_ADDRESSES+1)) \
# Calculate fee
FEE=$(cardano-cli transaction calculate-min-fee \
    --tx-body-file tx.draft \
    --tx-in-count 1 \
    --tx-out-count $((NUM_OF_ADDRESSES)) \
    --witness-count 1 \
    --protocol-params-file $PROTOCOL_PARAMETERS \
    ${CARDANO_NET_PREFIX})
FEE_AMOUNT=$(echo ${FEE} | awk '{print $1}')

# Receiver receive amount sent from script
#RECEIVER_AMOUNT_TO_RECEIVE=100000000
RECEIVER_AMOUNT_TO_RECEIVE=$(((AMOUNT_SENDER-FEE_AMOUNT)/NUM_OF_ADDRESSES))

FEE_AMOUNT=$((FEE_AMOUNT+(AMOUNT_SENDER-RECEIVER_AMOUNT_TO_RECEIVE*NUM_OF_ADDRESSES-FEE_AMOUNT)))

# Calculate expiration slot
CURRENT_SLOT=$(cardano-cli query tip ${CARDANO_NET_PREFIX} | jq -r '.slot')
EXPIRE=$((CURRENT_SLOT+300))

# Build raw transaction again with correct amounts
cardano-cli transaction build-raw \
    --tx-in $TXIN1 \
    $(for ((i=0; i<NUM_OF_ADDRESSES; i++)); do echo "--tx-out ${ADDRESSES[$i]}+${RECEIVER_AMOUNT_TO_RECEIVE}"; done) \
    --invalid-hereafter $EXPIRE \
    --fee $FEE_AMOUNT \
    --out-file tx.draft

cardano-cli transaction sign \
    --signing-key-file utxo-keys/utxo2.skey \
    --tx-body-file tx.draft \
    --out-file tx.signed \
    ${CARDANO_NET_PREFIX}

echo "$(cardano-cli transaction submit \
    --tx-file tx.signed \
    ${CARDANO_NET_PREFIX})"