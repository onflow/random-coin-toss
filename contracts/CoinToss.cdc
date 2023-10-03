import "FlowToken"
import "RandomBeaconHistory"
import "PseudoRandomGenerator"

access(all) contract CoinToss {

    access(self) let reserve: @FlowToken.Vault

    access(self) let ReceiptStoragePath: StoragePath

    access(all) resource Receipt {
        access(all) let betAmount: UFix64
        access(all) let commitBlock: UInt64

        init(betAmount: UFix64) {
            self.betAmount = betAmount
            self.commitBlock = getCurrentBlock().height
        }
    }

    // PRG implementation is not provided by the FLIP, we assume this contract
    // imports a suitable PRG implementation

    access(all) fun commitCointoss(bet: @FlowToken.Vault): @Receipt {
        let receipt <- create Receipt(
                betAmount: bet.balance
            )
        // commit the bet
        // `self.reserve` is a `@FlowToken.Vault` field defined on the app contract
        //  and represents a pool of funds
        self.reserve.deposit(from: <-bet)
        return <- receipt
    }

    access(all) fun revealCointoss(receipt: @Receipt): @FlowToken.Vault {
        let currentBlock = getCurrentBlock().height
        if receipt.commitBlock >= currentBlock {
            panic("cannot reveal yet")
        }

        let winnings = receipt.betAmount * 2.0
        let coin = self.randomCoin(atBlockHeight: receipt.commitBlock, salt: receipt.uuid)
        destroy receipt

        if coin == 1 {
            return <- (FlowToken.createEmptyVault() as! @FlowToken.Vault)
        }

        return <- (self.reserve.withdraw(amount: winnings) as! @FlowToken.Vault)
    }

    access(all) fun randomCoin(atBlockHeight: UInt64, salt: UInt64): UInt8 {
        // query the Random Beacon history core-contract.
        // if `blockHeight` is the current block height, `sourceOfRandomness` errors.
        let sourceOfRandomness = RandomBeaconHistory.sourceOfRandomness(atBlockHeight: atBlockHeight)
        assert(sourceOfRandomness.blockHeight == atBlockHeight, message: "RandomSource block height mismatch")

        // instantiate a PRG object using external `createPRG` that takes a `seed` 
        // and `salt` and returns a pseudo-random-generator object.
        let prg <- PseudoRandomGenerator.createPRG(
                sourceOfRandomness: sourceOfRandomness.value,
                salt: salt
            )

        // derive a 64-bit random using the object `prg`
        let rand = prg.nextUInt64()
        destroy prg
        
        return UInt8(rand & 1)
    }

    init() {
        self.reserve <- (FlowToken.createEmptyVault() as! @FlowToken.Vault)
        let seedVault = self.account.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)!
        self.reserve.deposit(
            from: <-seedVault.withdraw(amount: 100.0)
        )
    
        self.ReceiptStoragePath = /storage/CoinTossReceipt
    }
}
