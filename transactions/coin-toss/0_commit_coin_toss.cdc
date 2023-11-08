import "FlowToken"

import "CoinToss"

transaction(betAmount: UFix64) {

    prepare(signer: AuthAccount) {
        // Withdraw my bet amount from my FlowToken vault
        let flowVault = signer.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)!
        let bet <- flowVault.withdraw(amount: betAmount)
        
        // Commit my bet and get a receipt
        let receipt <- CoinToss.commitCoinToss(bet: <-bet)
        
        // Check that I don't already have a receipt stored
        if signer.type(at: CoinToss.ReceiptStoragePath) != nil {
            panic("You already have a receipt stored!")
        }

        // Save that receipt to my storage
        signer.save(<-receipt, to: CoinToss.ReceiptStoragePath)
    }
}