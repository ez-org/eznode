![eznode](https://raw.githubusercontent.com/shesek/eee/master/docs/img/header.png)

# 𝚎𝚣𝚗𝚘𝚍𝚎

[![Build Status](https://travis-ci.org/shesek/eee.svg?branch=master)](https://travis-ci.org/shesek/eee)
[![Latest release](https://img.shields.io/github/v/tag/shesek/eee?label=version&color=orange)](https://github.com/ez-org/eznode/releases/latest)
[![Docker pulls](https://img.shields.io/docker/pulls/eznode/eznode.svg?color=blueviolet)](https://hub.docker.com/r/eznode/eznode)
[![MIT license](https://img.shields.io/github/license/bwt-dev/bwt.svg?color=yellow)](https://github.com/ez-org/eznode/blob/master/LICENSE)
[![Chat on Telegram](https://img.shields.io/badge/chat-on%20telegram-blue)](https://t.me/ez_node)
[![Chat on IRC](https://img.shields.io/badge/chat-on%20IRC-green.svg)](https://webchat.freenode.net/#eznode)


A simple single-container docker setup for a personal bitcoin full node. Featuring:

- **Bitcoin Core:** Pruned by default with optional (trusted) fast-sync
- **Electrum Server**: Personal Electrum server powered by BWT
- **BTC RPC Explorer:** Personal block explorer and node dashboard
- **Specter Desktop:** Wallet GUI for hardware and multi-sig setups
- **Secure remote access** using Tor Onion, SSH tunnels or SSL

Why eznode?

- Simple, hassle-free setup
- Lightweight (a single 115 MB docker image)
- Pruning-friendly (requires <5GB of storage)
- Suitable for a dedicated box, but doesn't require one
- Supports Linux, macOS, Windows and ARMv7/v8

Support development: [⚡ lightning or ⛓️ on-chain via BTCPay](https://btcpay.shesek.info/)

## 🚀 Quickstart

[Install Docker](https://docs.docker.com/get-docker/) (the only dependency) and start eznode with the data directory mounted to `/data`:
```bash
docker run -it --rm --name ez -v ~/eznode:/data eznode/eznode TOR=1 XPUB=<xpub>
```

This will setup a pruned Bitcoin Core full node, an Electrum server tracking your `<xpub>`, a block explorer and a Tor onion service for secure remote access. All the information you need for accessing them will be shown on startup.

Change `~/eznode` if you'd like to store the node's data files elsewhere. On Windows, you can use `$env:AppData\eznode` to store them in `C:\Users\<USER>\AppData\Roaming`. They require ~4.8GB of free space.

On Windows/macOS, you'll need to [publish the ports with `-p`](docs#-connecting-locally).

Set `TRUSTED_FASTSYNC=1` to enable the [*trusted* fast-sync](docs#fast-sync) mode. You should carefully consider the implications and avoid this if possible.

To enable Specter Desktop, set `SPECTER=1`.

To experiment on signet, set `NETWORK=signet`.

## 📙 User Guide
 
- [✂️ Pruning](docs#%EF%B8%8F-pruning)
- [⚙️ Configuration](docs#%EF%B8%8F-configuration)
- [👩‍💻 Accessing the services](docs#-accessing-the-services)
  - [💻 Locally](docs#-connecting-locally)
  - [🌐 Remotely](docs#-connecting-remotely)
  - [🔐 Authentication](docs#-authentication)
- [🎁 Packages](docs#-packages)
  - [Bitcoin Core](docs#bitcoin-core) &middot; [BWT/Electrum](docs#bitcoin-wallet-tracker) &middot; [RPC Explorer](docs#btc-rpc-explorer) &middot; [Specter](docs#specter-desktop)
  - [Tor Onion](docs#tor) &middot; [Dropbear/SSH](docs#dropbear) &middot; [NGINX/SSL](docs#nginx) &middot; [Let's Encrypt](docs#lets-encrypt)
- [🔧 Server management](docs#-server-management)
  - [😈 Daemonizing](docs#-daemonizing)
  - [🕹️ Controlling services](docs#%EF%B8%8F-controlling-services)
  - [🖥️ Terminal display](docs#%EF%B8%8F-terminal-display)
  - [📝 Viewing logs](docs#-viewing-logs)
  - [🔄 Updating](docs#-updating)
  - [💾 Backing up](docs#-backing-up)
- [🏗️ Building locally](docs#%EF%B8%8F-building-locally)
- [🔏 Signed images](docs#-signed-images)

## 📃 License

MIT
