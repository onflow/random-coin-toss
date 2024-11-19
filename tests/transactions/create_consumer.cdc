import "RandomConsumer"

transaction {
    prepare (signer: auth(BorrowValue, SaveValue) &Account) {
        if signer.storage.type(at: RandomConsumer.ConsumerStoragePath) != nil {
            panic("Consumer already stored")
        }
        signer.storage.save(<-RandomConsumer.createConsumer(), to: RandomConsumer.ConsumerStoragePath)
    }
}
