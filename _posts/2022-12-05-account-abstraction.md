---
layout: post
title:  "Account abstraction"
date:   2022-12-05 16:08:31 +0530
---

I did a little exploration on Account abstraction for a project in EthIndia 2022. We called it zephyr wallet. This post covers some of interesting research and resources on Account abstraction.

First and foremost here are the two of the most important standards most important on the topic at the time of writing.

- [EIP-4337: Account Abstraction using alt mempool](https://eips.ethereum.org/EIPS/eip-4337)
- [EIP-1271: Standard Signature Validation Method for Contracts](https://eips.ethereum.org/EIPS/eip-1271)
- [EIP-2470: Singleton Factory](https://eips.ethereum.org/EIPS/eip-2470)

some previous developments and discussions

[Implementing account abstraction as part of eth1.x](https://ethereum-magicians.org/t/implementing-account-abstraction-as-part-of-eth1-x/4020)

[Tradeoffs in Account Abstraction Proposals](https://ethresear.ch/t/tradeoffs-in-account-abstraction-proposals/263)

[Benefits of Account Abstraction](https://hackmd.io/y7uhNbeuSziYn1bbSXt4ww?view)


## So what is it anyways?
Account abstraction is the abstraction of the authentication logic of a transaction and nonce checking from an account. 

Currently transactions are authenticated via ECDSA signatures and since smart contracts doesn't have a private key, as the public address we see is not based on a elliptic curve, they cannot provide a signature. And cannot initiate a transaction. Account abstraction is to use other cryptographic authentication schemes like multi-sig, BLS etc for validating a transaction.

Since validation is not dependent on Elliptic curve keypair and can be anything as long as it can be verified on EVM. It opens up plethora of cool features and extension to current mundane system.

- UX can be a lot better
- Social recovery and parital access to accounts need not be centralized anymore
- session keys
- gas payment sponsorships

With AA we can have accounts that are smart contracts and the verification is just a function `_validateSignature` which takes some parameters including signature of the cryptographic scheme account is using. 

Since accounts are now smart contracts arbitrary logic can be coded at different steps including the step where gas is paid and actual call is made.

## EIP-4337 implementation

EIP-4337 implements account abstraction by having a different mem-pool. Here are the rough steps of how it is done in simple language

* user submits an ABI-encoded struct called `UserOperation` or `UserOp` for short in the alt mem pool which has the following details

<img src="/images/posts/2022-12-05/user_op.png" />

* This mempool is operator by the existing nodes or a new class of operators called `bundlers`. They form the bundles of user operations and send them to the mem-pool for inclusion in the blockchain

* Every UserOp is processed by a special smart contract called `Entry Point` which is responsible for authentications, execution of the operation and giving out gas rewards to the bundler

* gas fees are typically collected from the `sender` address after validating `signature`. `sender` is the smart contract wallet

Okay that's it for today. Rest later. 

