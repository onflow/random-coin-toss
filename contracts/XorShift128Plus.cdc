import Crypto

/// Defines a xorsift128+ pseudo random generator as a resource
///
access(all) contract XorShift128Plus {

    access(all) let StoragePath: StoragePath
    access(all) let PublicPath: PublicPath

    /// While not limited to 128 bits of state, this PRG is largely informed by XORShift128+
    ///
    access(all) resource PRG {

        // The states below are of type Word64 (instead of UInt64) to prevent overflow/underflow as state evolves
        //
        access(all) var state0: Word64
        access(all) var state1: Word64

        init(sourceOfRandomness: [UInt8]) {
            pre {
                sourceOfRandomness.length == 32: "Expecting 32 bytes as sourceOfRandomness"
            }
            // Convert the seed bytes to two Word64 values for state initialization
            let segment0: Word64 = XorShift128Plus.bigEndianBytesToWord64(bytes: sourceOfRandomness, start: 0)
            let segment1: Word64 = XorShift128Plus.bigEndianBytesToWord64(bytes: sourceOfRandomness, start: 8)
            let segment2: Word64 = XorShift128Plus.bigEndianBytesToWord64(bytes: sourceOfRandomness, start: 16)
            let segment3: Word64 = XorShift128Plus.bigEndianBytesToWord64(bytes: sourceOfRandomness, start: 24)

            self.state0 = segment0 ^ segment1
            self.state1 = segment2 ^ segment3
        }

        /// Advances the PRG state and generates the next UInt64 value
        /// See https://arxiv.org/pdf/1404.0390.pdf for implementation details and reasoning for triplet selection.
        /// Note that state only advances when this function is called from a transaction. Calls from within a script
        /// will not advance state and will return the same value.
        ///
        /// @return The next UInt64 value
        ///
        access(all) fun nextUInt64(): UInt64 {
            var a: Word64 = self.state0
            let b: Word64 = self.state1

            self.state0 = b
            a = a ^ (a << 23) // a
            a = a ^ (a >> 17) // b
            a = a ^ b ^ (b >> 26) // c
            self.state1 = a

            let randUInt64: UInt64 = UInt64(a + b)
            return randUInt64
        }
    }

    /// Helper function to convert an array of big endian bytes to Word64
    ///
    /// @param bytes: The bytes to convert
    /// @param start: The index of the first byte to convert
    ///
    /// @return The Word64 value
    ///
    access(contract) fun bigEndianBytesToWord64(bytes: [UInt8], start: Int): Word64 {
        pre {
            start + 8 < bytes.length: "At least 8 bytes from the start are required for conversion"
        }
        var value: UInt64 = 0
        var i: Int = 0
        while i < 8 {
            value = value << 8 | UInt64(bytes[start + i])
            i = i + 1
        }
        return Word64(value)
    }

    /// Creates a new XORSift128+ PRG with the given source of randomness and salt
    ///
    /// @param sourceOfRandomness: The 32 byte source of randomness used to seed the PRG
    /// @param salt: The bytes used to salt the source of randomness
    ///
    /// @return A new PRG resource
    access(all) fun createPRG(sourceOfRandomness: [UInt8], salt: [UInt8]): @PRG {
        let tmp: [UInt8] = sourceOfRandomness.concat(salt)
        // Hash is 32 bytes
        let hash: [UInt8] = Crypto.hash(tmp, algorithm: HashAlgorithm.SHA3_256)
        // Reduce the seed to 16 bytes
        let seed: [UInt8] = hash.slice(from: 0, upTo: 16)

        return <- create PRG(sourceOfRandomness: seed)
    }

    init() {
        self.StoragePath = StoragePath(identifier: "XorShift128PlusPRG_".concat(self.account.address.toString()))!
        self.PublicPath = PublicPath(identifier: "XorShift128PlusPRG_".concat(self.account.address.toString()))!
    }
}
