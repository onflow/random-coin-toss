import "Xorshift128plus"

/// NOTE: This contract is intended for testing purposes in order to store the results of random number generation
///
access(all) contract RandomResultStorage {

    access(all) let results: [UInt64]
    access(contract) var prg: Xorshift128plus.PRG?

    access(all) let STORAGE_PATH: StoragePath

    access(all) resource Admin {
        access(all) fun initializePRG(sourceOfRandomness: [UInt8], salt: [UInt8]) {
            pre {
                RandomResultStorage.prg == nil: "PRG has already been initialized!"
            }
            RandomResultStorage.prg = Xorshift128plus.PRG(sourceOfRandomness: sourceOfRandomness, salt: salt)
        }

        access(all) fun generateResults(length: Int) {
            pre {
                RandomResultStorage.prg != nil: "PRG has not been initialized!"
            }
            var i: Int = 0
            while i < length {
                RandomResultStorage.results.append(RandomResultStorage.prg!.nextUInt64())
                i = i + 1
            }
        }
    }

    init() {
        self.results = []
        self.prg = nil

        self.STORAGE_PATH = /storage/RandomResultStorageAdmin

        self.account.storage.save(<-create Admin(), to: self.STORAGE_PATH)
    }
}