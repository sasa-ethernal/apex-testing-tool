init:
	go install go.k6.io/xk6/cmd/xk6@latest
	xk6 build --with github.com/grafana/xk6-exec@latest

reset-local-cluster:
	chmod +x cardano-scripts/reset-all.sh
	bash cardano-scripts/reset-all.sh

run-local-cluster-docker:
	cd local-testnet && docker compose up -d

run-vector2-testnet-docker:
	cd vector2-testnet && docker compose up -d
	docker exec -it vector2-testnet-apex-relay-1 cardano-cli query protocol-parameters --testnet-magic 1177 --socket-path /ipc/node.socket --out-file /ipc/protocol-parameters.json
	
test: run-test
	./k6 run script.js
