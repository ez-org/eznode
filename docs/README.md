# 𝚎𝚣𝚗𝚘𝚍𝚎 &nbsp;𝚞𝚜𝚎𝚛 &nbsp;𝚐𝚞𝚒𝚍𝚎
 
- [🚀 Quickstart](#-quickstart)
- [✂️ Pruning](#%EF%B8%8F-pruning)
- [⚙️ Configuration](#%EF%B8%8F-configuration)
- [👩‍💻 Accessing the services](#-accessing-the-services)
  - [💻 Locally](#-connecting-locally)
  - [🌐 Remotely](remote.md)
  - [🔐 Authentication](#-authentication)
- [🎁 Packages](#-packages)
  - [Bitcoin Core](#bitcoin-core) &middot; [BWT/Electrum](#bitcoin-wallet-tracker) &middot; [RPC Explorer](#btc-rpc-explorer) &middot; [Specter](#specter-desktop)
  - [Tor Onion](remote.md#tor) &middot; [Dropbear/SSH](remote.md#dropbear) &middot; [NGINX/SSL](remote.md#nginx) &middot; [Let's Encrypt](remote.md#lets-encrypt)
- [🔧 Server management](#-server-management)
  - [😈 Daemonizing](#-daemonizing)
  - [🕹️ Controlling services](#%EF%B8%8F-controlling-services)
  - [🖥️ Terminal display](#%EF%B8%8F-terminal-display)
  - [📝 Viewing logs](#-viewing-logs)
  - [🔄 Updating](#-updating)
  - [💾 Backing up](#-backing-up)
- [🏗️ Building locally](#%EF%B8%8F-building-locally)
- [🔏 Signed images](#-signed-images)


## 🚀 Quickstart

[Install Docker](https://docs.docker.com/get-docker/) (the only dependency) and start eznode with the data directory mounted to `/data`:
```bash
docker run -it --rm --name ez -v ~/eznode:/data eznode/eznode TOR=1 XPUB=<xpub>
```

This will setup a pruned Bitcoin Core full node, an Electrum server tracking your `<xpub>`, a block explorer and a Tor onion service for secure remote access. All the information you need for accessing them will be shown on startup.

Change `~/eznode` if you'd like to store the node's data files elsewhere. On Windows, you can use `$env:AppData\eznode` to store them in `C:\Users\<USER>\AppData\Roaming`. They will require ~4.8GB of free space.

On Windows/macOS, you'll need to [publish the ports with `-p`](#-connecting-locally).

Set `TRUSTED_FASTSYNC=1` to enable the [*trusted* fast-sync](#fast-sync) mode. You should carefully consider the implications and avoid this if possible.

To enable Specter Desktop, set `SPECTER=1`.

To experiment on signet, set `NETWORK=signet`.

## ✂️ Pruning

eznode is pruned by default with prune=550. It'll take up a total of ~4.8GB including the UTXO set and indexes (as of Feb 2021).

A pruned node can only scan the recent blocks it still has available for transactions related to your wallet. This makes it primarily suitable for newly created wallets.

There is, however, an opportunity to scan for your wallet's full history during the initial sync of your node, by scanning the blocks before they get pruned. This requires your xpubs/descriptors to be configured during the initial sync and will not work with [fast-sync](#fast-sync).

Additional xpubs/descriptors added after your node is synced will by default be tracked for new activity only.
If you'd like to retain the ability to rescan wallets with historical activity, set `PRUNE=0` to disable pruning or `PRUNE_UNTIL=<yyyy-mm-dd>` to keep blocks since the given date.

You could then initiate a rescan by setting `RESCAN_SINCE=<yyyy-mm-dd>` to the wallet creation time (err on the too early side to avoid missing transactions). It has to be more recent than `PRUNE_UNTIL`.

## ⚙️ Configuration

There are no mandatory configurations \o/, but you'll need to set at least one `XPUB`/`DESCRIPTOR` to use the BWT Electrum server. Below are some common settings:

```
XPUB=xpub33...
DESCRIPTOR='wpkh(xpub55.../0/*)'
DESCRIPTOR_2='wpkh(xpub55.../1/*)'

# Enable *trusted* fast-sync (see below)
# TRUSTED_FASTSYNC=1

# Enable authentication (except for Electrum)
AUTH_TOKEN=mySecretPassword

# Enable Tor onion service
TOR=1
```

eznode can be configured in several ways:

1. Using the standard `-e`/`--env` and `--env-file` arguments for `docker run`:<br>
   `$ docker run -e NETWORK=signet ... eznode/eznode`
   
2. Using a list of `KEY=VALUE` pairs tucked at the end of `docker run`:<br>
   `$ docker run ... eznode/eznode NETWORK=signet ...`

3. Using a `config` file with `KEY=VAL` pairs in your data directory (`~/eznode/config`).<br>
   The config file is `source`ed and may contain bash scripting and comments.

Global options:
- `NETWORK=bitcoin` (or `signet`/`testnet`/`regtest`)
- `AUTH_TOKEN=<none>` (enable [authentication](#-authentication))
- `VERBOSE=0` (increase logs verbosity)
- `BIND_ADDR=<auto>` (defaults to the container's virtual address)

Enable/disable packages:
- `BWT=1`
- `EXPLORER=1`
- `SPECTER=0`
- `TOR=0`
- `SSHD=0`
- `SSL=0`

See the individual packages below for their configuration options.

## 👩‍💻 Accessing the services

### 💻 Connecting locally

On Linux, you can access the services from the same machine running eznode by connecting directly to the docker container virtual IP address, which will be shown on startup.

![](https://raw.githubusercontent.com/shesek/eee/master/docs/img/server-urls.png)

You can optionally create an `ez` hostname alias for easier access to the services (for example http://ez:3002/) by mounting your hosts file with `-v /etc/hosts:/ez/hosts`. A new entry with the virtual IP address will be added automatically. You can also do this manually:

```bash
$ echo "$(docker inspect -f '{{.NetworkSettings.IPAddress}}' ez) ez" | sudo tee -a /etc/hosts
```

On macOS/Windows, you'll have to publish the ports with `-p 127.0.0.1:<port>:<port>` to make them available through `localhost`. Accessing them through the virtual IP address will [not](https://docs.docker.com/docker-for-mac/networking/#known-limitations-use-cases-and-workarounds) [work](https://docs.docker.com/docker-for-windows/networking/#known-limitations-use-cases-and-workarounds). For example, to make the block explorer available at http://localhost:3002/, run:

```bash
$ docker run -it -p 127.0.0.1:3002:3002 --rm --name ez -v ~/eznode:/data eznode/eznode
```

The ports are: `8332` for the Bitcoin Core RPC, `50001` for the BWT Electrum server, `3060` for the HTTP API, `3002` for the block explorer and `25441` for Specter. They are unencrypted and not suitable for access over the internet.

#### Local LAN

To access the services within a secure LAN, publish the ports on `0.0.0.0` or leave the address unspecified (e.g. `-p 50001:50001`). Note that this will bind on all available interfaces and [go right over](https://github.com/docker/for-linux/issues/777) some software firewalls (like `ufw`).

Depending on how secure you consider your LAN to be, you might want to consider enabling [authentication](#-authentication) and/or encryption with SSH/SSL.

### 🌐 Connecting remotely

You can access your eznode remotely using Tor onion services, SSH port tunneling, or SSL. 

See [`docs/remote.md`](remote.md) for a comparison between the different options and setup instructions.

## 🔐 Authentication

You can set `AUTH_TOKEN=mySecretPassword` to enable password authentication for everything *except* the Electrum server - BWT's HTTP API, BTC RPC Explorer and Specter.

> ⚠️ Using the Electrum server securely over the internet requires an authentication layer like SSH or Tor. An attacker with access to your Electrum server could check whether certain addresses are associated with your wallet, by querying for their history and checking if the server knows about them or not.

When the NGINX-backed SSL is enabled, NGINX will be configured to authenticate the password before forwarding traffic to the backend services. This helps protect against zero-day exploits.

You can use any username to login, except for the NGINX-based authentication which expects `satoshi`.

# 🎁 Packages

## Bitcoin Core

Full bitcoin node. [Pruned](#%EF%B8%8F-pruning) by default.

#### Fast sync

To enable fast-sync, set `TRUSTED_FASTSYNC=1`. This will download a recent pruned datadir snapshot from [prunednode.today](https://prunednode.today/) and start syncing from that instead of from scratch.

Using this option requires **trusting** the distributor of the snapshot. A malicious distributor could *feed you with invalid chain history and lead you to accept fake coins*. Please consider waiting some more for a full sync to avoid taking this risk.

A fast-synced node [is not able](#%EF%B8%8F-pruning) to scan for historical wallet transactions and is meant for use with newly created wallets.

[prunednode.today](https://prunednode.today/) is maintained by the [Specter Desktop](https://github.com/cryptoadvance/specter-desktop) team and signed by [Stepan Snigirev](https://stepansnigirev.com/).

> You'll need 10G of free space during the setup to store both the snapshot `.zip` file and the files extracted from it. It will shrink down to <5GB when the process completes.

#### Using existing full node

<details>
 <summary>Expand instructions...</summary><br>

If you already have a Bitcoin Core instance running on the same machine, you can connect eznode to it using cookie authentication by mounting the datadir into `/bitcoin`:

```bash
$ docker run -v ~/.bitcoin:/bitcoin:ro -it ... eznode/eznode
```

> On Linux, you'll need to add `--add-host host.docker.internal:host-gateway` to make the host's address discoverable from within the container. On Windows, change `~/.bitcoin` to `$env:AppData\Bitcoin`.

Instructions for modifying bitcoind's `rpcbind`/`rpcallowip` config will be shown on startup. If you're running into trouble with Docker's virtual networking, you can try with [`--net host`](https://docs.docker.com/network/host/) (this should ideally be avoided).

If your node is running remotely, you can configure its URL and RPC credentials with `BITCOIND_URL=http://my-bitcoind-server:8332/ BITCOIND_AUTH=satoshi:mySecretPassword`.

</details>

#### Accessing managed full node

<details>
 <summary>Expand instructions...</summary><br>

To issue RPC commands against eznode's managed Bitcoin Core instance, use `$ docker exec ez bitcoin-cli <command>` (see [*Server management*](#-server-management)).

To connect to the Bitcoin Core RPC from your host, set `BITCOIND_RPC_ACCESS=<user:pwd>` to open the RPC server for external access using password-based authentication.

On macOS/Windows, you'll need to publish the RPC port with `-p 127.0.0.1:8332:8332` to make it available through `localhost`. On Linux you can access it directly through the container IP address or using the `ez` alias (see [*Connecting Locally*](#-connecting-locally)).

If you'd like to access the RPC remotely, set `BITCOIND_RPC_ONION` to expose it through an [onion service](remote.md#tor) or setup an [SSH tunnel](remote.md#dropbear).

</details>

#### Options for managed full node
- `PRUNE=550` (set to `0` to disable pruning)
- `PRUNE_UNTIL=<height|yyyy-mm-dd>` (prune blocks before the given height/date)
- `TXINDEX=0` (enabling this requires pruning to be disabled)
- `BITCOIND_LISTEN=0` (accept incoming connections on the bitcoin p2p network)
- `BITCOIND_TOR=0` (connect to the bitcoin network through tor)
- `BITCOIND_RPC_ACCESS` (expose the bitcoind rpc with password-based auth)
- `BITCOIND_RPC_ONION=0` (expose the bitcoind rpc over onion)
- `BITCOIND_OPTS=<none>` (custom cli options for bitcoind)
- `BITCOIND_LOGS=0` (display bitcoind's logs in the `docker run` output)

A config file may be provided at `/data/bitcoin/bitcoin.conf`.

#### Options for fastsync
- `TRUSTED_FASTSYNC=0` (enable fast-sync)
- `FASTSYNC_PARALLEL=1` (parallel connections for download)

#### Paths
- `/bitcoin` (mount the bitcoind datadir from the host to enable cookie authentication)
- `/data/bitcoin` (managed bitcoind data directory)

#### Ports
- `8332`/`18332`/`38332`/`18443` (RPC)
- `8333`/`18333`/`38333`/`18444` (P2P)<br>
  (mainnet/testnet/signet/regtest)

## Bitcoin Wallet Tracker

[Bitcoin Wallet Tracker](https://bwt.dev/) is a personal wallet tracker that watches your wallet's activity, available as an Electrum RPC server and an [HTTP API](https://github.com/bwt-dev/bwt#http-api).

BWT keeps an index of your wallet transactions only. To make your wallet activity available, you'll have to configure your xpubs/descriptors.

#### Electurm wallet setup
<details>
 <summary>Expand instructions...</summary><br>

With pruning enabled (the default), starting with a new wallet is the easiest. Make sure you don't connect to public servers while creating it (you can start Electrum with `--offline` to ensure that).
To use an existing wallet, read the [instructions here](#%EF%B8%8F-pruning) first.

Grab your xpub from `Wallet` > `Information` and add it to your config file (`~/eznode/config`) as a new line with `XPUB=<my-xpub>` (or `XPUB_*` if you have multiple).

Restart eznode and wait for BWT to sync up. This may take awhile if you're using an existing wallet that requires scanning for historical transactions.

You can then run `electrum $(ez electrum-args)` to start Electurm and connect it with your local eznode (assumes the [`ez` alias described below](#-server-management)). Or you can do this manually:

```
$ electrum --oneserver --server ez:50001:t --skipmerklecheck
```

> If you don't have the [`ez` hostname](#-connecting-locally) set up, replace `ez` with the IP address shown on startup (`electrum-args` does this automatically). The [`skipmerklecheck`](https://github.com/spesmilo/electrum/pull/4957) option is needed to support pruning.

To configure Electrum to use eznode by default, run `ez electrum-cfg | bash -x`. This will issue `electrum setconfig` commands (you can run without `| bash` to see them).

If you're connecting remotely, you'll need to setup [Tor Onion or an SSH tunnel](remote.md) for secure access.
</details>

#### Electrum wallet setup - with the BWT plugin
<details>
 <summary>Expand instructions...</summary><br>

You can also setup Electrum desktop to connect with eznode using the [BWT Electrum plugin](https://github.com/bwt-dev/bwt-electrum-plugin).
The plugin will run a separate BWT instance that connects to Bitcoin Core directly and automatically detects your wallet(s) xpub(s).

[Open RPC access](#accessing-managed-full-node) to Bitcoin Core by setting `BITCOIND_RPC_ACCESS=<user:pwd>`, then follow the [instructions here](https://github.com/bwt-dev/bwt-electrum-plugin#installation) to setup the plugin.
</details>

#### Options
- `BWT=1` (enabled by default, set to `0` to turn off)
- `XPUB`/`XPUB_*` (xpubs/ypubs/zpubs to track)
- `DESCRIPTOR`/`DESCRIPTOR_*`/`DESC_*` (output script descriptors to track)
- `RESCAN_SINCE=now` (date to begin rescanning for historical wallet transactions in `YYYY-MM-DD` format. By default, only new transactions will be visible.)
- `BITCOIND_WALLET=ez-bwt` (bitcoind wallet to use)
- `CREATE_WALLET_IF_MISSING=1` (automatically create a new bitcoind wallet)
- `GAP_LIMIT=20` (the gap limit for address import)
- `FORCE_RESCAN=0` (force rescanning for historical transactions, even if the addresses were already previously imported)
- `HTTP_CORS=<none>` (allowed cross-origins for the http api server)
- `WEBHOOK_URLS=<none>` (URLs to notify with real-time wallet events)
- `AUTH_TOKEN=<none>` (enable authentication with the specified token)
- `BWT_LOGS=1` (display bwt's logs in the `docker run` output)

The full list of BWT's config options is [available here](https://github.com/bwt-dev/libbwt#config-options).

#### Ports
- `50001` (Electrum RPC)
- `3060` (HTTP API)

#### Paths
- `/data/watch-addresses.txt` (optional list of standalone addresses to track)

## BTC RPC Explorer

[BTC RPC Explorer](https://github.com/janoside/btc-rpc-explorer) is a [block explorer](https://explorer.btc21.org/) and node dashboard with an [RPC console](https://explorer.btc21.org/rpc-browser?method=getblockheader), [statistics and graphs](https://explorer.btc21.org/block-stats), [status page](https://explorer.btc21.org/node-status), [peers overview](https://explorer.btc21.org/peers) and more.

Automatically connects with the BWT Electrum server, to enable exploration of your wallet addresses (but not of arbitrary addresses).

#### Pruning support

<details>
 <summary>Expand...</summary><br>

When pruning is enabled or if `txindex` is disabled (the default), some functionality will be limited:
- You will only be able to search for wallet, mempool and recently confirmed transactions by their `txid`. Searching for non-wallet transactions that were confirmed over 3 blocks ago is only possible if you provide the confirmed block height in addition to the `txid`.
- Pruned blocks will display basic header information, without the list of transactions. Transactions in pruned blocks will not be available, unless they're wallet-related.
- The address and amount of previous transaction outputs will not be shown, only the `txid:vout`. 
- Mining fees will only be shown for unconfirmed transactions.

Enabling full block explorer functionality requires setting `PRUNE=0 TXINDEX=1`.
</details>

#### Options
- `EXPLORER=1` (enabled by default, set to `0` to turn off)
- `EXPLORER_LOGS=0`  (display btc-rpc-explorer's logs in the `docker run` output)
- `AUTH_TOKEN=<none>` (alias for `BTCEXP_BASIC_AUTH_PASSWORD`)

Plus all of [btc-rpc-explorer's options](https://github.com/janoside/btc-rpc-explorer/blob/master/.env-sample).

#### Ports
- `3002`

## Specter Desktop

[Specter Desktop](https://github.com/cryptoadvance/specter-desktop) is a wallet GUI for Bitcoin Core with a focus on hardware and multi-sig setups.

Using Specter with USB hardware wallets requires [setting up udev rules](https://github.com/cryptoadvance/specter-desktop/tree/master/udev#udev-rules) on the host and starting docker with [`--device /dev/<usb-device-id>`](https://docs.docker.com/engine/reference/commandline/run/#add-host-device-to-container---device). If you're unsure what the device id is, you could also (less ideally) use [`--privileged -v /dev:/dev`](https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities) to give the container full access to all the host devices.

#### Options
- `SPECTER=0` (disabled by default, set to `1` to enable)
- `SPECTER_LOGS=0` (display spectr's logs in the `docker run` output)
- `AUTH_TOKEN=<none>` (sets the password for the admin account)

Additional configuration options are available through Specter's web interface.

#### Paths
- `/data/specter` (wallets, devices and other configuration)

#### Ports
- `25441`


# 🔧 Server management

To make things easier, setting the following aliases is recommended:

```bash
$ alias ez='docker exec ez'
$ alias bitcoin-cli='ez bitcoin-cli'
```

With these in place, you can use `bitcoin-cli` as you normally would and `ez <cmd>` to issue other commands on the container.

You can add the aliases to `~/.profile` to make them permanent. The instructions below assumes you have them set up.

To run an interactive command, use `docker exec -it`. For example, `docker exec -it ez bash` to start a new shell.

To manage the server remotely, you can enable the [SSH service](remote.md#dropbear) with `SSHD=UNRESTRICTED`.

## 😈 Daemonizing

To run the docker container as a background daemon and have it automatically run on start-up, change `docker run` to use `-d --restart unless-stopped` instead of  `-it --rm`. For example:

```bash
$ docker run -d --restart unless-stopped --name ez -v ~/eznode:/data eznode/eznode
```

You can control the background container using `$ docker stop|start|restart ez`.

## 🕹️ Controlling services

eznode uses the (fantastic!) [`s6`](https://skarnet.org/software/s6/) init/supervision system (via [`s6-overlay`](https://github.com/just-containers/s6-overlay)) to manage services.

A [CLI utility](https://github.com/ez-org/eznode/blob/master/s6/service.sh) wrapper written on top of the `s6` commands is provided to ease service management:

```bash
# Display an overview of all services
$ ez status

# Display more information
$ ez status -v

# Display the status of some service(s)
$ ez status <services...>

# Basic management
$ ez start|stop|restart <services...>
```

<img src="https://raw.githubusercontent.com/shesek/eee/master/docs/img/services.png" width="550">


## 🖥️ Terminal display

You can setup a simple textual dashboard display with information about your node and the Bitcoin network using `$ watch -t -n10 docker exec ez banner`.

It will look something like this:

<img src="https://raw.githubusercontent.com/shesek/eee/master/docs/img/banner.png" width="550">

## 📝 Viewing logs

The main logs are displayed in the `docker run` output, including some select important log messages across all services. If you're running the container in the background, you can use `$ docker logs -f ez` to view them.

`$ ez logs` will stream full logs from all the services (`tail -f`-like). You can use `$ ez logs <services...>` to select specific services.

`-n` sets how many last log lines are returned initially (defaults to 8). `-c` reads the logs without following them. For example: `$ ez logs -c -n1000 bitcoind`.

You can request that some services will be logged in the main `docker run` output using the following flags: `BITCOIND_LOGS`, `BWT_LOGS`, `EXPLORER_LOGS`, `SPECTER_LOGS`, `TOR_LOGS`, `SSHD_LOGS` and `LETSENCRYPT_LOGS`.

## 🔄 Updating

Updating your eznode is a simple matter of:

```bash
$ docker pull eznode/eznode
```

And re-running `docker run`.

## 💾 Backing up

All of the important directories that needs to be backed up are symlinked in `/important`. You can create a backup `tar.gz` file with everything using the following command:

```bash
$ ez backup > ez-backup.tar.gz
```

> `backup` is a shortcut for `tar czvhf - /important`.

The backup includes the following:

- Bitcoin Core wallets (`/data/bitcoin/**/wallets`) + `bitcoin.conf`
- Specter wallets/devices config (`/data/specter`)
- SSH keys (`/data/ssh-keys`)
- SSL keys/certificates (`/data/nginx-keys`)
- Tor onion service files (`/data/tor-hsv`)
- Config file (`/data/config`)

Everything that needs to be backed up is kept within the directory mounted to `/data`, so keeping a safe copy of it is sufficient. But `/data` also includes files that don't require a backup, like the bitcoind data files. The `/important` directory contains the minimal set of files that do require it.

# 🏗️ Building locally

```bash
# Clone repo and verify signature
$ git clone https://github.com/ez-org/eznode && cd eznode
$ git checkout <tag>
$ git verify-commit HEAD

# Build
$ docker build -t eznode .

# Run using local image
$ docker run -it ... eznode ...
```

All the files retrieved during the build are verified by their hash.

To build the ARM32v7/ARM64v8 images, run `$ ./docker/build-arch.sh [arm|arm64] -t eznode`. Cross-compilation requires [qemu-user-static](https://github.com/multiarch/qemu-user-static) to be installed.

You can upgrade third-party packages yourself by setting the following `--build-arg`s: `BITCOIND_{VERSION,SHA256}`, `BWT_{VERSION,SHA256}`, `BTCEXP_{VERSION,SHA256}` and `SPECTER_{VERSION,SHA256}`.

# 🔏 Signed images

Signed docker image digests are available in [`SHA256SUMS.asc`](https://github.com/ez-org/eznode/blob/master/SHA256SUMS.asc).

The images are signed by Nadav Ivgi (@shesek). The public key can be verified on the [PGP WoT](http://keys.gnupg.net/pks/lookup?op=vindex&fingerprint=on&search=0x81F6104CD0F150FC), [github](https://api.github.com/users/shesek/gpg_keys), [twitter](https://twitter.com/shesek), [keybase](https://keybase.io/nadav), [hacker news](https://news.ycombinator.com/user?id=nadaviv) and [this video presentation](https://youtu.be/SXJaN2T3M10?t=4).

```bash
# Verify signature
$ wget https://raw.githubusercontent.com/ez-org/eznode/latest/SHA256SUMS.asc
$ gpg --keyserver keyserver.ubuntu.com --recv-keys FCF19B67866562F08A43AAD681F6104CD0F150FC
$ gpg --verify SHA256SUMS.asc

# Get the signed hash for your platform
$ grep amd64 SHA256SUMS.asc

# Fetch docker image by hash and give it a local alias
$ docker pull eznode/eznode@sha256:<hash>
$ docker tag eznode/eznode@sha256:<hash> eznode

# Run using local alias
$ docker run -it ... eznode ...
```
