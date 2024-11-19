import "RandomConsumer"

transaction(storagePath: StoragePath) {
    prepare (signer: auth(BorrowValue, SaveValue) &Account) {
        if signer.storage.type(at: storagePath) != nil {
            panic("Object already stored in provided storage path")
        }
        let consumer = signer.storage.borrow<auth(RandomConsumer.Commit) &RandomConsumer.Consumer>(
                from: RandomConsumer.ConsumerStoragePath
            ) ?? panic("Consumer not found in storage")
        signer.storage.save(<-consumer.requestRandomness(), to: storagePath)
    }
}
