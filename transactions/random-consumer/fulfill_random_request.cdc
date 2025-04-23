import "RandomConsumer"

/// Fulfills a random Request (loaded from the provided StoragePath) with a random number up to UInt64.max
/// Although the result cannot be returned from a transaction, users could reference the emitted 
/// RandomConsumer.RandomnessFulfilled event for the result.
///
/// @param requestStoragePath: The StoragePath from which the Request resource should be loaded
///
transaction(requestStoragePath: StoragePath) {
    let request: @RandomConsumer.Request

    prepare(signer: auth(BorrowValue, LoadValue) &Account) {
        self.request <- signer.storage.load<@RandomConsumer.Request>(from: requestStoragePath)
            ?? panic("Could not find pending randomness request in expected path \(requestStoragePath)")
    }

    execute {
        // can't return the result from a transaction, but the result will be emitted in the
        // RandomConsumer.RandomnessFulfilled event
        RandomConsumer.fulfillRandomRequest(<-self.request)
    }
}
