import "FungibleToken"
import "FlowToken"

import "CoinToss"

/// Commits the defined amount of Flow as a bet to the CoinToss contract, saving the returned Receipt to storage
///
transaction(betAmount: UFix64) {

    prepare(signer: auth(BorrowValue, SaveValue) &Account) {
        // Withdraw my bet amount from my FlowToken vault
        let flowVault = signer.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(from: /storage/flowTokenVault)!
        let bet <- flowVault.withdraw(amount: betAmount)
        
        // Commit my bet and get a receipt
        let receipt <- CoinToss.flipCoin(bet: <-bet)
        
        // Check that I don't already have a receipt stored
        if signer.storage.type(at: CoinToss.ReceiptStoragePath) != nil {
            panic("Storage collision at path=".concat(CoinToss.ReceiptStoragePath.toString()).concat(" a Receipt is already stored!"))
        }

        // Save that receipt to my storage
        // Note: production systems would consider handling path collisions
        signer.storage.save(<-receipt, to: CoinToss.ReceiptStoragePath)
    }
}
