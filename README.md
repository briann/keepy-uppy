# Keepy Uppy

![gif of keepy uppy from the show bluey](https://c.tenor.com/StwF5iZoussAAAAd/tenor.gif)

Keepy Uppy is a **toy** smart contract inspired by the ubiquitous game you might have played as a kid, and as illustrated by the wonderful kids show Bluey (S01E03).

⚠️ **This is a toy smart contract meant for playing with Solidity & smart contracts. Do not use for anything else.**

## Overview

The idea of the game is to keep the balloon in the air and prevent it from touching the ground. In real life, you do this by bumping the balloon into the air - preferably towards hard-to-reach places if you're playing with others so they have to vault over furniture to keep the balloon in the air. In our smart contract, we'll "bump" the balloon by calling a function. 

Bumping the balloon in our smart contract requires currency to be paid to the contract in the function call (e.g., gwei for Ethereum). While in real life you can fine-tune the strength and direction of your balloon bump-age, in our smart contract we'll just simulate strength of the balloon bump by the amount of currency provided.

Currently, the game is single-player played by the owner of the contract. We'll extend this to be multi-player later.

## How to play

### Game flow
1. Deploy contract.
1. Bump the balloon, provide currency. You'll be told how long the balloon will be in the air before you have to bump it again. Note that this is in block time.
1. Two possible outcomes:
    1. Bump the balloon again: repeat.
    1. Fail to bump the balloon within the time limit - you lose all the gwei sent to the contract.

### Deploying

```shell
$ forge script script/KeepyUppy.s.sol:KeepyUppyScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Contract API

TBD

## Developing

### Install prerequisites

This project assumes you have Rust and Foundry installed on your host. If you don't have those:

```shell
# Install Rust
$ curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Install Foundry if you don't have it
$ curl -L https://foundry.paradigm.xyz | bash
```

### Building

```shell
$ forge build
```

### Running tests

```shell
$ forge test
```

### Formatting

```shell
$ forge fmt
```

## Why?

As mentioned in the header, this is a toy contract for the purposes of exploring Solidity, smart contracts, etc.. There are a few things we want to get out of building this:
1. **Smart contract development basics**: writing Solidity, deploying a contract, etc - all the things you get from doing the basics.
1. **Multi-party interaction**: most contracts are multi-player games, in a way. This is explicitly a game that can be played by multiple actors.
1. **Multiple chains**: we'll use this as an avenue to explore deploying to multiple L1/L2 chains, possibly with communication between them.
1. **Contract optimization**: The contract logic here should be simple enough that we can play with some smart contract optimization.