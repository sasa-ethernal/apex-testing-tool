#!/bin/bash
cardano-node run --topology cluster/relay/topology.json --database-path cluster/relay/db --host-addr 0.0.0.0 --port 6000 --config cluster/relay/configuration.yaml --socket-path cluster/relay/node.socket
