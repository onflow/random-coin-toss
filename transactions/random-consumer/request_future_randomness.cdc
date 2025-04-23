import "RandomConsumer"

/// Requests randomness sourced at block height (>= current block height) via the RandomConsumer contract methods and
/// stores the returned Request resource at the specified StoragePath. The Request can then be fulfilled in the block
/// succeeding the committed block height.
///
/// @param blockHeight: The current or future block height where the random result should be sourced. If nil, current
///     block height is used
/// @param requestStoragePath: The StoragePath where the Request resource should be stored
///
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
