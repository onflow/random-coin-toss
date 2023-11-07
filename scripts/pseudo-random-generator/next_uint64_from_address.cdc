import "Xorshift128plus"

pub fun main(prgAddress: Address): UInt64 {

    return getAccount(prgAddress).getCapability<&Xorshift128plus.PRG>(
            Xorshift128plus.PublicPath
        ).borrow()
        ?.nextUInt64()
        ?? panic("Could not find PRG at address")
}
