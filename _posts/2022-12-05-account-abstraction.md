---
layout: post
title:  "Notes on Account abstraction"
date:   2022-12-05 16:08:31 +0530
is_post: True
---

I did a little exploration of Account abstraction for a project in ETH-India 2022. We called it zephyr wallet. This post covers some interesting research and resources on Account abstraction.

First and foremost here are some of the most important standards most important on the topic at the time of writing.


- [EIP-4337: Account Abstraction using alt mempool](https://eips.ethereum.org/EIPS/eip-4337)
- [EIP-1271: Standard Signature Validation Method for Contracts](https://eips.ethereum.org/EIPS/eip-1271)
- [EIP-2470: Singleton Factory](https://eips.ethereum.org/EIPS/eip-2470)

some previous developments and discussions

[Implementing account abstraction as part of eth1.x](https://ethereum-magicians.org/t/implementing-account-abstraction-as-part-of-eth1-x/4020)

[Tradeoffs in Account Abstraction Proposals](https://ethresear.ch/t/tradeoffs-in-account-abstraction-proposals/263)

[Benefits of Account Abstraction](https://hackmd.io/y7uhNbeuSziYn1bbSXt4ww?view)


## So what is it anyways?
Account abstraction is the abstraction of the authentication logic of a transaction and nonce checking from an account.

Currently, transactions are authenticated via ECDSA signatures. Since smart contracts don’t have a private key, as the public address we see is not based on an elliptic curve, they cannot provide a signature. And cannot initiate a transaction. Account abstraction can use other cryptographic authentication schemes like multi-sig, BLS, etc., to validate a transaction

Since validation is not dependent on Elliptic curve keypair and can be anything as long as it can be verified on EVM. It opens up a plethora of cool features and extensions to the current mundane system.



- UX can be a lot better
- Social recovery 
- Access Management
- Session keys
- Gas payment sponsorships

With AA we can have accounts that are smart contracts and the verification is just a function `_validateSignature`e which takes some parameters including the signature of the cryptographic scheme account is using.

Since accounts are now smart contracts arbitrary logic can be coded at different steps including the step where gas is paid and the actual call is made.

## EIP-4337 implementation

EIP-4337 implements account abstraction by having a different mem-pool. Here are the rough steps of how it is done: 

* user submits an ABI-encoded struct called `UserOperation` or `UserOp` for short in the alt mem pool which has the following details

<img src="/images/posts/2022-12-05/user_op.png" />

* This mempool is operated by the existing nodes or a new class of operators called `bundlers`. They form the bundles of `UserOp` transactions and send them to the mem-pool for inclusion in the blockchain

* Every `UserOp` is processed by a special smart contract called `Entry Point` which is responsible for authentications, execution of the operation and giving out gas rewards to the bundler.

* gas fees are typically collected from the `sender` address after validating `signature`. `sender` is the smart contract wallet


## Let's talk about how the accounts are created in the first place

Since these accounts are smart contracts and smart contract creation requires gas fees which is deducted from the account balance. How can a bundler take gas fees from the account that is being created and is essentially empty?

The answer to that is in deterministic addresses using EIP-2470. Cutting it short, you load up some balance in the address which can be calculated using

```javascript
address(keccak256(bytes1(0xff), 0xce0042B868300000d44A59004Da54A005ffdcf9f, _salt, keccak256(_code)) << 96)
```

more details in the eip referenced above. You can calculate the address before sending the `UserOp` to initialize the wallet and set it as the sender with the init code for initialization params.


## Zephyr wallet

With Zephyr, we wanted to create a wallet keeping security features as the top priority.

Zephyr wallet had features like
- dead man switch
- social recovery
- session management
- access controls

The aim was to create a wallet where with more granular access controls

- You can provide partial access to some wallets to trade on an AMM Swap on your behalf for a certain period of time

- After the dead man switch is activated, the new owner should not be able to impersonate the user completely

- custom rules for session keys

**customized security startegies**

a social check before every transaction which can be customized as per the user

[zephyr contracts](https://github.com/ethCadets/secure-wallet-contracts)

Not all of it was implemented as there was a time limit.


## Resources

- [eth-infinitism github with implementations of core contracts required in AA, bundler to realay UserOp and a client side sdk to create UserOps ](https://github.com/eth-infinitism/)

- [Ethereum Foundation's video on ERC-4337](https://www.youtube.com/watch?v=xHWlJiL_iZA)

- [Unpacking ERC4337](https://frontier.tech/unpacking-erc-4337)

- [Soul Wallet protocol](https://github.com/proofofsoulprotocol)

- [porton wallet](https://github.com/nanjiangwill/porton-wallet)







