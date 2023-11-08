import "FlowToken"

import "CoinToss"

/// Retrieves the saved Receipt and redeems it to reveal the coin toss result, depositing winnings with any luck
///
transaction {

    prepare(signer: AuthAccount) {
        // Load my receipt from storage
        let receipt <- signer.load<@CoinToss.Receipt>(from: CoinToss.ReceiptStoragePath)
            ?? panic("No Receipt found!")

        // Reveal by redeeming my receipt - fingers crossed!
        let winnings <- CoinToss.revealCoinToss(receipt: <-receipt)

        if winnings.balance > 0.0 {
            // Deposit winnings into my FlowToken Vault
            let flowVault = signer.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)!
            flowVault.deposit(from: <-winnings)
        } else {
            destroy winnings
        }
    }
}
