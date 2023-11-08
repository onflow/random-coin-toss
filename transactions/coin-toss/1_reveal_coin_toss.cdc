import "FlowToken"

import "CoinToss"

transaction {

    prepare(signer: AuthAccount) {
        // load my receipt from storage
        let receipt <- signer.load<@CoinToss.Receipt>(from: CoinToss.ReceiptStoragePath)
            ?? panic("No Receipt found!")

        // Reveal by redeeming my receipt
        let winnings <- CoinToss.revealCoinToss(receipt: <-receipt)

        if winnings.balance > 0.0 {
            let flowVault = signer.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)!
            // deposit winnings into my FlowToken Vault
            flowVault.deposit(from:<-winnings)
        } else {
            destroy winnings
        }
    }
}