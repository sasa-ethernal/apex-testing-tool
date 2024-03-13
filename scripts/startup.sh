#!/usr/bin/env bash

TEST_DIR=test-data
VUS_PREFIX=vus
WALLET_PREFIX=wallet
SCRIPTS_DIR=scripts

VUS_COUNT=$1
WALLET_COUNT=$2
SENDER=$3
INITIAL_AMOUNT=$4

# Check if the number of input parameters is correct
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <VUS_COUNT> <WALLET_COUNT> <SENDER> <INITIAL_AMOUNT>"
    exit 1
fi

# Generate VUS_COUNT x WALLET_COUNT addresses
ADDRESS_LIST=""

for ((VUS_ID=0; VUS_ID<$VUS_COUNT; VUS_ID++))
do
    for ((WALLET_ID=0; WALLET_ID<$WALLET_COUNT; WALLET_ID++))
    do
        ./"${SCRIPTS_DIR}"/generate_address.sh "$VUS_ID" "$WALLET_ID"
        ADDRESS_LIST+="${TEST_DIR}/${VUS_PREFIX}-${VUS_ID}/${WALLET_PREFIX}-${WALLET_ID} "
    done
done

# Remove space character from the end that was added in for loop
ADDRESS_LIST="${ADDRESS_LIST%?}"

# Distribute tokens among all created addresses
SCRIPT="${SCRIPTS_DIR}/distribute_utxos.sh ${SENDER} ${INITIAL_AMOUNT} ${ADDRESS_LIST}"
./${SCRIPT}
