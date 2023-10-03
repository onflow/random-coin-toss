import "PseudoRandomGenerator"

pub fun main(seed: [UInt8], salt: UInt64): UInt64 {

    let prg <- PseudoRandomGenerator.createPRG(sourceOfRandomness: seed, salt: salt)
    
    let randUInt64 = prg.nextUInt64()
    
    destroy prg
    
    return randUInt64
}
