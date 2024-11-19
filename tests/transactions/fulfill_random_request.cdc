import "RandomConsumer"

transaction(storagePath: StoragePath) {
    let consumer: auth(RandomConsumer.Reveal) &RandomConsumer.Consumer
    let request: @RandomConsumer.Request
    
    prepare (signer: auth(BorrowValue, LoadValue) &Account) {
        self.consumer = signer.storage.borrow<auth(RandomConsumer.Reveal) &RandomConsumer.Consumer>(
                from: RandomConsumer.ConsumerStoragePath
            ) ?? panic("Consumer not found in storage")
        self.request <- signer.storage.load<@RandomConsumer.Request>(from: storagePath)
            ?? panic("No Request found at provided storage path")
    }

    execute {
        let rand = self.consumer.fulfillRandomRequest(<-self.request)
    }
}
