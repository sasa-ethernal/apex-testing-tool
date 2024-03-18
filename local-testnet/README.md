# Apex vector testnet relay and tooling

This docker compose file is starting following containers:

* apex-relay (standalone, prerequisite for dbsync and wallet-api)
* wallet-api (requires apex-relay)
* icarus (requires wallet-api)
* ogmios (requires apex-relay)

The docker compose file is envisioned as example of available tooling and will start all of them in sequence.
Feel free to exclude/modify listed services as per your requirements, following the dependency comments.

For detals consult the docker compose file but at the time of writing, the followinge versions apply:

| Component  | Version      | Docker registry                      |
|------------|--------------|--------------------------------------|
| apex-relay |        8.7.3 | ghcr.io/intersectmbo/cardano-node    |
| wallet-api |   2023.12.18 | cardanofoundation/cardano-wallet     |
| icarus     |  v2023-04-14 | piotrstachyra/icarus                 |
| ogmios     |       v6.1.0 | cardanosolutions/ogmios              |

The additional info can be found in following files:

* WALLET.md (some information about `wallet-cli` and mnemonics handling)
* TRANSACIONS.md (short recap of `cardano-cli` and simple transaciton handling)

## Prerequisites:

* intel based linux system (this was tested on)
* docker with compose
* network


## Start procedure

Run:

```
docker compose up -d
```


## Apex node relay

This is a relay node connected to a running `local-testnet` network. All `cardano-cli` commands apply as usual. For example:

To check the tip (at the moment it is about 10 min to sync, will definitely vary over time):

```
docker exec -it local-testnet-tools-v3-apex-relay-1 cardano-cli query tip --testnet-magic 1177 --socket-path /ipc/node.socket
```


## Wallet API and Icarus

Wallet API provides an HTTP Application Programming Interface (API) and command-line interface (CLI) for
working with wallets. It also featuers a lightweight frontend web interface called Icarus.

For wallet-api consult the [online documentation](https://cardano-foundation.github.io/cardano-wallet/api/edge/).
To check the wallet-api point a browser to `localhost` port `8090`, for example:

```
http://localhost:8090/v2/network/information
http://localhost:8090/v2/network/clock
```

To check the icarus wallet-api ui point a browser to `localhost` port `4444` and then click `Connect` button, for example:

```
http://localhost:4444/
http://localhost:4444/network-info
```

## Ogmios API

For ogmios api consult the [online documentation](https://ogmios.dev/api/v5.6/).
To check ogmios http api point a browser to `localhost` port `1337`, for example:

```
http://localhost:1337/
```


## Remove procedure

To remove containers and volumes, images will be left for fast restart:

```
docker compose down
docker volume rm \
  local-testnet-tools-v3_node-db \
  local-testnet-tools-v3_wallet-api-data
```
