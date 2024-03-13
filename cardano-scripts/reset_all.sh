#!/usr/bin/env bash

ROOT_A=cluster/chain_A
RELAY_A=cluster/relay
SCRIPT_A=cardano-scripts/mkfiles_chain1.sh
RUN_A=run/all.sh

# Remove Chain_A data
rm -rf ${ROOT_A}
rm -rf ${RELAY_A}

# execute mkfiles_A
bash ${SCRIPT_A}
sleep 3

# create Relay dir..
cd cluster
mkdir relay
cd relay
mkdir db
cd ../..

cp -R ${ROOT_A}/genesis ${RELAY_A}
cp ${ROOT_A}/configuration.yaml ${RELAY_A}

cat > "${RELAY_A}/topology.json" <<EOF
{
   "Producers": [
     {
       "addr": "127.0.0.1",
       "port": 13001,
       "valency": 1
     }
   ]
 }
EOF

cat > "scripts/start_relay.sh" <<EOF
#!/bin/bash
cardano-node run --topology ${RELAY_A}/topology.json --database-path ${RELAY_A}/db --host-addr 0.0.0.0 --port 6000 --config ${RELAY_A}/configuration.yaml --socket-path ${RELAY_A}/node.socket
EOF

chmod +x scripts/start_relay.sh

# execute run_all.sh on A and B
gnome-terminal -- bash ${ROOT_A}/${RUN_A}
sleep 10

cd $ROOT_A/

# Params
MAGIC_NUMBER=142
export CARDANO_NODE_SOCKET_PATH=node-spo1/node.sock
CARDANO_NET_PREFIX="--testnet-magic ${MAGIC_NUMBER}"
PROTOCOL_PARAMETERS=protocol-parameters.json
cardano-cli query protocol-parameters --out-file ${PROTOCOL_PARAMETERS} ${CARDANO_NET_PREFIX}

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
AMOUNT_TO_SEND=10000000000
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

sleep 3
gnome-terminal -- ogmios \
  --port 13000 \
  --node-socket ${ROOT_A}/node-spo1/node.sock \
  --node-config ${ROOT_A}/configuration.yaml

mkdir ${RELAY_A}/keys/
cp ${ROOT_A}/utxo-keys/user.addr ${RELAY_A}/keys/
cp ${ROOT_A}/utxo-keys/user.skey ${RELAY_A}/keys/
cp ${ROOT_A}/utxo-keys/user.vkey ${RELAY_A}/keys/







