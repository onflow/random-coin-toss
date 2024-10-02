import "Burner"
import "FungibleToken"
import "FlowToken"

import "RandomConsumer"

/// CoinToss is a simple game contract showcasing the safe use of onchain randomness by way of a commit-reveal sheme.
///
/// See FLIP 123 for more details: https://github.com/onflow/flips/blob/main/protocol/20230728-commit-reveal.md
/// And the onflow/random-coin-toss repo for implementation context: https://github.com/onflow/random-coin-toss
///
/// NOTE: This contract is for demonstration purposes only and is not intended to be used in a production environment.
///
access(all) contract CoinToss {
    /// The multiplier used to calculate the winnings of a successful coin toss
    access(all) let multiplier: UFix64
    /// The Vault used by the contract to store funds.
    access(self) let reserve: @FlowToken.Vault
    /// The RandomConsumer.Consumer resource used to request & fulfill randomness
    access(self) let consumer: @RandomConsumer.Consumer

    /// The canonical path for common Receipt storage
    /// Note: production systems would consider handling path collisions
    access(all) let ReceiptStoragePath: StoragePath

    /* --- Events --- */
    //
    access(all) event CoinTossBet(betAmount: UFix64, commitBlock: UInt64, receiptID: UInt64)
    access(all) event CoinTossReveal(betAmount: UFix64, winningAmount: UFix64, commitBlock: UInt64, receiptID: UInt64)

    /// The Receipt resource is used to store the bet amount and the associated randomness request. By listing the
    /// RandomConsumer.RequestWrapper conformance, this resource inherits all the default implementations of the
    /// interface. This is why the Receipt resource has access to the getRequestBlock() and popRequest() functions
    /// without explicitly defining them.
    ///
    access(all) resource Receipt : RandomConsumer.RequestWrapper {
        /// The amount bet by the user
        access(all) let betAmount: UFix64
        /// The associated randomness request which contains the block height at which the request was made
        /// and whether the request has been fulfilled.
        access(all) var request: @RandomConsumer.Request?

        init(betAmount: UFix64, request: @RandomConsumer.Request) {
            self.betAmount = betAmount
            self.request <- request
        }
    }

    /* --- Commit --- */
    //
    /// In this method, the caller commits a bet. The contract takes note of the block height and bet amount, returning a
    /// Receipt resource which is used by the better to reveal the coin toss result and determine their winnings.
    ///
    access(all) fun commitCoinToss(bet: @{FungibleToken.Vault}): @Receipt {
        pre {
            bet.balance > 0.0:
            "Provided vault.balance=0.0 - must deposit a non-zero amount to commit to a coin toss"
            bet.getType() == Type<@FlowToken.Vault>():
            "Invalid vault type=".concat(bet.getType().identifier).concat(" - must provide a FLOW vault")
        }
        let request <- self.consumer.requestRandomness()
        let receipt <- create Receipt(
                betAmount: bet.balance,
                request: <-request
            )
        self.reserve.deposit(from: <-bet)

        emit CoinTossBet(betAmount: receipt.betAmount, commitBlock: receipt.getRequestBlock()!, receiptID: receipt.uuid)

        return <- receipt
    }

    /* --- Reveal --- */
    //
    /// Here the caller provides the Receipt given to them at commitment. The contract then "flips a coin" with
    /// _randomCoin(), providing the Receipt's contained Request.
    ///
    /// If result is 1, user loses, but if it's 0 the user doubles their bet. Note that the caller could condition the
    /// revealing transaction, but they've already provided their bet amount so there's no loss for the contract if
    /// they do.
    ///
    access(all) fun revealCoinToss(receipt: @Receipt): @{FungibleToken.Vault} {
        pre {
            receipt.request != nil: 
            "The provided receipt has already been revealed"
            receipt.getRequestBlock()! <= getCurrentBlock().height:
            "Provided receipt committed at block height=".concat(receipt.getRequestBlock()!.toString()).concat(
                " - must wait until at least the following block to reveal"
            )
        }
        let betAmount = receipt.betAmount
        let commitBlock = receipt.getRequestBlock()!
        let receiptID = receipt.uuid

        let coin = self._randomCoin(request: <-receipt.popRequest())

        Burner.burn(<-receipt)

        // Deposit the reward into a reward vault if the coin toss was won
        let reward <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
        if coin == 0 {
            let winningsAmount = betAmount * self.multiplier
            let winnings <- self.reserve.withdraw(amount: winningsAmount)
            reward.deposit(
                from: <-winnings
            )
        }

        emit CoinTossReveal(betAmount: betAmount, winningAmount: reward.balance, commitBlock: commitBlock, receiptID: receiptID)

        return <- reward
    }

    /// Returns a random number between 0 and 1 using the RandomConsumer.Consumer resource contained in the contract.
    ///
    access(self) fun _randomCoin(request: @RandomConsumer.Request): UInt8 {
        return self.consumer.fulfillRandomInRange(request: <-request, min: 0, max: 1) as! UInt8
    }

    init(multiplier: UFix64) {
        // Initialize the contract with a multiplier for the winnings
        self.multiplier = multiplier
        // Create a FlowToken.Vault to store the contract's funds
        self.reserve <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
        let seedVault = self.account.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(
                from: /storage/flowTokenVault
            )!
        self.reserve.deposit(
            from: <-seedVault.withdraw(amount: 1000.0)
        )
        // Create a RandomConsumer.Consumer resource
        self.consumer <-RandomConsumer.createConsumer()

        // Set the ReceiptStoragePath to a unique path for this contract - appending the address to the identifier
        // prevents storage collisions with other objects in user's storage
        self.ReceiptStoragePath = StoragePath(identifier: "CoinTossReceipt_".concat(self.account.address.toString()))!
    }
}
