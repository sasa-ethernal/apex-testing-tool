#!/usr/bin/env bash

DOCKER_RELAY_CONTAINER=$(docker ps --format "{{.Names}}" --filter "name=apex-relay")
DOCKER_PREFIX="docker exec -it ${DOCKER_RELAY_CONTAINER}"

TEST_DIR=test-data
TX_DIR=tx
POTENTIAL_FEE=200000

CARDANO_NET_PREFIX="--testnet-magic 1177"
PROTOCOL_PARAMETERS=/ipc/protocol-parameters.json
NODE_SOCKET_PREFIX="--socket-path /ipc/node.socket"

SENDER_PATH=$1
AMOUNT=$2

tx_output_count=0
tx_outputs=""
tx_outputs_zero=""

# Check if there are at least two parameters
if [ $# -lt 3 ]; then
    echo "Usage: $0 <SENDER_PATH> <AMOUNT> [DESTINATION_PATH...]"
    exit 1
fi

shift 2 # shift to skip the first two parameters
while [ $# -gt 0 ]; do
    DESTINATION_ADDRESS=$(cat "${1}.addr")
    tx_outputs+="--tx-out ${DESTINATION_ADDRESS}+${AMOUNT} "
    tx_outputs_zero+="--tx-out ${DESTINATION_ADDRESS}+0 "
    tx_output_count=$((tx_output_count + 1))
    shift
done

# TODO - Split into multiple txs
if [ ${tx_output_count} -gt 400 ]; then
   echo "NOT SUPPORTED"
   exit 1
fi

TOTAL_AMOUNT=$((tx_output_count * AMOUNT))
SENDER_ADDRESS=$(cat ${SENDER_PATH}.addr)

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
    
    tx_amount=$((tx_amount + amount))
    tx_input_count=$((tx_input_count + 1))
    tx_inputs+="--tx-in ${tx_hash}#${tx_ix} "

    # Get enough UTXOs to cover Amount + Potential fee
    if [ $((tx_amount - POTENTIAL_FEE - TOTAL_AMOUNT)) -gt 0 ]; then    
        break
    fi
done <<< "$(echo "${UTXOS}" | awk 'NR > 2')"

if [ $((tx_amount - POTENTIAL_FEE - TOTAL_AMOUNT)) -lt 0 ]; then    
    echo "Not enough funds"
    exit -1
fi

# Build raw transaction
${DOCKER_PREFIX} cardano-cli transaction build-raw \
    ${tx_inputs} \
    ${tx_outputs_zero} \
    --tx-out $SENDER_ADDRESS+0 \
    --invalid-hereafter 0 \
    --fee 0 \
    --out-file ${TX_FILE}.draft

# Calculate fee
FEE=$(${DOCKER_PREFIX} cardano-cli transaction calculate-min-fee \
    --tx-body-file ${TX_FILE}.draft \
    --tx-in-count ${tx_input_count} \
    --tx-out-count $((tx_output_count + 1)) \
    --witness-count 1 \
    --protocol-params-file $PROTOCOL_PARAMETERS \
    ${CARDANO_NET_PREFIX})
FEE_AMOUNT=$(echo ${FEE} | awk '{print $1}')

# Sender receive nothing
SENDER_AMOUNT_TO_RECEIVE=$((tx_amount - TOTAL_AMOUNT - FEE_AMOUNT))

# Calculate expiration slot
CURRENT_SLOT=$(${DOCKER_PREFIX} cardano-cli query tip ${CARDANO_NET_PREFIX} ${NODE_SOCKET_PREFIX} | jq -r '.slot')
EXPIRE=$((CURRENT_SLOT+300))

# Build raw transaction again with correct amounts
${DOCKER_PREFIX} cardano-cli transaction build-raw \
    ${tx_inputs} \
    ${tx_outputs} \
    --tx-out $SENDER_ADDRESS+$SENDER_AMOUNT_TO_RECEIVE \
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
