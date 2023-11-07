import "Xorshift128plus"

/// Returns a random number from a Xorshift128plus.PRG struct constructed from the given seed and salt.
///
pub fun main(seed: [UInt8], salt: UInt64): UInt64 {
    return Xorshift128plus.PRG(sourceOfRandomness: seed, salt: salt).nextUInt64()
}
