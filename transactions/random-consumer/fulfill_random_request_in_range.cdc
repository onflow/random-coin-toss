import "RandomConsumer"

/// Fulfills a random Request (loaded from the provided StoragePath) with a random number in the inclusive range.
/// Although the result cannot be returned from a transaction, users could reference the emitted 
/// RandomConsumer.RandomnessFulfilled event for the result.
///
/// @param requestStoragePath: The StoragePath from which the Request resource should be loaded
/// @param min: The inclusive minimum of the random result range
/// @param max: The inclusive maximum of the random result range
///
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