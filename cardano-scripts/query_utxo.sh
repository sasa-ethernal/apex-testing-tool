
# Query User utxo
echo "prime user"
cardano-cli query utxo --address $(cat cluster/chain_A/utxo-keys/user.addr) --testnet-magic 142 --socket-path cluster/chain_A/node-spo1/node.sock

# TODO query all test generated UTXOs
