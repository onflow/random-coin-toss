import "FungibleToken"
import "FlowToken"

import "RandomBeaconHistory"
import "Xorshift128plus"

access(all) contract CoinToss {

    access(self) let reserve: @FlowToken.Vault

    access(all) let ReceiptStoragePath: StoragePath

    access(all) event CoinTossBet(betAmount: UFix64, commitBlock: UInt64, receiptID: UInt64)
    access(all) event CoinTossReveal(betAmount: UFix64, winningAmount: UFix64, commitBlock: UInt64, receiptID: UInt64)

    access(all) resource Receipt {
        access(all) let betAmount: UFix64
        access(all) let commitBlock: UInt64

        init(betAmount: UFix64) {
            self.betAmount = betAmount
            self.commitBlock = getCurrentBlock().height
        }
    }

    access(all) fun commitCoinToss(bet: @FungibleToken.Vault): @Receipt {
        let receipt <- create Receipt(
                betAmount: bet.balance
            )
        // commit the bet
        // `self.reserve` is a `@FungibleToken.Vault` field defined on the app contract
        //  and represents a pool of funds
        self.reserve.deposit(from: <-bet)
        
        emit CoinTossBet(betAmount: receipt.betAmount, commitBlock: receipt.commitBlock, receiptID: receipt.uuid)
        
        return <- receipt
    }

    access(all) fun revealCoinToss(receipt: @Receipt): @FungibleToken.Vault {
        pre {
            receipt.commitBlock <= getCurrentBlock().height: "Cannot reveal before commit block"
        }

        let betAmount = receipt.betAmount
        let commitBlock = receipt.commitBlock
        let receiptID = receipt.uuid
        let coin = self.randomCoin(atBlockHeight: receipt.commitBlock, salt: receipt.uuid)

        destroy receipt

        if coin == 1 {
            emit CoinTossReveal(betAmount: betAmount, winningAmount: 0.0, commitBlock: commitBlock, receiptID: receiptID)
            return <- FlowToken.createEmptyVault()
        }
        
        let reward <- self.reserve.withdraw(amount: betAmount * 2.0)
        
        emit CoinTossReveal(betAmount: betAmount, winningAmount: reward.balance, commitBlock: commitBlock, receiptID: receiptID)
        
        return <- reward
    }

    access(all) fun randomCoin(atBlockHeight: UInt64, salt: UInt64): UInt8 {
        // query the Random Beacon history core-contract.
        // if `blockHeight` is the current block height, `sourceOfRandomness` errors.
        let sourceOfRandomness = RandomBeaconHistory.sourceOfRandomness(atBlockHeight: atBlockHeight)
        assert(sourceOfRandomness.blockHeight == atBlockHeight, message: "RandomSource block height mismatch")

        // instantiate a PRG object, seeding a source of randomness with and `salt` and returns a pseudo-random
        // generator object.
        let prg = Xorshift128plus.PRG(
                sourceOfRandomness: sourceOfRandomness.value,
                salt: salt.toBigEndianBytes()
            )

        // derive a 64-bit random using the object `prg`
        let rand = prg.nextUInt64()
        
        return UInt8(rand & 1)
    }

    init() {
        self.reserve <- (FlowToken.createEmptyVault() as! @FlowToken.Vault)
        let seedVault = self.account.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)!
        self.reserve.deposit(
            from: <-seedVault.withdraw(amount: 1000.0)
        )
    
        self.ReceiptStoragePath = /storage/CoinTossReceipt
    }
}
