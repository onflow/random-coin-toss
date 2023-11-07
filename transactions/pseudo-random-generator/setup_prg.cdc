import "Xorshift128plus"

/// Saves and links a .PRG resource in the signer's storage and public namespace
///
transaction(seed: [UInt8], salt: UInt64) {
    prepare(signer: AuthAccount) {
        if signer.type(at: Xorshift128plus.StoragePath) != nil {
            return
        }
        signer.save(
             <- Xorshift128plus.createPRG(
                sourceOfRandomness: seed,
                salt: salt
            ),
            to: Xorshift128plus.StoragePath
        )
        signer.link<&Xorshift128plus.PRG>(
            Xorshift128plus.PublicPath,
            target: Xorshift128plus.StoragePath
        )
    }
}