import "FungibleToken"
import "FlowToken"

import "EVM"

/// Deposits $FLOW to the provided EVM address from the signer's FlowToken Vault
///
transaction(toHex: String, amount: UFix64) {
    let recipient: EVM.EVMAddress
    let preBalance: UFix64
    let signerVault: auth(FungibleToken.Withdraw) &FlowToken.Vault

    prepare(signer: auth(BorrowValue) &Account) {
        // Parse the recipient's address
        self.recipient = EVM.addressFromString(toHex)
        // Note the pre-transfer balance
        self.preBalance = self.recipient.balance().inFLOW()
    
        // Reference the signer's FlowToken Vault
        self.signerVault = signer.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(from: /storage/flowTokenVault)
            ?? panic("Could not borrow reference to the owner's vault")
    }

    execute {
        // Withdraw tokens from the signer's vault
        let fromVault <- self.signerVault.withdraw(amount: amount) as! @FlowToken.Vault
        // Deposit tokens into the COA
        self.recipient.deposit(from: <-fromVault)
    }

    post {
        self.recipient.balance().inFLOW() == self.preBalance + amount: "Error executing transfer!"
    }
}
