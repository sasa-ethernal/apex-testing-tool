#!/usr/bin/env bash

ROOT_DIR=test-data/local-cluster
RELAY_DIR=local-testnet
MKFILES_SCRIPT=cardano-scripts/mkfiles.sh
RUN_CLUSTER=run/all.sh

# Remove Chain_A data
rm -rf ${ROOT_DIR}
rm -rf ${RELAY_DIR}/genesis
rm -rf ${RELAY_DIR}/config

# Execute mkfiles script
bash ${MKFILES_SCRIPT}
sleep 1

# Relay-node data
cd $RELAY_DIR
mkdir config
cd config
mkdir ogmios
mkdir relay
cd ../..

cp -R ${ROOT_DIR}/genesis ${RELAY_DIR}

cp ${ROOT_DIR}/configuration.yaml ${RELAY_DIR}/config
cat > "${RELAY_DIR}/config/topology.json" <<EOF
{
  "Producers": [
    {
      "addr": "host.docker.internal",
      "port": 13001,
      "valency": 1
    }
  ]
}
EOF

sed -i "9s%.*%ByronGenesisFile: /genesis/byron/genesis.json%" "${RELAY_DIR}/config/configuration.yaml"
sed -i "10s%.*%ShelleyGenesisFile: /genesis/shelley/genesis.json%" "${RELAY_DIR}/config/configuration.yaml"
sed -i "11s%.*%AlonzoGenesisFile: /genesis/shelley/genesis.alonzo.json%" "${RELAY_DIR}/config/configuration.yaml"
sed -i "12s%.*%ConwayGenesisFile: /genesis/shelley/genesis.conway.json%" "${RELAY_DIR}/config/configuration.yaml"

cp ${RELAY_DIR}/config/configuration.yaml ${RELAY_DIR}/config/ogmios/configuration.yaml
cp ${RELAY_DIR}/config/configuration.yaml ${RELAY_DIR}/config/relay/configuration.yaml
cp ${RELAY_DIR}/config/topology.json ${RELAY_DIR}/config/ogmios/topology.json
cp ${RELAY_DIR}/config/topology.json ${RELAY_DIR}/config/relay/topology.json

# Execute run_all script
gnome-terminal -- bash ${ROOT_DIR}/${RUN_CLUSTER}
sleep 10

cd $ROOT_DIR/

# Params
export CARDANO_NODE_SOCKET_PATH=node-spo1/node.socket
CARDANO_NET_PREFIX="--testnet-magic 1177"
PROTOCOL_PARAMETERS=protocol-parameters.json
cardano-cli query protocol-parameters --out-file ${PROTOCOL_PARAMETERS} ${CARDANO_NET_PREFIX}
mkdir ../node-ipc/
cp ${PROTOCOL_PARAMETERS} ../node-ipc/${PROTOCOL_PARAMETERS}

# Generate new keys for USER and BRIDGE
for KEY in user bridge; do
cardano-cli address key-gen \
	--verification-key-file utxo-keys/${KEY}.vkey \
	--signing-key-file utxo-keys/${KEY}.skey

cardano-cli address build \
	--payment-verification-key-file utxo-keys/${KEY}.vkey \
	--out-file utxo-keys/${KEY}.addr \
	--testnet-magic 42
done

# Generate .addr files for all addresses
for N in 1 2 3; do
	cardano-cli address build \
	--payment-verification-key-file utxo-keys/utxo${N}.vkey \
	--out-file utxo-keys/utxo${N}.addr \
	--testnet-magic 42
done
	
# Send tokens from first cardano generated addr to USER and BRIDGE
SENDER=$(cat utxo-keys/utxo1.addr)
DSTADDRESS=$(cat utxo-keys/user.addr)

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
    --out-file tx.draft

# Calculate fee
FEE=$(cardano-cli transaction calculate-min-fee \
    --tx-body-file tx.draft \
    --tx-in-count 1 \
    --tx-out-count 2 \
    --witness-count 1 \
    --protocol-params-file $PROTOCOL_PARAMETERS \
    ${CARDANO_NET_PREFIX})
FEE_AMOUNT=$(echo ${FEE} | awk '{print $1}')

# Amount
AMOUNT_TO_SEND=100000000000
# Sender sends fee
SENDER_AMOUNT_TO_SEND=$FEE_AMOUNT+$AMOUNT_TO_SEND
# Sender receive his change
SENDER_AMOUNT_TO_RECEIVE=$((AMOUNT_SENDER-SENDER_AMOUNT_TO_SEND))
# Receiver receive amount sent from script
RECEIVER_AMOUNT_TO_RECEIVE=$AMOUNT_TO_SEND

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
    --out-file tx.draft

cardano-cli transaction sign \
    --signing-key-file utxo-keys/utxo1.skey \
    --tx-body-file tx.draft \
    --out-file tx.signed \
    ${CARDANO_NET_PREFIX}

cardano-cli transaction submit \
    --tx-file tx.signed \
    ${CARDANO_NET_PREFIX}

cd ../..

mkdir -p test-data/local-keys/
cp ${ROOT_DIR}/utxo-keys/user.addr test-data/local-keys/
cp ${ROOT_DIR}/utxo-keys/user.skey test-data/local-keys/
cp ${ROOT_DIR}/utxo-keys/user.vkey test-data/local-keys/







