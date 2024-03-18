# apex-testing-tool

## Prerequisites:

* intel based linux system (this was tested on)
* docker with compose
* network

## Connecting to local testnet

```
make reset-local-cluster
make run-local-cluster-docker
```

## Connecting to vector2 testnet

```
make run-vector2-testnet-docker
```

## Running test scenarios


```
make init
./k6 run script.js
```

### Scripts.js file

Script.js is example script for making k6 test scenarios, it uses predefined bash scripts from scripts/ directory to make specific scenarios.

### scripts/

* generate_address (VUS_ID, WALLET_ID) - Creates wallet files at test-data/vus-#/wallet-# [.addr|.skey|.vkey]
```
./scripts/generate_address.sh 1 1
```

* send_one_tx (SENDER_PATH, RECEIVER_PATH, AMOUNT) - Sends single Tx from SENDER_PATH address to RECEIVER_PATH address
```
./scripts/send_one_tx.sh cluster/chain_A/utxo-keys/user test-data/vus-1/wallet-1 10000000
```

* distribute_utxos (SENDER_PATH, AMOUNT, DESTINATION_PATH[]...) - Sends AMOUNT from SENDER_PATH address to every DESTINATION_PATH address
```
./scripts/distribute_utxos.sh cluster/chain_A/utxo-keys/user 10000000 test-data/vus-1/wallet-1 test-data/vus-1/wallet-2 test-data/vus-1/wallet-3 ...
```

* return_all_utxos (SENDER_PATH, RECEIVER_PATH) - Collects all UTXOs from SENDER_PATH address and sends them to RECEIVER_PATH address
```
./scripts/return_all_utxos.sh test-data/vus-1/wallet-1 cluster/chain_A/utxo-keys/user
```

* query_utxos - Queries cardano-cli query utxo command for every wallet found in test-data directory
```
./scripts/query_utxos.sh
```

* startup (VUS_COUNT, WALLET_COUNT, SENDER_PATH, INITIAL_AMOUNT) - Creates WALLET_COUNT wallets for every VUS_COUNT user and sends INITIAL_AMOUNT funds from SENDER_PATH address
```
./scripts/startup.sh 8 2 cluster/chain_A/utxo-keys/user 10000000
```

* teardown (RECEIVER_PATH) - Finds every wallet in test-data directory and returns all UTXOs found on it
```
./scripts/teardown.sh cluster/chain_A/utxo-keys/user
```

### More about k6
```
https://docs.google.com/document/d/1qLNMI8QT_jyXNJICtccBoTfsd3_56h-PuwvcC1-oe-c/edit#heading=h.qj4wbro9f2un
```