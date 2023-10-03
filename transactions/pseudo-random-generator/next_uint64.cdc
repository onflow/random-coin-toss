import "PseudoRandomGenerator"

/// Saves and links a .PRG resource in the signer's storage and public namespace
///
transaction(generationLength: Int) {
    prepare(signer: AuthAccount) {
        if let prg = signer.borrow<&PseudoRandomGenerator.PRG>(from: PseudoRandomGenerator.StoragePath) {
            var i = 0
            while i < generationLength {
                prg.nextUInt64()
                i = i + 1
            }            
        }
    }
}