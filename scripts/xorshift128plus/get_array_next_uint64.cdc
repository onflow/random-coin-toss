import "Xorshift128plus"

/// Generates an arbitrary number of random numbers using the Xorshift128plus.PRG struct.
/// This script demonstrates how one would go about generating any number of random numbers using the 
/// example PRG implemented in Xorshift128plus.
///
/// Note that if the PRG were stored onchain, this script would not advance the state of the PRG
///
access(all) fun main(sourceOfRandomness: [UInt8], salt: [UInt8], generationLength: Int): [UInt64] {
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

    return randomNumbers
}
