import "Xorshift128plus"

/// Generates an arbitrary number of random numbers using the Xorshift128plus.PRG struct.
/// While the values generated in this transaction are not used or stored, this transaction demonstrates how one would
/// go about generating any number of random numbers using the Xorshift128plus.PRG. If desired, the generated numbers
/// could be stored in some resource or
///
access(all) fun main(sourceOfRandomness: [UInt8], salt: [UInt8], generationLength: Int): [UInt64] {
    let prg = Xorshift128plus.PRG(
            sourceOfRandomness: sourceOfRandomness.value,
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
