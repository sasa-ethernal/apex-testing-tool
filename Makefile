init:
	go install go.k6.io/xk6/cmd/xk6@latest
	xk6 build --with github.com/grafana/xk6-exec@latest

run-cluster:
	chmod +x scripts/run_cluster.sh
	bash scripts/run_cluster.sh

run-nodes:
	bash cluster/chain_A/node-spo1.sh &
	bash cluster/chain_A/node-spo2.sh &
	bash cluster/chain_A/node-spo3.sh &
	
test: run-cluster
	./k6 run script.js

show:
	watch -n 0.5 -- cardano-cli query tx-mempool info --socket-path cluster/chain_A/node-spo1/node.sock --testnet-magic 142
