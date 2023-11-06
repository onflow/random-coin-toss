import "XorShift128Plus"

/// Saves and links a .PRG resource in the signer's storage and public namespace
///
transaction(generationLength: Int) {
    prepare(signer: AuthAccount) {
        if let prg = signer.borrow<&XorShift128Plus.PRG>(from: XorShift128Plus.StoragePath) {
            var i = 0
            while i < generationLength {
                prg.nextUInt64()
                i = i + 1
            }            
        }
    }
}