#!/usr/bin/env bash

DOCKER_RELAY_CONTAINER=$(docker ps --format "{{.Names}}" --filter "name=apex-relay")
DOCKER_PREFIX="docker exec -it ${DOCKER_RELAY_CONTAINER}"

TEST_DIR=test-data
TX_DIR=tx
NODE_ROOT=cluster/chain_A

CARDANO_NET_PREFIX="--testnet-magic 1177"
PROTOCOL_PARAMETERS=/ipc/protocol-parameters.json
NODE_SOCKET_PREFIX="--socket-path /ipc/node.socket"

SENDER_PATH=$1
RECEIVER_PATH=$2

# Check if the number of input parameters is correct
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <SENDER_PATH> <RECEIVER_PATH>"
    exit 1
fi

SENDER_ADDRESS=$(cat ${SENDER_PATH}.addr)
DESTINATION_ADDRESS=$(cat ${RECEIVER_PATH}.addr)

mkdir -p ${TEST_DIR} && cd ${TEST_DIR} && mkdir -p ${TX_DIR} && cd ..
TX_TIME=`date +%s`
TX_FILE=${TEST_DIR}/${TX_DIR}/tx_${TX_TIME}_$(basename "$SENDER_PATH")_$(basename "$RECEIVER_PATH")_${AMOUNT}

# Initialize tx parameters
tx_amount=0
tx_input_count=0
tx_inputs=""

UTXOS="$(${DOCKER_PREFIX} cardano-cli query utxo --address ${SENDER_ADDRESS} ${CARDANO_NET_PREFIX} ${NODE_SOCKET_PREFIX})"

while IFS= read -r line; do
    tx_hash=$(echo "$line" | awk '{print $1}')
    tx_ix=$(echo "$line" | awk '{print $2}')
    amount=$(echo "$line" | awk '{print $3}')

    if [ $((amount)) -eq 0 ]; then    
        echo "No UTXOs"
        exit 0
    fi
    
    tx_amount=$((tx_amount + amount))
    tx_input_count=$((tx_input_count + 1))
    tx_inputs+="--tx-in ${tx_hash}#${tx_ix} "
done <<< "$(echo "${UTXOS}" | awk 'NR > 2')"

# Build raw transaction
${DOCKER_PREFIX} cardano-cli transaction build-raw \
    ${tx_inputs} \
    --tx-out $DESTINATION_ADDRESS+0 \
    --invalid-hereafter 0 \
    --fee 0 \
    --out-file ${TX_FILE}.draft

# Calculate fee
FEE=$(${DOCKER_PREFIX} cardano-cli transaction calculate-min-fee \
    --tx-body-file ${TX_FILE}.draft \
    --tx-in-count ${tx_input_count} \
    --tx-out-count 1 \
    --witness-count 1 \
    --protocol-params-file $PROTOCOL_PARAMETERS \
    ${CARDANO_NET_PREFIX})
FEE_AMOUNT=$(echo ${FEE} | awk '{print $1}')

# Sender receive nothing
RECEIVER_AMOUNT_TO_RECEIVE=$((tx_amount - FEE_AMOUNT))

# Calculate expiration slot
CURRENT_SLOT=$(${DOCKER_PREFIX} cardano-cli query tip ${CARDANO_NET_PREFIX} ${NODE_SOCKET_PREFIX} | jq -r '.slot')
EXPIRE=$((CURRENT_SLOT+300))

# Build raw transaction again with correct amounts
${DOCKER_PREFIX} cardano-cli transaction build-raw \
    ${tx_inputs} \
    --tx-out $DESTINATION_ADDRESS+$RECEIVER_AMOUNT_TO_RECEIVE \
    --invalid-hereafter $EXPIRE \
    --fee $FEE_AMOUNT \
    --out-file ${TX_FILE}.draft

${DOCKER_PREFIX} cardano-cli transaction sign \
    --signing-key-file ${SENDER_PATH}.skey \
    --tx-body-file ${TX_FILE}.draft \
    --out-file ${TX_FILE}.signed \
    ${CARDANO_NET_PREFIX}

echo "$(${DOCKER_PREFIX} cardano-cli transaction submit \
    ${NODE_SOCKET_PREFIX} \
    --tx-file ${TX_FILE}.signed \
    ${CARDANO_NET_PREFIX})"
