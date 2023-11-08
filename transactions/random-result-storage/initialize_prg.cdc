import "Xorshift128plus"
import "RandomResultStorage"

/// This transaction is intended for project's statistical testing.
/// Initializes the contracts PRG struct with the given source of randomness and salt.
///
transaction(sourceOfRandomness: [UInt8], salt: [UInt8]) {

    prepare(signer: AuthAccount) {
        signer.borrow<&RandomResultStorage.Admin>(from: RandomResultStorage.STORAGE_PATH)
            ?.initializePRG(sourceOfRandomness: sourceOfRandomness, salt: salt)
            ?? panic("Signer is not admin for RandomResultStorage!")
    }
}
