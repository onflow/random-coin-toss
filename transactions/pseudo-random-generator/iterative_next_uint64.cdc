import "Xorshift128plus"

/// Generates an arbitrary number of random numbers using the Xorshift128plus.PRG struct.
/// While the values generated in this transaction are not used or stored, this transaction demonstrates how one would
/// go about generating any number of random numbers using the Xorshift128plus.PRG. If desired, the generated numbers
/// could be stored in some resource or used in a transaction.
///
/// Note that since transactions are mutating, calls to `nextUInt64` will advance the PRG state.
///
transaction(sourceOfRandomness: [UInt8], salt: [UInt8], generationLength: Int) {

    prepare(signer: AuthAccount) {
        let prg = Xorshift128plus.PRG(
                sourceOfRandomness: sourceOfRandomness,
                salt: salt
            )

        var i: Int = 0
        let randomNumbers: [UInt64] = []
        // Generate the desired number of random numbers
        while i < generationLength {
            prg.nextUInt64()
            i = i + 1
            randomNumbers.append(prg.nextUInt64())
        }

        // Can then continue using array of random numbers for your use case...
    }
}
