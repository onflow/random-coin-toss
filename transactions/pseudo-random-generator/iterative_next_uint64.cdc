import "Xorshift128plus"

/// Generates an arbitrary number of random numbers using the Xorshift128plus.PRG saved in signer's storage.
/// While the values generated in this transaction are not used or stored, this transaction demonstrates how one would
/// go about generating any number of random numbers using the Xorshift128plus.PRG. If desired, the generated numbers
/// could be stored in some resource or
///
transaction(generationLength: Int) {

    prepare(signer: AuthAccount) {
        // Get the Xorshift128plus.PRG from signer's storage
        if let prg = signer.borrow<&Xorshift128plus.PRG>(from: Xorshift128plus.StoragePath) {
            var i = 0
            // Generate the desired number of random numbers
            while i < generationLength {
                prg.nextUInt64()
                i = i + 1
            }
        }
    }
}
