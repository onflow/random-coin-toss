import "PseudoRandomGenerator"

/// Saves and links a .PRG resource in the signer's storage and public namespace
///
transaction(seed: [UInt8], salt: UInt64) {
    prepare(signer: AuthAccount) {
        if signer.type(at: PseudoRandomGenerator.StoragePath) != nil {
            return
        }
        signer.save(
             <- PseudoRandomGenerator.createPRG(
                sourceOfRandomness: seed,
                salt: salt
            ),
            to: PseudoRandomGenerator.StoragePath
        )
        signer.link<&PseudoRandomGenerator.PRG>(
            PseudoRandomGenerator.PublicPath,
            target: PseudoRandomGenerator.StoragePath
        )
    }
}