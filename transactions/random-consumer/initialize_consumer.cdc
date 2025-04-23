import "RandomConsumer"

transaction {
    prepare(signer: &Account) {}

    execute {
        RandomConsumer.initializeConsumer()
    }
}