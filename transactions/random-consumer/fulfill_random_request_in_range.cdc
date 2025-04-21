import "RandomConsumer"

transaction(requestStoragePath: StoragePath, min: UInt64, max: UInt64) {
    let request: @RandomConsumer.Request

    prepare(signer: auth(BorrowValue, LoadValue) &Account) {
        self.request <- signer.storage.load<@RandomConsumer.Request>(from: requestStoragePath)
            ?? panic("Could not find pending randomness request in expected path \(requestStoragePath)")
    }

    execute {
        // can't return the result from a transaction, but the result will be emitted in the
        // RandomConsumer.RandomnessFulfilled event
        RandomConsumer.fulfillRandomRequestInRange(<-self.request, min: min, max: max)
    }
}