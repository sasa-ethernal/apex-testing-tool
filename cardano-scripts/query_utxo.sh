
# Query User utxo
echo "prime user"
cardano-cli query utxo --address $(cat test-data/local-cluster/utxo-keys/user.addr) --testnet-magic 1177 --socket-path test-data/local-cluster/node-spo1/node.socket

# TODO query all test generated UTXOs
