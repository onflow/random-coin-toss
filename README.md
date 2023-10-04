# [WIP] Random Coin Toss

> :warning: This repo is still a work in progress - the underlying RandomBeaconHistory is also still a work in progress

## Overview

The contracts contained in this repo demonstrate how to use Flow's onchain randomness safely - safe randomness here
meaning non-revertible randomness.

Random sources are committed to the [`RandomBeaconHistory` contract](./contracts/RandomBeaconHistory.cdc) by the service
account at the end of every block. These random sources are catalogued chronologically, extending historically for every
associated block height to the initial commitment height.

Used on their own, these random sources are not safe. In other words, using the random source in your contract without
the framing of a commit-reveal mechanism would enable callers to condition their interactions with your contract on the
random result. In the context of a random coin toss, I could revert my transaction if I didn't win - not a very fair
game.

To achieve non-revertible randomness, the contract should be structured to resolve in two phases:

1. Commit - Caller commits to the resolution of their bet with some yet unknown source of randomness (i.e. in the
   future)
2. Reveal - Caller can then reveal the result of their bet

Though a caller could still condition the revealing transaction on the coin flip result, they've already incurred the
cost of their bet and would gain nothing by doing so.

## References

- [Secure Random Number Generator Forum Post](https://forum.onflow.org/t/secure-random-number-generator-for-flow-s-smart-contracts/5110)
- [RandomBeaconHistory PR - flow-core-contracts](https://github.com/onflow/flow-core-contracts/pull/375)
- [FLIP: On-Chain randomness history for commit-reveal schemes](https://github.com/onflow/flips/pull/123)