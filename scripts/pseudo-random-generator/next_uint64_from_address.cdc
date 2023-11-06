import "XorShift128Plus"

pub fun main(prgAddress: Address): UInt64 {

    return getAccount(prgAddress).getCapability<&XorShift128Plus.PRG>(
            XorShift128Plus.PublicPath
        ).borrow()
        ?.nextUInt64()
        ?? panic("Could not find PRG at address")
}
