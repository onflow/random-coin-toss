import "RandomConsumer"

access(all)
fun main(address: Address, storagePath: StoragePath): Bool {
    return getAuthAccount<auth(BorrowValue) &Account>(address).storage
        .borrow<&RandomConsumer.Request>(
            from: storagePath
        )?.canFullfill()
        ?? panic("No Request found")
}
