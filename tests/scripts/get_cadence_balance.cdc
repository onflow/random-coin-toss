import "FlowToken"

access(all)
fun main(address: Address): UFix64 {
    return getAuthAccount<auth(BorrowValue) &Account>(address)
        .storage
        .borrow<&FlowToken.Vault>(
            from: /storage/flowTokenVault
        )!.balance
}
