#!/usr/bin/env bash

SENDER_PATH=$1
RECEIVER_PATH=$2
AMOUNT=$3

# Check if the number of input parameters is correct
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <SENDER_PATH> <RECEIVER_PATH> <AMOUNT>"
    exit 1
fi

TX_TIME=`date +%s`
TX_FILE=test-data/tx/tx_${TX_TIME}_$(basename "$SENDER_PATH")_$(basename "$RECEIVER_PATH")_${AMOUNT}
ROOT_A=cluster/chain_A

export CARDANO_NODE_SOCKET_PATH=${ROOT_A}/node-spo1/node.sock
CARDANO_NET_PREFIX="--testnet-magic 142"
PROTOCOL_PARAMETERS=${ROOT_A}/protocol-parameters.json

SENDER=$(cat ${SENDER_PATH}.addr)
DSTADDRESS=$(cat ${RECEIVER_PATH}.addr)
#SENDER=$(cat test-data/vus-${SENDER_VUS_ID}/wallet_${SENDER_WALLET_ID}.addr)
#DSTADDRESS=$(cat test-data/vus-${RECEIVER_VUS_ID}/wallet_${RECEIVER_WALLET_ID}.addr)

# Prepare tx input of sender
TRANS=$(cardano-cli query utxo ${CARDANO_NET_PREFIX} --address ${SENDER} | tail -n1)
UTXO=$(echo ${TRANS} | awk '{print $1}')
ID=$(echo ${TRANS} | awk '{print $2}')
AMOUNT_SENDER=$(echo ${TRANS} | awk '{print $3}')
TXIN1=${UTXO}#${ID}

# Build raw transaction
cardano-cli transaction build-raw \
    --tx-in $TXIN1 \
    --tx-out $SENDER+0 \
    --tx-out $DSTADDRESS+0 \
    --invalid-hereafter 0 \
    --fee 0 \
    --out-file ${TX_FILE}.draft

# Calculate fee
FEE=$(cardano-cli transaction calculate-min-fee \
    --tx-body-file ${TX_FILE}.draft \
    --tx-in-count 1 \
    --tx-out-count 2 \
    --witness-count 1 \
    --protocol-params-file $PROTOCOL_PARAMETERS \
    ${CARDANO_NET_PREFIX})
FEE_AMOUNT=$(echo ${FEE} | awk '{print $1}')

# Sender receive his change
SENDER_AMOUNT_TO_RECEIVE=$((AMOUNT_SENDER - AMOUNT - FEE_AMOUNT))
RECEIVER_AMOUNT_TO_RECEIVE=${AMOUNT}

# Calculate expiration slot
CURRENT_SLOT=$(cardano-cli query tip ${CARDANO_NET_PREFIX} | jq -r '.slot')
EXPIRE=$((CURRENT_SLOT+300))

# Build raw transaction again with correct amounts
cardano-cli transaction build-raw \
    --tx-in $TXIN1 \
    --tx-out $SENDER+$SENDER_AMOUNT_TO_RECEIVE \
    --tx-out $DSTADDRESS+$RECEIVER_AMOUNT_TO_RECEIVE \
    --invalid-hereafter $EXPIRE \
    --fee $FEE_AMOUNT \
    --out-file ${TX_FILE}.draft

cardano-cli transaction sign \
    --signing-key-file ${SENDER_PATH}.skey \
    --tx-body-file ${TX_FILE}.draft \
    --out-file ${TX_FILE}.signed \
    ${CARDANO_NET_PREFIX}

echo "$(cardano-cli transaction submit \
    --tx-file ${TX_FILE}.signed \
    ${CARDANO_NET_PREFIX})"
