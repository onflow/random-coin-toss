import "RandomConsumer"

transaction(blockHeight: UInt64?, requestStoragePath: StoragePath) {

    prepare(signer: auth(BorrowValue, SaveValue) &Account) {
        let storedType = signer.storage.type(at: requestStoragePath)
        assert(storedType == nil,
            message: "Storage collision at \(requestStoragePath) - try to store the new Request at an unused path")

        signer.storage.save(
            <-RandomConsumer.requestFutureRandomness(at: blockHeight ?? getCurrentBlock().height),
            to: requestStoragePath
        )
    }
}
