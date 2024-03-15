# Apex vector testnet relay and tooling

This docker compose file is starting following containers:

* apex-relay (standalone, prerequisite for dbsync and wallet-api)
* postgres (standalone, prerequisite for dbsync and blockfrost)
* dbsync (requires apex-relay and postgres)
* blockfrost (requires postgres and consequently dbsync to keep it up to date)
* wallet-api (requires apex-relay)
* icarus (requires wallet-api)
* ogmios (requires apex-relay)

The docker compose file is envisioned as example of available tooling and will start all of them in sequence.
Feel free to exclude/modify listed services as per your requirements, following the dependency comments.

For detals consult the docker compose file but at the time of writing, the followinge versions apply:

| Component  | Version      | Docker registry                      |
|------------|--------------|--------------------------------------|
| apex-relay |        8.7.3 | ghcr.io/intersectmbo/cardano-node    |
| postgres   | 14.10-alpine | postgres                             |
| dbsync     |     13.2.0.1 | ghcr.io/intersectmbo/cardano-db-sync |
| blockfrost |       v1.7.0 | blockfrost/backend-ryo               |
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

This is a relay node connected to a running `vector2-testnet` network. All `cardano-cli` commands apply as usual. For example:

To check the tip (at the moment it is about 10 min to sync, will definitely vary over time):

```
docker exec -it vector2-testnet-tools-v3-apex-relay-1 cardano-cli query tip --testnet-magic 1177 --socket-path /ipc/node.socket
```


## DbSync

DbSync is indexer created as ETL tool coprised of three components:

* running node relay (to track blockchain state)
* dbsync etl tool (to react to block events, parse them and store them to postgres database)
* postgres database

Credentials to access the postgres database are in `secrets/dbsync/` folder.


## Blockfrost

Blockfrost is an instant, highly optimized and accessible API as a Service that serves as an alternative access
to the Cardano blockchain and related networks, with extra features.

For blockfrost api consult the [online documentation](https://docs.blockfrost.io/).
To check the blockfrost point a browser to `localhost` port `3000`, for example:

```
http://localhost:3000
http://localhost:3000/epochs/latest
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
  vector2-testnet-tools-v3_db-sync-data \
  vector2-testnet-tools-v3_node-db \
  vector2-testnet-tools-v3_node-ipc \
  vector2-testnet-tools-v3_postgres \
  vector2-testnet-tools-v3_wallet-api-data
```
