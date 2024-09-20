import "EVM"
import "FungibleToken"
import "FlowToken"

/// Configures a COA in the signer's Flow account, funding with the specified amount. If the COA already exists, the
/// transaction reverts.
///
transaction(amount: UFix64) {
    let coa: &EVM.CadenceOwnedAccount
    let sentVault: @FlowToken.Vault

    prepare(signer: auth(BorrowValue, IssueStorageCapabilityController, PublishCapability, SaveValue, UnpublishCapability) &Account) {
        let storagePath = /storage/evm
        let publicPath = /public/evm
        
        // Revert if the CadenceOwnedAccount already exists
        if signer.storage.type(at: storagePath) != nil {
            panic("Storage collision - Resource already stored at path=".concat(storagePath.toString()))
        }

        // Configure the CadenceOwnedAccount
        signer.storage.save<@EVM.CadenceOwnedAccount>(<-EVM.createCadenceOwnedAccount(), to: storagePath)
        let addressableCap = signer.capabilities.storage.issue<&EVM.CadenceOwnedAccount>(storagePath)
        signer.capabilities.unpublish(publicPath)
        signer.capabilities.publish(addressableCap, at: publicPath)

        // Reference the CadeceOwnedAccount
        self.coa = signer.storage.borrow<auth(EVM.Owner) &EVM.CadenceOwnedAccount>(from: /storage/evm)
            ?? panic("Missing or mis-typed CadenceOwnedAccount at /storage/evm")
     
        // Withdraw the amount from the signer's FlowToken vault
        let vaultRef = signer.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(
                from: /storage/flowTokenVault
            ) ?? panic("Could not borrow reference to the owner's Vault!")
        self.sentVault <- vaultRef.withdraw(amount: amount) as! @FlowToken.Vault
    }

    pre {
        self.sentVault.balance == amount:
        "Expected amount =".concat(amount.toString()).concat(" but sentVault.balance=").concat(self.sentVault.balance.toString())
    }

    execute {
        // Deposit the amount into the CadenceOwnedAccount if the balance is greater than zero
        if self.sentVault.balance > 0.0 {
            self.coa.deposit(from: <-self.sentVault)
        } else {
            destroy self.sentVault
        }
    }
}