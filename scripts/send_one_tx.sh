#!/usr/bin/env bash

TEST_DIR=test-data
TX_DIR=tx
NODE_ROOT=cluster/chain_A
POTENTIAL_FEE=200000

CARDANO_NET_PREFIX="--testnet-magic 142"
PROTOCOL_PARAMETERS=${NODE_ROOT}/protocol-parameters.json
export CARDANO_NODE_SOCKET_PATH=${NODE_ROOT}/node-spo1/node.sock

SENDER_PATH=$1
RECEIVER_PATH=$2
AMOUNT=$3

# Check if the number of input parameters is correct
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <SENDER_PATH> <RECEIVER_PATH> <AMOUNT>"
    exit 1
fi

SENDER_ADDRESS=$(cat ${SENDER_PATH}.addr)
DESTINATION_ADDRESS=$(cat ${RECEIVER_PATH}.addr)

mkdir -p ${TEST_DIR} && cd ${TEST_DIR} && mkdir -p ${TX_DIR} && cd ..
TX_TIME=`date +%s`
TX_FILE=test-data/tx/tx_${TX_TIME}_$(basename "$SENDER_PATH")_$(basename "$RECEIVER_PATH")_${AMOUNT}

# Initialize tx parameters
tx_amount=0
tx_input_count=0
tx_inputs=""

UTXOS="$(cardano-cli query utxo --address ${SENDER_ADDRESS} ${CARDANO_NET_PREFIX})"

while IFS= read -r line; do
    tx_hash=$(echo "$line" | awk '{print $1}')
    tx_ix=$(echo "$line" | awk '{print $2}')
    amount=$(echo "$line" | awk '{print $3}')
    
    tx_amount=$((tx_amount + amount))
    tx_input_count=$((tx_input_count + 1))
    tx_inputs+="--tx-in ${tx_hash}#${tx_ix} "

    # Get enough UTXOs to cover Amount + Potential fee
    if [ $((tx_amount - POTENTIAL_FEE - AMOUNT)) -gt 0 ]; then    
        break
    fi
done <<< "$(echo "${UTXOS}" | awk 'NR > 2')"

if [ $((tx_amount - POTENTIAL_FEE - AMOUNT)) -lt 0 ]; then    
    echo "Not enough funds"
    exit -1
fi

# Build raw transaction
cardano-cli transaction build-raw \
    ${tx_inputs} \
    --tx-out $SENDER_ADDRESS+0 \
    --tx-out $DESTINATION_ADDRESS+0 \
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

# Sender receive his change
SENDER_AMOUNT_TO_RECEIVE=$((tx_amount - AMOUNT - FEE_AMOUNT))
RECEIVER_AMOUNT_TO_RECEIVE=${AMOUNT}

# Calculate expiration slot
CURRENT_SLOT=$(cardano-cli query tip ${CARDANO_NET_PREFIX} | jq -r '.slot')
EXPIRE=$((CURRENT_SLOT+300))

# Build raw transaction again with correct amounts
cardano-cli transaction build-raw \
    ${tx_inputs} \
    --tx-out $SENDER_ADDRESS+$SENDER_AMOUNT_TO_RECEIVE \
    --tx-out $DESTINATION_ADDRESS+$RECEIVER_AMOUNT_TO_RECEIVE \
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
