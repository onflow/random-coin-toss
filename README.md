# Random Coin Toss

> :information_source: This repository contains demonstrations for safe usage of Flow's protocol-native secure randomness in both Cadence and Solidity smart contracts.

On Flow, there are two routes to get a random value. While both are backed by Flow's Random Beacon,
it is important for developers to mindfully choose between `revertibleRandom`
or seeding their own PRNG utilizing the `RandomBeaconHistory` smart contract:

- When using `revertibleRandom` a developer is relying on randomness generation controlled by the transaction,
  which also has the power to abort and revert based on `revertibleRandom`'s outputs. Therefore,
  `revertibleRandom` is only suitable for smart contract functions that exclusively run within credibly-neutral transactions which a developer can trust won't revert based on undesirable random outputs.
- In contrast, using the `RandomBeaconHistory` allows developers to use a committed random source (or seed) that can't be reverted. 
  The `RandomBeaconHistory` is key for effectively implementing a commit-and-reveal scheme which is itself a pattern that prevents users from gaming a transaction based on the result of randomness.
  During the commit phase, the user commits to proceed with a **future** source of randomness
  which is revealed after the commit transaction concludes.
  For each block, the `RandomBeaconHistory` automatically stores the subsequently generated source of randomness in the final transaction of that block. This source of randomness is committed by Flow's protocol service account.

> 🚨 A transaction can atomically revert the entirety of its action based on results exposed within the scope of that transaction.
> Therefore, it is possible for a transaction calling into your smart contract to post-select favorable
> results and revert the transaction for unfavorable results.
> 
> 💡 Post-selection - the ability for transactions to reject results they don't like - is inherent to any
> smart contract platform that allows transactions to roll back atomically. See this very similar
> [Ethereum example](https://consensys.github.io/smart-contract-best-practices/development-recommendations/general/public-data/).
> 
> ✅ Utilizing a commit-and-reveal scheme is important for developers to protect their smart contracts from transaction post-selection attacks.

Via a commit-and-reveal scheme, Flow's protocol-native secure randomness can be safely used within both Cadence and Solidity smart contracts 
when contracts are transacted on by untrusted parties. 
By providing examples of commit-reveal implementations we hope to foster a more secure ecosystem of decentralized
applications and encourage developers to build with best practices.

## Commit-Reveal Scheme

The contracts contained in this repo demonstrate how to use Flow's onchain randomness safely
in contracts that are transacted on by untrusted parties. Safe randomness here meaning non-revertible randomness, 
i.e. mitigating post-selection attacks via a commit-and-reveal scheme.

Random sources are committed to the [`RandomBeaconHistory` contract](https://github.com/onflow/flow-core-contracts/blob/master/contracts/RandomBeaconHistory.cdc) by the service
account at the end of every block. The RandomBeaconHistory contract provides a convenient archive, where for each past
block height (starting Nov 2023) the respective 'source of randomness' can be retrieved.

When used naively, `revertibleRandom` as well as the [`RandomBeaconHistory` contract](https://github.com/onflow/flow-core-contracts/blob/master/contracts/RandomBeaconHistory.cdc)
are subject to post-selection attacks from transactions.
In simple terms, using the random source in your contract without
the protection of a commit-reveal mechanism would enable non-trusted callers to condition their interactions with your contract on the
random result. In the context of a random coin toss, I could revert my transaction if I didn't win - not a very fair
game.

To achieve non-revertible randomness, the contract should be structured to resolve in two phases:

1. **Commit** - Caller commits to the resolution of their bet with some yet unknown source of randomness (i.e. in the
  future)
2. **Reveal** - Caller can then resolve the result of their bet once the source of randomness is available in the `RandomBeaconHistory` with a separate transaction.
  From a technical perspective, this could also be called a "resolving transaction", because the transaction simply executes the smart contract with the locked-in
  inputs, whose output all parties committed to accept in the previous phase.

Though a caller could still condition the revealing transaction on the coin flip result, all the inputs influencing the bet's outcome
have already been fixed (the source of randomness being the last one that is only generated after the commit transaction concluded).
Conceptually, this corresponds to owning a winning (or loosing) lottery ticket, where the numbers have already been published,
but the ticket has not been handed in to the lottery company to affirm the win (or loss).
All that the resolving transaction (reveal phase) is doing is affirming the win or loss.
The ticket owner could revert their resolving transaction. Though that does not change whether the ticket won or lost. Furthermore, the player has already
incurred the cost of their bet and gains nothing by reverting the reveal step.

Given that Flow has both Cadence and EVM runtimes, commit-reveal patterns covering Cadence and Solidity are found in this repo as well as transactions demonstrating how Flow accounts can interact with EVM implementations from the Cadence runtime via COAs.

## Deployments

|Contract|Testnet|Mainnet|
|---|---|---|
|[CoinToss.cdc](./contracts/CoinToss.cdc)|[0xd1299e755e8be5e7](https://contractbrowser.com/A.d1299e755e8be5e7.CoinToss)|N/A|
|[Xorshift128plus.cdc](./contracts/Xorshift128plus.cdc)|[0xed24dbe901028c5c](https://contractbrowser.com/A.ed24dbe901028c5c.Xorshift128plus)|[0x45caec600164c9e6](https://contractbrowser.com/A.45caec600164c9e6.Xorshift128plus)|
|[CoinToss.sol](./contracts/CoinToss.sol)|[0x959922bE3CAee4b8Cd9a407cc3ac1C251C2007B1](https://evm-testnet.flowscan.io/address/0x959922bE3CAee4b8Cd9a407cc3ac1C251C2007B1?tab=contract_code)|N/A|

> :information_source: To use the Solidity dependencies demonstrated in the `CoinToss.sol` example, see the [`@onflow/flow-sol-utils` repository](https://github.com/onflow/flow-sol-utils).

## Further Reading


- We recommend the **Flow developer documentation** [**_Advanced Concepts → Flow VRF_**](https://developers.flow.com/build/advanced-concepts/randomness)
  for important concepts and context on safely using Flow's VRF.  
- Flow Forum post [_Secure random number generator for Flow’s smart contracts_](https://forum.onflow.org/t/secure-random-number-generator-for-flow-s-smart-contracts/5110)
  summarizes the weaknesses of prevalent approaches to random number generation in other blockchains (such as using block hashes) and explains the details behind Flow's secure solution.
- [Pull request introducing the `RandomBeaconHistory` system smart contract.](https://github.com/onflow/flow-core-contracts/pull/375) 
- [FLIP 123: _On-Chain randomness history for commit-reveal schemes_](https://github.com/onflow/flips/pull/123) describes the need for a commit-and-reveal scheme and 
  discusses ideas for additional convenience functionality to further optimize the developer experience in the future.
- For more on Cadence Arch pre-compiles and accessing random values from EVM on Flow, see documentation on the [Cadence Arch precompiled contracts](https://developers.flow.com/evm/how-it-works#precompiled-contracts).
