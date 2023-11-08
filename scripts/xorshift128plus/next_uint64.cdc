import "Xorshift128plus"

/// Returns a random number from a Xorshift128plus.PRG struct constructed from the given seed and salt.
///
/// Note that if the PRG were stored onchain, this script would not advance the state of the PRG
///
pub fun main(sourceOfRandomness: [UInt8], salt: [UInt8]): UInt64 {
    return Xorshift128plus.PRG(sourceOfRandomness: sourceOfRandomness, salt: salt).nextUInt64()
}
