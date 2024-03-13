#!/usr/bin/env bash

SENDER_PATH=$1
RECEIVER_PATH=$2

# Check if the number of input parameters is correct
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <SENDER_PATH> <RECEIVER_PATH>"
    exit 1
fi

export CARDANO_NODE_SOCKET_PATH=${ROOT_A}/node-spo1/node.sock
CARDANO_NET_PREFIX="--testnet-magic 142"
SOCKET_PATH=cluster/chain_A/node-spo1/node.sock
PROTOCOL_PARAMETERS=${ROOT_A}/protocol-parameters.json
MIN_UTXO_VALUE=1000000

SENDER=$(cat ${SENDER_PATH}.addr)
DSTADDRESS=$(cat ${RECEIVER_PATH}.addr)

UTXOS="$(cardano-cli query utxo --address ${SENDER} ${CARDANO_NET_PREFIX} --socket-path ${SOCKET_PATH})"

# Initialize tx parameters
tx_amount=0
tx_input_count=0
tx_inputs=""

while IFS= read -r line; do
    tx_hash=$(echo "$line" | awk '{print $1}')
    tx_ix=$(echo "$line" | awk '{print $2}')
    amount=$(echo "$line" | awk '{print $3}')
    
    if [ "$amount" -ge $MIN_UTXO_VALUE ]; then
    	tx_amount=$((tx_amount + amount))
    	tx_inputs+="--tx-in ${tx_hash}#${tx_ix} "
    	tx_input_count=$((tx_input_count + 1))
    fi
done <<< "$(echo "${UTXOS}" | awk 'NR > 2')"

TX_TIME=`date +%s`
TX_FILE=test-data/tx/tx_${TX_TIME}_$(basename "$SENDER_PATH")_$(basename "$RECEIVER_PATH")_${AMOUNT}
ROOT_A=cluster/chain_A

# Prepare tx input of sender
TRANS=$(cardano-cli query utxo ${CARDANO_NET_PREFIX} --address ${SENDER} | tail -n1)
UTXO=$(echo ${TRANS} | awk '{print $1}')
ID=$(echo ${TRANS} | awk '{print $2}')
AMOUNT_SENDER=$(echo ${TRANS} | awk '{print $3}')
TXIN1=${UTXO}#${ID}

AMOUNT_SENDER=$tx_amount
# Build raw transaction
cardano-cli transaction build-raw \
    ${tx_inputs} \
    --tx-out $SENDER+0 \
    --tx-out $DSTADDRESS+0 \
    --invalid-hereafter 0 \
    --fee 0 \
    --out-file ${TX_FILE}.draft

# Calculate fee
FEE=$(cardano-cli transaction calculate-min-fee \
    --tx-body-file ${TX_FILE}.draft \
    --tx-in-count ${tx_input_count} \
    --tx-out-count 2 \
    --witness-count 1 \
    --protocol-params-file $PROTOCOL_PARAMETERS \
    ${CARDANO_NET_PREFIX})
FEE_AMOUNT=$(echo ${FEE} | awk '{print $1}')

# Sender receive nothing
SENDER_AMOUNT_TO_RECEIVE=$MIN_UTXO_VALUE
RECEIVER_AMOUNT_TO_RECEIVE=$((tx_amount - FEE_AMOUNT - MIN_UTXO_VALUE))

# Calculate expiration slot
CURRENT_SLOT=$(cardano-cli query tip ${CARDANO_NET_PREFIX} | jq -r '.slot')
EXPIRE=$((CURRENT_SLOT+300))

# Build raw transaction again with correct amounts
cardano-cli transaction build-raw \
    ${tx_inputs} \
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
