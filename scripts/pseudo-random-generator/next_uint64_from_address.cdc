import "PseudoRandomGenerator"

pub fun main(prgAddress: Address): UInt64 {

    return getAccount(prgAddress).getCapability<&PseudoRandomGenerator.PRG>(
            PseudoRandomGenerator.PublicPath
        ).borrow()
        ?.nextUInt64()
        ?? panic("Could not find PRG at address")
}
