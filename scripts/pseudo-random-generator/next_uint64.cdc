import "Xorshift128plus"

pub fun main(seed: [UInt8], salt: UInt64): UInt64 {

    let prg = Xorshift128plus.PRG(sourceOfRandomness: seed, salt: salt)
    
    let randUInt64 = prg.nextUInt64()
    
    return randUInt64
}
