---
layout: post
title:  "OZ's ethernaut challenges"
date:   2023-01-05 16:08:31 +0530
---

Exploits and explanations of [damnvulnerabledefi](https://www.damnvulnerabledefi.xyz/) solutions as of January 2023.

P.S. Do not expect detailed description. You can most probably find articles with in-depth details out there somwhere.


## unstoppable

Goal is to stop the `UnstoppableLender` lending tokens. Attacker initially has some tokens as well. Looking at the lender's contract, we can see the only way to get a loan is via `flashLoan`. 

In the function there are multiple require checks but the main issue is with the assert `assert(poolBalance == balanceBefore);` because the `balanceBefore` can be manipulated from an external transfer of tokens while `poolBalance` can only be changed via `deposit`. And asserting equality leads to the exploit.

Attacker simply transfer some tokens to the contract which will increase the `balanceBefore` (as it checks the balance from the token contract) but `poolBalance` wont be updated

```javascript
token = this.token.connect(attacker)
await token.transfer(this.pool.address, INITIAL_ATTACKER_TOKEN_BALANCE);
```

---