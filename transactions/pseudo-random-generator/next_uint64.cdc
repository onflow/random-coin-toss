import "PseudoRandomGenerator"

/// For demonstration - generates the given number of random numbers
/// These values might be passed to a consuming contract or resource
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