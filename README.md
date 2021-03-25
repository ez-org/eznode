![eznode](https://raw.githubusercontent.com/ez-org/eznode/master/docs/img/header.png)

# 𝚎𝚣𝚗𝚘𝚍𝚎

[![Build Status](https://travis-ci.org/ez-org/eznode.svg?branch=master)](https://travis-ci.org/ez-org/eznode)
[![Latest release](https://img.shields.io/github/v/tag/ez-org/eznode?label=version&color=orange)](https://github.com/ez-org/eznode/releases/latest)
[![Docker pulls](https://img.shields.io/docker/pulls/eznode/eznode.svg?color=blueviolet)](https://hub.docker.com/r/eznode/eznode)
[![MIT license](https://img.shields.io/github/license/ez-org/eznode.svg?color=yellow)](https://github.com/ez-org/eznode/blob/master/LICENSE)
[![Chat on Telegram](https://img.shields.io/badge/chat-on%20telegram-blue)](https://t.me/ez_node)
[![Chat on IRC](https://img.shields.io/badge/chat-on%20IRC-green.svg)](https://webchat.freenode.net/#eznode)

Docker-based single-container package featuring:

* **Bitcoin Core:** Pruned by default with optional *trusted* fast-sync
* **Electrum Server:** Personal Electrum server powered by BWT
* **BTC RPC Explorer:** Personal block explorer and node dashboard
* **Specter Desktop:** Wallet GUI for hardware and multi-sig setups
* **Secure remote access** using Tor Onion SSH tunnels or SSL

Why eznode?

* Simple one command setup
* Lightweight (120 MB docker image)
* Pruning-friendly (requires <5GB of storage)
* Suitable for a dedicated box, but doesn't require one
* Supports Linux, macOS, Windows and ARMv7/v8

Support development: [⚡ lightning or ⛓️ on-chain via BTCPay](https://btcpay.shesek.info/)

Website: [ezno.de](https://ezno.de)

## 🚀 Quickstart

[Install Docker](https://docs.docker.com/get-docker/) (the only dependency) and start eznode with the data directory mounted to `/data`:

```bash
docker run -it --rm --name ez -v ~/eznode:/data eznode/eznode TOR=1 XPUB=<xpub>
```

This will setup a pruned Bitcoin Core full node, a personal Electrum server tracking your `<xpub>`, a block explorer and a Tor onion service for secure remote access. All the information you need for accessing them will be shown on startup.

You can skip setting an `XPUB` if you're not using the [Electrum server](https://ezno.de/packages#bitcoin-wallet-tracker).

Change `~/eznode` if you'd like to store the node's data files elsewhere. On Windows, you can use `$env:AppData\eznode` to store them in `C:\Users\<USER>\AppData\Roaming`. They require \~4.8GB of free space.

On Windows/macOS, you'll need to [publish the ports with `-p`](https://ezno.de/accessing#connecting-locally) to access them locally.

Set `TRUSTED_FASTSYNC=1` to enable the [_trusted_ fast-sync](https://ezno.de/packages#fast-sync) mode. You should carefully consider the implications and avoid this if possible.

To enable Specter Desktop, set `SPECTER=1`.

To experiment on signet, set `NETWORK=signet`.

Signature verification instructions [are available here](https://ezno.de/signed-images).

## 📙 User Guide

The full user guide is available at https://ezno.de.

- [⭐ Getting started](https://ezno.de/getting-started)
- [👩‍💻 Accessing the services](https://ezno.de/accessing)
- [🎁 Packages](https://ezno.de/packages)
- [🛡️ Secure transports](https://ezno.de/transports)
- [🔧 Node management](https://ezno.de/node-management)
- [🔏 Signed images](https://ezno.de/signed-images)
- [🏗️ Building locally](https://ezno.de/building)

## ❤️ Contributing

Contributions are welcome!

eznode manages services using the (fantastic!) [`s6`](https://skarnet.org/software/s6/) init/supervision system (via [`s6-overlay`](https://github.com/just-containers/s6-overlay)). Refer to [`specter`](https://github.com/ez-org/eznode/tree/master/specter) for an example of a simple service package and to the s6 docs for more information on writing services.

## 📃 License

MIT
