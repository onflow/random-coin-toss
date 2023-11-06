import "XorShift128Plus"

/// Generates an arbitrary number of random numbers using the XorShift128Plus.PRG saved in signer's storage.
/// While the values generated in this transaction are not used or stored, this transaction demonstrates how one would
/// go about generating any number of random numbers using the XorShift128Plus.PRG. If desired, the generated numbers
/// could be stored in some resource or
///
transaction(generationLength: Int) {

    prepare(signer: AuthAccount) {
        // Get the XorShift128Plus.PRG from signer's storage
        if let prg = signer.borrow<&XorShift128Plus.PRG>(from: XorShift128Plus.StoragePath) {
            var i = 0
            // Generate the desired number of random numbers
            while i < generationLength {
                prg.nextUInt64()
                i = i + 1
            }
        }
    }
}
