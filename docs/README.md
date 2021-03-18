![eznode](https://raw.githubusercontent.com/shesek/eee/master/docs/img/header.png)

# 𝚎𝚣𝚗𝚘𝚍𝚎 &nbsp;𝚞𝚜𝚎𝚛 &nbsp;𝚐𝚞𝚒𝚍𝚎

See [the repo's main readme](..) for an introduction to eznode.

- [🚀 Quickstart](#-quickstart)
- [✂️ Pruning](#%EF%B8%8F-pruning)
- [⚙️ Configuration](#%EF%B8%8F-configuration)
- [👩‍💻 Accessing the services](#-accessing-the-services)
  - [💻 Locally](#-connecting-locally)
  - [🌐 Remotely](#-connecting-remotely)
  - [🔐 Authentication](#-authentication)
- [🎁 Packages](#-packages)
  - [Bitcoin Core](#bitcoin-core) &middot; [BWT/Electrum](#bitcoin-wallet-tracker) &middot; [RPC Explorer](#btc-rpc-explorer) &middot; [Specter](#specter-desktop)
  - [Tor Onion](#tor) &middot; [Dropbear/SSH](#dropbear) &middot; [NGINX/SSL](#nginx) &middot; [Let's Encrypt](#lets-encrypt)
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

Change `~/eznode` if you'd like to store the node's data files elsewhere. On Windows, you can use `$env:AppData\eznode` to store them in `C:\Users\<USER>\AppData\Roaming`. They require ~4.8GB of free space.

On Windows/macOS, you'll need to [publish the ports with `-p`](#-connecting-locally).

Set `TRUSTED_FASTSYNC=1` to enable the [*trusted* fast-sync](#fast-sync) mode. You should carefully consider the implications and avoid this if possible.

To enable Specter Desktop, set `SPECTER=1`.

To experiment on signet, set `NETWORK=signet`.

## ✂️ Pruning

eznode is pruned by default with prune=550. It'll take up a total of ~4.8GB including the UTXO set and indexes (as of March 2021).

A pruned node can only scan the recent blocks it still has available for transactions related to your wallet. This makes it primarily suitable for use with newly created wallets.

There is, however, an opportunity to scan for your wallet's full history during the initial sync of your node, by scanning the blocks before they get pruned. This requires your xpubs/descriptors to be [configured](#%EF%B8%8F-configuration) during the initial sync and will not work with [fast-sync](#fast-sync).

Additional xpubs/descriptors added after your node is synced will by default be tracked for new activity only.
If you'd like to retain the ability to rescan wallets with historical activity, set `PRUNE_UNTIL=<yyyy-mm-dd>` to keep blocks after the given date or `PRUNE=0` to disable pruning entirely. *(Make sure to add these options in your config file so they don't get lost.)*

Then, when adding new xpubs/descriptors, you could initiate a rescan by setting `RESCAN_SINCE=<yyyy-mm-dd>` to the wallet creation time (err on the too early side to avoid missing transactions). It will have to be more recent than `PRUNE_UNTIL`.

## ⚙️ Configuration

There are no mandatory configurations \o/, but you'll need to set at least one `XPUB`/`DESCRIPTOR` to use the [BWT Electrum server](#bitcoin-wallet-tracker).

eznode can be configured in several ways:

1. Using a `config` file with `KEY=VAL` pairs in your data directory (`~/eznode/config`). Example with some common options:
   ```
   XPUB=xpub33...
   XPUB_2=xpub44...
   DESCRIPTOR='wpkh(xpub55.../0/*)'

   # Enable authentication (except for Electrum)
   AUTH_TOKEN=mySecretPassword
   
   # Enable *trusted* fast-sync (see below)
   # TRUSTED_FASTSYNC=1

   # Enable Tor onion service
   TOR=1

   # Keep blocks since 2021 to enable wallet rescans
   PRUNE_UNTIL=2021-01-01
   ```
   > The config file is `source`ed and may contain variables, bash scripting and comments.

2. Using a list of `KEY=VALUE` pairs tucked at the end of `docker run`:
   ```bash
   docker run -it ... eznode/eznode NETWORK=signet
   ```

3. Using the standard `-e`/`--env` and `--env-file` arguments for `docker run`:
   ```bash
   docker run -it ... -e NETWORK=signet eznode/eznode
   ```

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
echo "$(docker inspect -f '{{.NetworkSettings.IPAddress}}' ez) ez" | sudo tee -a /etc/hosts
```

On macOS/Windows, you'll have to publish the ports with `-p 127.0.0.1:<port>:<port>` to make them available through `localhost`. Accessing them through the virtual IP address will [not](https://docs.docker.com/docker-for-mac/networking/#known-limitations-use-cases-and-workarounds) [work](https://docs.docker.com/docker-for-windows/networking/#known-limitations-use-cases-and-workarounds). For example, to make the block explorer available at http://localhost:3002/, use:

```bash
docker run -it -p 127.0.0.1:3002:3002 --rm --name ez -v ~/eznode:/data eznode/eznode
```

The ports are: `8332` for the Bitcoin Core RPC, `50001` for the BWT Electrum server, `3060` for the HTTP API, `3002` for the block explorer and `25441` for Specter. They are unencrypted and not suitable for access over the internet.

#### Local LAN

To access the services within a secure LAN, publish the ports on `0.0.0.0` or leave the address unspecified (e.g. `-p 3002:3002`). Note that this will bind on all available interfaces and [go right over](https://github.com/docker/for-linux/issues/777) some software firewalls.

Depending on how secure you consider your LAN to be, you might want to consider enabling [authentication](#-authentication) and/or encryption with SSH/SSL.

### 🌐 Connecting remotely

You can access your eznode remotely using Tor onion services, SSH port tunneling, or SSL. Below is a summary of the pros of cons for each approach.


<details>
 <summary>Expand...</summary>
 
- Tor onion is the easiest to setup on the server's side, because it works behind NATs and firewalls with no special configuration. It provides strong encryption and authentication.

  However, it requires using the Tor client on your end devices (like Orbot for Android) and connecting through the Tor network, which can be quirky at times. The `TOR_NONANONYMOUS` option may somewhat un-quirk it.
  
  Set `TOR=1` to enable. See [more details and options below](#tor).

- SSH port tunneling can provide strong encryption and authentication using a direct connection to your server. It is the most reliable and the recommended option.

  However, if your server is behind a router or a NAT, you'll need to configure port forwarding so it can accept incoming connections, or use the [assistance of another server that can](#punch-through-nats-with-a-reverse-ssh-tunnel). You'll also need an SSH client on your end devices (like ConnectBot for Android). The setup is somewhat more involved compared to Tor.
  
  Set `SSHD=1` to enable. See [more details and options below](#dropbear).

- SSL relies on centralized authorities and is best avoided. It is also *unsuitable* for accessing the (unauthenticated) Electrum server. It can be suitable for the bwt/specter/explorer web servers if [`AUTH_TOKEN`](#-authentication) is enabled.

  On the plus side, SSL works on nearly all end devices with no special software or configuration. But it still requires setting up port forwarding on the server.
  
  Set `SSL=1` to enable with a self-signed cert, add `SSL_DOMAIN=mydomain.com` to obtain a Let's Encrypt certificate. See [more details and options below](#dropbear).

> If you're connecting directly to your server's IP address (i.e. not via onion or a [reverse SSH tunnel](#punch-through-nats-with-a-reverse-ssh-tunnel)) and don't have a static IP address, you'll probably want to use a dynamic DNS service like [afraid.org](https://freedns.afraid.org/).

</details>

## 🔐 Authentication

You can set `AUTH_TOKEN=mySecretPassword` to enable password authentication for everything *except* the Electrum server - BWT's HTTP API, BTC RPC Explorer and Specter.

> ⚠️ Using the Electrum server securely over the internet requires an authentication layer like [SSH](#dropbear) or [Tor](#tor). An attacker with access to your Electrum server could check whether certain addresses are associated with your wallet, by querying for their history and checking if the server knows about them or not.

When the NGINX-backed SSL is enabled, NGINX will be configured to authenticate the password before forwarding traffic to the backend services. This helps protect against zero-day exploits.

You can use any username to login, except for the NGINX-based authentication which expects `satoshi`.

# 🎁 Packages

## Bitcoin Core

Full bitcoin node. [Pruned](#%EF%B8%8F-pruning) by default.

#### Fast sync

To enable fast-sync, set `TRUSTED_FASTSYNC=1`. This will download a recent pruned datadir snapshot from [prunednode.today](https://prunednode.today/) and start syncing from that instead of from scratch.

This can get your node synced up 10-60 minutes (depending on how recent the snapshot is), but requires ⚠ **trusting** the distributor of the snapshot. A malicious distributor could *feed you with invalid chain history and lead you to accept fake coins*. Please consider waiting some more for a full sync to avoid taking this risk.

A fast-synced node [is not able](#%EF%B8%8F-pruning) to scan for historical wallet transactions and can therefore only be used with newly created wallets.

[prunednode.today](https://prunednode.today/) is maintained by the [Specter Desktop](https://github.com/cryptoadvance/specter-desktop) team and signed by [Stepan Snigirev](https://stepansnigirev.com/).

> You'll need 10G of free space during the setup to store both the snapshot `.zip` file and the files extracted from it. It will shrink down to <5GB when the process completes.

#### Using existing full node

<details>
 <summary>Expand instructions...</summary><br>

If you already have a Bitcoin Core instance running on the same machine, you can connect eznode to it using cookie authentication by mounting the datadir into `/bitcoin`:

```bash
docker run -v ~/.bitcoin:/bitcoin:ro -it ... eznode/eznode
```

> On Linux, you'll need to add `--add-host host.docker.internal:host-gateway` to make the host's address discoverable from within the container. On Windows, change `~/.bitcoin` to `$env:AppData\Bitcoin`.

Instructions for modifying bitcoind's `rpcbind`/`rpcallowip` config will be shown on startup. If you're running into trouble with Docker's virtual networking, you can try with [`--net host`](https://docs.docker.com/network/host/) (this should ideally be avoided).

If your node is running remotely, you can configure its URL and RPC credentials with `BITCOIND_URL=http://my-bitcoind-server:8332/ BITCOIND_AUTH=satoshi:mySecretPassword`.

</details>

#### Accessing managed full node

<details>
 <summary>Expand instructions...</summary><br>

To issue RPC commands against eznode's managed Bitcoin Core instance, use `docker exec ez bitcoin-cli <command>` (see [*Server management*](#-server-management)).

To connect to the Bitcoin Core RPC from your host, set `BITCOIND_RPC_ACCESS=<user:pwd>` to open the RPC server for external access using password-based authentication.

On macOS/Windows, you'll also need to publish the RPC port with `-p 127.0.0.1:8332:8332` to make it available through `localhost`. On Linux you can access it directly through the container's IP address or using the `ez` alias (see [*Connecting Locally*](#-connecting-locally)).

If you'd like to access the RPC remotely, set `BITCOIND_RPC_ONION` to expose it through an [onion service](#tor) or setup an [SSH tunnel](#dropbear).

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

A config file may also be provided at `/data/bitcoin/bitcoin.conf`, but the options above will take priority over it.

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

BWT keeps an index of your wallet transactions only. To make your wallet activity available, you'll need to [configure](#%EF%B8%8F-configuration) your `XPUB`s/`DESCRIPTOR`s (use `XPUB_*`/`DESC_*` if you have multiple, e.g. `XPUB_1` or `DESC_CHANGE`).


With pruning enabled (the default), starting with a new wallet is the easiest.
A new wallet is also recommended for privacy reasons, if your addresses were previously exposed to public Electrum servers.
To use an existing wallet, refer to the [instructions here](#%EF%B8%8F-pruning).

#### Electurm wallet setup
<details>
 <summary>Expand instructions...</summary><br>

If you're creating a new wallet, make sure you don't connect to public servers while doing it, to avoid exposing your addresses. You can start Electrum with `--offline` to ensure that.

Grab your xpub from `Wallet` > `Information` and add it to your config file (`~/eznode/config`) as a new line with `XPUB=<my-xpub>`.

Restart eznode, wait for BWT to start up and run `electrum $(docker exec ez electrum-args)` to start Electrum and connect it with your local node. Or you can do this manually:

```
electrum --oneserver --server ez:50001:t --skipmerklecheck
```

> If you don't have the [`ez` hostname](#-connecting-locally) set up, replace `ez` with the IP address shown on startup (`electrum-args` does this automatically). The [`skipmerklecheck`](https://github.com/spesmilo/electrum/pull/4957) option is needed to support pruning.

To configure Electrum to use eznode by default, run `docker exec ez electrum-cfg | bash -x`. This will issue `electrum setconfig` commands (you can run without `| bash` to see them).

If you're connecting remotely, you'll need to setup [Tor Onion or an SSH tunnel](#-connecting-remotely) for secure access.
</details>

#### Electrum wallet setup - with the BWT plugin
<details>
 <summary>Expand instructions...</summary><br>

You can setup Electrum desktop to connect with eznode using the [BWT Electrum plugin](https://github.com/bwt-dev/bwt-electrum-plugin).
The plugin will run a separate BWT instance that connects directly to Bitcoin Core and automatically detects your wallet(s) xpub(s).

[Open RPC access](#accessing-managed-full-node) to Bitcoin Core by setting `BITCOIND_RPC_ACCESS=<user:pwd>`, then follow the [instructions here](https://github.com/bwt-dev/bwt-electrum-plugin#installation) to setup the plugin.
</details>

#### Options
- `BWT=1` (enabled by default, set to `0` to turn off)
- `XPUB`/`XPUB_*` (xpubs/ypubs/zpubs to track)
- `DESCRIPTOR`/`DESCRIPTOR_*`/`DESC_*` (script descriptors to track)
- `RESCAN_SINCE=now` (date to begin rescanning for historical wallet transactions in `YYYY-MM-DD` format. rescan is disabled by default.)
- `BITCOIND_WALLET=ez-bwt` (bitcoind wallet to use)
- `CREATE_WALLET_IF_MISSING=1` (automatically create a new bitcoind wallet)
- `GAP_LIMIT=20` (the [gap limit](https://github.com/bwt-dev/bwt#gap-limit) for tracking derived addresses)
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
- `/data/track-addresses.txt` (optional file with standalone addresses to track)

## BTC RPC Explorer

[BTC RPC Explorer](https://github.com/janoside/btc-rpc-explorer) is a [block explorer](https://explorer.btc21.org/) and node dashboard with an [RPC console](https://explorer.btc21.org/rpc-browser?method=getblockheader), [statistics and graphs](https://explorer.btc21.org/block-stats), [status page](https://explorer.btc21.org/node-status), [peers overview](https://explorer.btc21.org/peers) and more.

Automatically connects with the BWT Electrum server, to enable exploration of your wallet addresses (but not of arbitrary addresses).

#### Pruning support

<details>
 <summary>Expand...</summary><br>

When pruning is enabled or if `txindex` is disabled (the default), some functionality will be limited:

- You will only be able to search for wallet, mempool and recently confirmed transactions by their `txid`.<br>
  Searching for non-wallet transactions that were confirmed over 3 blocks ago is only possible if you provide the confirmed block height in addition to the `txid`, using `<txid>@<height>` in the search box.
- Pruned blocks will display basic header information, without the list of transactions. Transactions in pruned blocks will not be available, unless they're wallet-related.
- The address and amount of previous transaction outputs will not be shown, only the `txid:vout`. 
- Mining fees will only be shown for unconfirmed transactions.

To enable full block explorer functionality, set `PRUNE=0 TXINDEX=1`.
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

Using Specter with USB hardware wallets requires [setting up udev rules](https://github.com/cryptoadvance/specter-desktop/tree/master/udev#udev-rules) on the host and starting docker with [`--device /dev/<usb-device-id>`](https://docs.docker.com/engine/reference/commandline/run/#add-host-device-to-container---device). If you're unsure what the device id is, you could also (less ideally) use [`--privileged -v /dev:/dev`](https://docs.docker.com/engine/reference/run/#runtime-privilege-and-linux-capabilities) to give the container full access to all host devices.

#### Options
- `SPECTER=0` (disabled by default, set to `1` to enable)
- `SPECTER_LOGS=0` (display spectr's logs in the `docker run` output)
- `AUTH_TOKEN=<none>` (sets the password for the admin account)

Additional configuration options are available through Specter's web interface.

#### Paths
- `/data/specter` (wallets, devices and other configuration)

#### Ports
- `25441`

## Tor

Tor anonymity network. For secure remote access using onion services and (optionally) for proxying bitcoind.

Onion services provide strong encryption and mutual authentication established based on information embedded into the `.onion` hostname. It does not require setting up port forwarding.

The onion service files, including secret key material, will be kept in `/data/tor-hsv`. If you lose them you'll lose your `.onion` address.

#### Setting up

Start with `TOR=1`. The `.onion` hostname will be shown on startup.

![](https://raw.githubusercontent.com/shesek/eee/master/docs/img/tor.png)

You'll be able to access your server through the `.onion` address from any client device with Tor installed, like the [Tor Browser](https://www.torproject.org/download/) for desktop or [Orbot](https://play.google.com/store/apps/details?id=org.torproject.android) for Android.


#### Non-anonymous mode

You can set `TOR_NONANONYMOUS=1` to use the [single-hop non-anonymous mode](https://2019.www.torproject.org/docs/tor-manual.html.en#HiddenServiceSingleHopMode). This will remove the 3 extra hops that protect the server's anonymity, making the connection faster and more reliable. Clients will remain anonymous. Note that this is [incompatible](https://gitlab.torproject.org/legacy/trac/-/issues/21284) with `BITCOIND_TOR`.

#### Options
- `TOR=0` (disabled by default, set to `1` to enable)
- `TOR_NONANONYMOUS=0` (enable non-anonymous mode)
- `TOR_CONFIG=<none>` (custom config to append to `torrc`)
- `TOR_LOGS=0` (display tor's logs in the `docker run` output)
- `BITCOIND_TOR=0` (connect to the bitcoin network through tor)
- `BITCOIND_RPC_ONION=0` (expose the bitcoind rpc port over onion)

#### Paths
- `/data/tor-hsv` (onion service files)

## Dropbear

Lightweight SSH server powered by [Dropbear](https://matt.ucc.asn.au/dropbear/dropbear.html). For secure remote access via SSH tunnels, using public-key based authentication.

A pair of client and server keys will be generated for you by default. The client's private key that can be used to login will be available in `/data/ssh-keys/client_rsa`.

If you already have a client key that you'd like to use, you can mount the pubkey file into `/root/id.pub` (e.g. `-v ~/.ssh/id_rsa.pub:/root/id.pub`), or mount an `authorized_keys` file into `/root/.ssh/authorized_keys`.

By default, the SSH server permits port tunneling only. Set `SSHD=UNRESTRICTED` to enable shell access, X11 forwarding, agent forwarding and remote port forwarding.


#### Server set-up

Enable `SSHD`, publish the SSH port (2222) for remote access and give the container an hostname (to make its virtual IP address easily discoverable from the client).

```bash
(server)$ docker run -p 2222:2222 --hostname ez -it ... eznode/eznode SSHD=1
```

![](https://raw.githubusercontent.com/shesek/eee/master/docs/img/ssh.png)


> You might need to open port `2222` on your firewall (e.g. `ufw allow to any port 2222`).

#### Client set-up

Copy the generated client key file from `~/eznode/ssh-keys/client_rsa` on the server to the client machine and setup an SSH tunnel:

```bash
(client)$ ssh -i ./client_rsa -fTN -L 50001:ez:50001 -p 2222 root@mynode.com
```

You will now be able to access the remote Electrum server through `localhost:50001` on the client.

> Protip: Use [`autossh`](https://medium.com/@gary4est/autossh-port-forwarding-23088d948787) to automatically restart dropped connections.

#### Android setup with ConnectBot

<details>
 <summary>Expand instructions...</summary><br>

You can setup an SSH tunnel from Android using the [ConnectBot](https://connectbot.org/) app. Install it and:

1. Transfer the generated `client_rsa` private key file to your phone, open the app, tap `⋮` > `Manage Pubkeys` > :open_file_folder: and load the key. Long-tap it and select `Load` and `Load on start`.

   > Alternatively, you can generate a key with ConnectBot and transfer the public key file to the server.

2. Go back to the main screen, tap `+` to add a new host, set the address to `root@mynodebox.com:2222`, untick `Start shell session`, tick `Stay connected` and save.

3. Long-tap the host, tap `Edit port forwards`, tap `+`, set `Source port` to the local port to bind on the phone (e.g. `50001`) and `Destination` to `ez:<port>` (e.g. `ez:50001`).

4. Tap the host to connect and verify the host's key fingerprint. Unfortunately, ConnectBot shows it in (the outdated and insecure) MD5, which you can get by setting `WEAK_SSH_CHECKSUM=1`.

You should now be able to access the remote services through `localhost` on your phone.

> ⚠️ Note that any app with the `INTERNET` permission will be able to access the local ports. To prevent malicious apps installed on your device from accessing the services, you'll need to enable authentication. BWT has [experimental support for Electrum authentication](https://github.com/bwt-dev/bwt/blob/master/doc/auth.md) that could be used.

</details>

#### Punch through NATs with a reverse SSH tunnel

If you're unable to directly accept incoming connections to your server, you can create a reverse tunnel to route traffic through a different server that can.

The server can be any cheap VPS. It doesn't need to run anything apart from an SSH server. It won't see anything apart from encrypted traffic and IP addresses. You will be safe from MITM attacks, as long as you verify the fingerprint the first time you connect.

<details>
 <summary>Expand instructions...</summary><br>

On the cheap VPS, edit `/etc/ssh/sshd_config`, add (assuming your username is `satoshi`):
```
Match User satoshi
  GatewayPorts clientspecified
```

And reload the SSH server (e.g. `service ssh reload`).

Then, on your eznode host, run:
```bash
ssh -fTN -R :2222:localhost:2222 satoshi@cheapvps.com
```

You will now be able to connect to the eznode SSH server through `cheapvps.com:2222`. You can setup SSH tunnels to the services through it in the same manner explained above.

> [localhost.run](https://localhost.run/) offers tunneling as a service for $3.5/month (the free tier isn't suitable because its HTTP-only). It's used with the standard `ssh` client and doesn't require any special software installation. It supports custom domain names.

</details>

#### Options
- `SSHD=0` (disabled by default, set to `1` or `UNRESTRICTED` to enable)
- `SSHD_LOGS=0` (display dropbear's logs in the `docker run` output)
- `DROPBEAR_OPTS=<none>` (custom CLI options for dropbear)

#### Paths
- `/root/id.pub` `/root/.ssh/authorized_keys` (mount from host to use existing client key)
- `/data/ssh-keys/client_rsa` (generated client key)
- `/data/ssh-keys/host_rsa` (generate host key)

#### Ports
- `2222`

## NGINX

NGINX-powered SSL terminating reverse proxy. Provides encryption, but not authentication. SSL relies on central authorities and is best avoided.

To setup, set `SSL=1`, publish the SSL port and make sure to enable authentication:

```bash
docker run -it -p 443:3443 ... eznode/eznode SSL=1 AUTH_TOKEN=mySecretPassword
```

A private key and a self-signed certificate will be automatically generated and saved to `/data/ssl-keys/selfsigned.{key,cert}`. See [*Let's Encrypt*](#lets-encrypt) below for a CA-signed cert.

The web services will be available on port `3443` under `/bwt/`, `/explorer/` and `/specter/`.

The *unauthenticated* Electrum SSL server will be available on port `50002`. It should *not* be exposed directly to the Internet and is meant to be used behind an authentication layer like SSH or Tor.

When `AUTH_TOKEN` is set, NGINX will be configured to authenticate the password before forwarding traffic to the backend web services. This helps protect against zero-day exploits.


#### Options
- `SSL=0` (disabled by default, set to `1` to enable)
- `AUTH_TOKEN=<none>` (setup `htpasswd`-based login enforced by nginx)

#### Paths
- `/data/ssl-keys/selfsigned.{key,cert}` (keys and certificates)

#### Ports
- `3443` (HTTPS)
- `8080` (HTTP)
- `50002` (Electrum RPC)

## Let's Encrypt

To obtain a CA-signed certificate from LetsEncrypt, set `SSL=1 SSL_DOMAIN=<domain>` and publish the HTTP/S ports for remote access, like so:

```bash
docker run -it -p 443:3443 -p 80:8080 ... eznode/eznode SSL=1 SSL_DOMAIN=mynodebox.com
```

> You might need to open the HTTP/S ports on your firewall (e.g. `ufw allow to any port 80,443`).


#### With existing webserver

<details>
 <summary>Expand instructions...</summary><br>

Verifying domain ownership for the LetsEncrypt certificate requires accepting connections on port `80`. If you already have a webserver occupying this port, you can configure it to forward verification requests on a subdomain to the ez webserver. Example with NGINX:

```
server {
    listen 80;
    server_name ez.mynodebox.com;
    location /.well-known/acme-challenge/ { proxy_pass http://localhost:8080; }
}
```

Then start docker with `-p 3443:3443 -p 127.0.0.1:8080:8080` and access the SSL server through `https://ez.mynodebox.com:3443/`.
</details>

#### Options
- `SSL_DOMAIN=<none>` (obtain CA-signed certificate for the given domain)
- `LETSENCRYPT_EMAIL=<none>` (for renewal and security notices, optional)
- `LETSENCRYPT_LOGS=0` (display letsencrypt’s logs in the `docker run` output)

#### Paths
- `/data/ssl-keys/letsencrypt` (keys and certificates)


# 🔧 Server management

To make things easier, setting the following aliases is recommended:

```bash
alias ez='docker exec ez'
alias bitcoin-cli='ez bitcoin-cli'
```

With these in place, you can use `bitcoin-cli` as you normally would and `ez <cmd>` to issue other commands on the container.

You can add the aliases to `~/.profile` to make them permanent. The instructions below assumes you have them set up.

To run an interactive command, use `docker exec` with `-it`. For example, `docker exec -it ez bash` to start a new shell.

To manage the server remotely, you can enable the [SSH service](#dropbear) with `SSHD=UNRESTRICTED`.

## 😈 Daemonizing

To run the docker container as a background daemon and have it automatically run on start-up, change `docker run` to use `-d --restart unless-stopped` instead of  `-it --rm`. For example:

```bash
docker run -d --restart unless-stopped --name ez -v ~/eznode:/data eznode/eznode
```

You can control the background container using `docker stop|start|restart ez`.

## 🕹️ Controlling services

eznode uses the (fantastic!) [`s6`](https://skarnet.org/software/s6/) init/supervision system (via [`s6-overlay`](https://github.com/just-containers/s6-overlay)) to manage services.

A [CLI utility](https://github.com/ez-org/eznode/blob/master/s6/service) wrapper written on top of the `s6` commands is provided to ease service management:

```bash
# Display an overview of all services
ez status

# Display more information
ez status -v

# Display the status of some service(s)
ez status <services...>

# Service management
ez start|stop|restart <services...>
```

<img src="https://raw.githubusercontent.com/shesek/eee/master/docs/img/services.png" width="550">


## 🖥️ Terminal display

You can setup a simple textual dashboard display with information about your node and the Bitcoin network using `watch -t -n10 docker exec ez banner`.

It will look something like this:

<img src="https://raw.githubusercontent.com/shesek/eee/master/docs/img/banner.png" width="550">

## 📝 Viewing logs

The main logs are displayed in the `docker run` output, including some select important log messages across all services. If you're running the container in the background, you can use `docker logs -f ez` to view them.

`ez logs` will stream full logs from all the services (`tail -f`-like). You can use `ez logs <services...>` to select specific services.

`-n` sets how many last log lines are returned initially (defaults to 8). `-c` reads the logs without following them. For example: `ez logs -c -n1000 bitcoind`.

You can request that some services will be logged in the main `docker run` output using the following flags: `BITCOIND_LOGS`, `BWT_LOGS`, `EXPLORER_LOGS`, `SPECTER_LOGS`, `TOR_LOGS`, `SSHD_LOGS` and `LETSENCRYPT_LOGS`.

## 🔄 Updating

To update your ezonde, run:

```bash
docker pull eznode/eznode
```

And re-start the `docker run` command.

## 💾 Backing up

All of the important directories that needs to be backed up are symlinked in `/important`. You can create a backup `tar.gz` file with everything using the following command:

```bash
ez backup > ez-backup.tar.gz
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
git clone https://github.com/ez-org/eznode && cd eznode
git checkout <tag>
git verify-commit HEAD

# Build
docker build -t eznode .

# Run using local image
docker run -it ... eznode ...
```

All the files retrieved during the build are verified by their hash.

To build the ARM32v7/ARM64v8 images, run `./docker/build-arch.sh [arm|arm64] -t eznode`. Cross-compilation requires [qemu-user-static](https://github.com/multiarch/qemu-user-static) to be installed.

You can upgrade third-party packages yourself by setting the following `--build-arg`s: `BITCOIND_{VERSION,SHA256}`, `BWT_{VERSION,SHA256}`, `BTCEXP_{VERSION,SHA256}` and `SPECTER_{VERSION,SHA256}`.

# 🔏 Signed images

Signed docker image digests are available in [`SHA256SUMS.asc`](https://github.com/ez-org/eznode/blob/master/SHA256SUMS.asc).

The images are signed by Nadav Ivgi (@shesek). The public key can be verified on the [PGP WoT](http://keys.gnupg.net/pks/lookup?op=vindex&fingerprint=on&search=0x81F6104CD0F150FC), [github](https://api.github.com/users/shesek/gpg_keys), [twitter](https://twitter.com/shesek), [keybase](https://keybase.io/nadav), [hacker news](https://news.ycombinator.com/user?id=nadaviv) and [this video presentation](https://youtu.be/SXJaN2T3M10?t=4).

```bash
# Verify signature
wget https://raw.githubusercontent.com/ez-org/eznode/latest/SHA256SUMS.asc
gpg --keyserver keyserver.ubuntu.com --recv-keys FCF19B67866562F08A43AAD681F6104CD0F150FC
gpg --verify SHA256SUMS.asc

# Get the signed hash for your platform
grep amd64 SHA256SUMS.asc

# Fetch docker image by hash and give it a local alias
docker pull eznode/eznode@sha256:<hash>
docker tag eznode/eznode@sha256:<hash> eznode

# Run using the local alias
docker run -it ... eznode ...
```
