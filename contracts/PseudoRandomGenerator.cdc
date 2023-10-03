access(all) contract PseudoRandomGenerator {

    access(all) let StoragePath: StoragePath
    access(all) let PublicPath: PublicPath

    access(all) resource PRG {
        access(all) let sourceOfRandomness: [UInt8]
        access(all) let salt: UInt64
        
        init(sourceOfRandomness: [UInt8], salt: UInt64) {
            self.sourceOfRandomness = sourceOfRandomness
            self.salt = salt
        }

        // TODO: replace unsafeRandom with PRG implementation
        access(all) fun nextUInt64(): UInt64 {
            return unsafeRandom()
        }
    }

    access(all) fun createPRG(sourceOfRandomness: [UInt8], salt: UInt64): @PRG {
        return <- create PRG(sourceOfRandomness: sourceOfRandomness, salt: salt)
    }

    init() {
        self.StoragePath = StoragePath(identifier: "PseudoRandomGenerator_".concat(self.account.address.toString()))!
        self.PublicPath = PublicPath(identifier: "PseudoRandomGenerator_".concat(self.account.address.toString()))!
    }
}