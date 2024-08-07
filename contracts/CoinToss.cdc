import "FungibleToken"
import "FlowToken"

import "RandomBeaconHistory"
import "Xorshift128plus"

/// CoinToss is a simple game contract showcasing the safe use of onchain randomness by way of a commit-reveal sheme.
///
/// See FLIP 123 for more details: https://github.com/onflow/flips/blob/main/protocol/20230728-commit-reveal.md
/// And the onflow/random-coin-toss repo for implementation context: https://github.com/onflow/random-coin-toss
///
/// NOTE: This contract is for demonstration purposes only and is not intended to be used in a production environment.
///
access(all) contract CoinToss {

    /// The Vault used by the contract to store funds.
    access(self) let reserve: @FlowToken.Vault

    /// The canonical path for common Receipt storage
    /// Note: production systems would consider handling path collisions
    access(all) let ReceiptStoragePath: StoragePath

    /* --- Events --- */
    //
    access(all) event CoinTossBet(betAmount: UFix64, commitBlock: UInt64, receiptID: UInt64)
    access(all) event CoinTossReveal(betAmount: UFix64, winningAmount: UFix64, commitBlock: UInt64, receiptID: UInt64)

    /// The Receipt resource is used to store the bet amount and block height at which the bet was committed.
    ///
    access(all) resource Receipt {
        access(all) let betAmount: UFix64
        access(all) let commitBlock: UInt64

        init(betAmount: UFix64) {
            self.betAmount = betAmount
            self.commitBlock = getCurrentBlock().height
        }
    }

    /* --- Commit --- */
    //
    /// In this method, the caller commits a bet. The contract takes note of the block height and bet amount, returning a
    /// Receipt resource which is used by the better to reveal the coin toss result and determine their winnings.
    ///
    access(all) fun commitCoinToss(bet: @{FungibleToken.Vault}): @Receipt {
        pre {
            bet.balance > 0.0: "Bet amount must be greater than 0"
            bet.getType() == Type<@FlowToken.Vault>(): "Bet must be of type FlowToken.Vault"
        }
        let receipt <- create Receipt(
                betAmount: bet.balance
            )
        self.reserve.deposit(from: <-bet)

        emit CoinTossBet(betAmount: receipt.betAmount, commitBlock: receipt.commitBlock, receiptID: receipt.uuid)

        return <- receipt
    }

    /* --- Reveal --- */
    //
    /// Here the caller provides the Receipt given to them at commitment. The contract then "flips a coin" with
    /// randomCoin(), providing the committed block height and salting with the Receipts unique identifier.
    /// If result is 1, user loses, if it's 0 the user doubles their bet. Note that the caller could condition the
    /// revealing transaction, but they've already provided their bet amount so there's no loss for the contract if
    /// they do.
    ///
    access(all) fun revealCoinToss(receipt: @Receipt): @{FungibleToken.Vault} {
        pre {
            receipt.commitBlock <= getCurrentBlock().height: "Cannot reveal before commit block"
        }

        let betAmount = receipt.betAmount
        let commitBlock = receipt.commitBlock
        let receiptID = receipt.uuid

        // self.randomCoin() errors if commitBlock <= current block height in call to
        // RandomBeaconHistory.sourceOfRandomness()
        let coin = self.randomCoin(atBlockHeight: receipt.commitBlock, salt: receipt.uuid)

        destroy receipt

        if coin == 1 {
            emit CoinTossReveal(betAmount: betAmount, winningAmount: 0.0, commitBlock: commitBlock, receiptID: receiptID)
            return <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
        }

        let reward <- self.reserve.withdraw(amount: betAmount * 2.0)

        emit CoinTossReveal(betAmount: betAmount, winningAmount: reward.balance, commitBlock: commitBlock, receiptID: receiptID)

        return <- reward
    }

    /// Helper method using RandomBeaconHistory to retrieve a source of randomness for a specific block height and the
    /// given salt to instantiate a PRG object. A randomly generated UInt64 is then reduced by bitwise operation to
    /// UInt8 value of 1 or 0 and returned.
    ///
    access(all) fun randomCoin(atBlockHeight: UInt64, salt: UInt64): UInt8 {
        // query the Random Beacon history core-contract - if `blockHeight` <= current block height, panic & revert
        let sourceOfRandomness = RandomBeaconHistory.sourceOfRandomness(atBlockHeight: atBlockHeight)
        assert(sourceOfRandomness.blockHeight == atBlockHeight, message: "RandomSource block height mismatch")

        // instantiate a PRG object, seeding a source of randomness with `salt` and returns a pseudo-random
        // generator object.
        let prg = Xorshift128plus.PRG(
                sourceOfRandomness: sourceOfRandomness.value,
                salt: salt.toBigEndianBytes()
            )

        // derive a 64-bit random using the PRG object and reduce to a UInt8 value of 1 or 0
        let rand = prg.nextUInt64()

        return UInt8(rand & 1)
    }

    init() {
        self.reserve <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
        let seedVault = self.account.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(
                from: /storage/flowTokenVault
            )!
        self.reserve.deposit(
            from: <-seedVault.withdraw(amount: 1000.0)
        )

        self.ReceiptStoragePath = StoragePath(identifier: "CoinTossReceipt_".concat(self.account.address.toString()))!
    }
}
