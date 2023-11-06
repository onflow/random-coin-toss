import "XorShift128Plus"

/// Advances the XorShift128Plus.PRG state and generates a random number. Since values cannot be returned from
/// transactions, a caller would need to have queried the PRG with prg.getNextUInt64() before running this transaction
/// to retrieve the number that will be generated. 
///
transaction {
    prepare(signer: AuthAccount) {
        signer.borrow<&XorShift128Plus.PRG>(from: XorShift128Plus.StoragePath)
            ?.nextUInt64()
            ?? panic("No PRG found in signer's storage")
    }
}
