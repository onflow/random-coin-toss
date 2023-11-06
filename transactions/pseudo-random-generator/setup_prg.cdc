import "XorShift128Plus"

/// Saves and links a .PRG resource in the signer's storage and public namespace
///
transaction(seed: [UInt8], salt: UInt64) {
    prepare(signer: AuthAccount) {
        if signer.type(at: XorShift128Plus.StoragePath) != nil {
            return
        }
        signer.save(
             <- XorShift128Plus.createPRG(
                sourceOfRandomness: seed,
                salt: salt
            ),
            to: XorShift128Plus.StoragePath
        )
        signer.link<&XorShift128Plus.PRG>(
            XorShift128Plus.PublicPath,
            target: XorShift128Plus.StoragePath
        )
    }
}