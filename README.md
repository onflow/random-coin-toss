# Random Coin Toss

While both are backed by Flow's Random Beacon,
it is important for developers to mindfully choose between `revertibleRandom`
or seeding their own PRNG utilizing the `RandomBeaconHistory` smart contract:

- Under the hood, the FVM also just instantiates a PRNG for each transaction that `revertibleRandom` draws from. 
  Though, with `revertibleRandom` a developer is calling the PRNG that is controlled by the transaction,
  which also has the power to abort and revert if it doesn't like `revertibleRandom`'s outputs.
  `revertibleRandom` is only suitable for smart contract functions that exclusively run within the trusted transactions.
- In contrast, using the `RandomBeaconHistory` means to use a deterministically-seeded PRNG. 
  The `RandomBeaconHistory` is key for effectively implementing a commit-and-reveal scheme.
  During the commit phase, the user commits to proceed with a future source of randomness,
  which is revealed after the commit transaction concluded.
  For each block, the `RandomBeaconHistory` automatically stores the subsequently generated source of randomness.

> 🚨 A transaction can atomically revert all its action during its runtime and abort.
> Therefore, it is possible for a transaction calling into your smart contract to post-select favorable
> results and revert the transaction for unfavorable results.
> 
> 💡 Post-selection - the ability for transactions to reject results they don't like - is inherent to any
> smart contract platform that allows transactions to roll back atomically. See this very similar
> [Ethereum example](https://consensys.github.io/smart-contract-best-practices/development-recommendations/general/public-data/).
> 
> ✅ Utilizing a commit-and-reveal scheme is important for developers to protect their smart contracts from transaction post-selection attacks.


Via a commit-and-reveal scheme, flow's native secure randomness can be safely used within Cadence smart contracts 
when contracts are transacted on by untrusted parties. 
By providing examples of commit-reveal implementations we hope to foster a more secure ecosystem of decentralized
applications and encourage developers to build with best practices.

## Commit-Reveal Scheme

The contracts contained in this repo demonstrate how to use Flow's onchain randomness safely
in contracts that are transacted on by untrusted parties. Safe randomness here meaning non-revertible randomness, 
i.e. mitigating post-selection attacks via a commit-and-reveal scheme.

Random sources are committed to the [`RandomBeaconHistory` contract](./contracts/RandomBeaconHistory.cdc) by the service
account at the end of every block. The RandomBeaconHistory contract provides a convenient archive, where for each past
block height (starting Nov 2023) the respective 'source of randomness' can be retrieved.

When used naively, `revertibleRandom` as well as the [`RandomBeaconHistory` contract](./contracts/RandomBeaconHistory.cdc)
are subject to post-selection attacks from transactions.
In simple terms, using the random source in your contract without
the protection of a commit-reveal mechanism would enable non-trusted callers to condition their interactions with your contract on the
random result. In the context of a random coin toss, I could revert my transaction if I didn't win - not a very fair
game.

To achieve non-revertible randomness, the contract should be structured to resolve in two phases:

1. Commit - Caller commits to the resolution of their bet with some yet unknown source of randomness (i.e. in the
   future)
2. Reveal - Caller can then resolve the result of their bet once the source of randomness is available in the `RandomBeaconHistory` with a separate transaction.
   From a technical perspective, this could also be called "resolving transaction", because the transaction simply executes the smart contract with the locked-in
   inputs, whose output all parties committed to accept in the previous phase.

Though a caller could still condition the revealing transaction on the coin flip result, all the inputs influencing the bet's outcome
have already been fixed (the source of randomness being the last one that is only generated after the commit transaction concluded).
Conceptually, this corresponds to owning a winning (or loosing) lottery ticket, where the numbers have already been published,
but the ticket has not been handed in to the lottery company to affirm the win (or loss).
All that the resolving transaction (reveal phase) is doing is affirming the win or loss.
The ticket owner could revert their resolving transaction. Though that does not change whether the ticket won or lost. Furthermore, the player has already
incurred the cost of their bet and gains nothing by reverting the reveal step.

## References

- [Secure Random Number Generator Forum Post](https://forum.onflow.org/t/secure-random-number-generator-for-flow-s-smart-contracts/5110)
- [RandomBeaconHistory PR - flow-core-contracts](https://github.com/onflow/flow-core-contracts/pull/375)
- [FLIP: On-Chain randomness history for commit-reveal schemes](https://github.com/onflow/flips/pull/123)