import "Xorshift128plus"
import "RandomResultStorage"

/// This contract & transaction is intended for this project's statistical testing which needs persistent PRG state
/// across large numbers of random number generations.
///
/// Initializes the contracts PRG struct with the given source of randomness and salt.
///
transaction(sourceOfRandomness: [UInt8], salt: [UInt8]) {

    prepare(signer: auth(BorrowValue) &Account) {
        signer.storage.borrow<&RandomResultStorage.Admin>(from: RandomResultStorage.STORAGE_PATH)
            ?.initializePRG(sourceOfRandomness: sourceOfRandomness, salt: salt)
            ?? panic("Signer is not admin for RandomResultStorage!")
    }
}
