import "Burner"

import "RandomBeaconHistory"
import "Xorshift128plus"

/// This contract is intended to make it easy to consume randomness securely from the Flow protocol's random beacon. It provides
/// a simple construct to commit to a request, and reveal the randomness in a secure manner as well as helper functions to
/// generate random numbers in a range without bias.
///
/// See an example implementation in the repository: https://github.com/onflow/random-coin-toss
///
access(all) contract RandomConsumer {

    /* --- PATHS --- */
    //
    /// Canonical path for Consumer storage
    access(all) let ConsumerStoragePath: StoragePath

    /* --- EVENTS --- */
    //
    access(all) event RandomnessRequested(requestUUID: UInt64, block: UInt64)
    access(all) event RandomnessSourced(requestUUID: UInt64, block: UInt64, randomSource: [UInt8])
    access(all) event RandomnessFulfilled(requestUUID: UInt64, randomResult: UInt64)

    ///////////////////
    // PUBLIC FUNCTIONS
    ///////////////////

    /// Retrieves a revertible random number in the range [min, max]
    ///
    /// @param min: The minimum value of the range
    /// @param max: The maximum value of the range
    ///
    /// @return A random number in the range [min, max]
    ///
    access(all) fun getRevertibleRandomInRange(min: UInt64, max: UInt64): UInt64 {
        return revertibleRandom<UInt64>(modulo: max - min + 1)
    }

    /// Retrieves a random number in the range [min, max] using the provided PRG to source additional randomness if
    /// needed
    ///
    /// @param prg: The PRG to use for random number generation
    /// @param min: The minimum value of the range
    /// @param max: The maximum value of the range
    ///
    /// @return A random number in the range [min, max]
    ///
    access(all) fun getNumberInRange(prg: Xorshift128plus.PRG, min: UInt64, max: UInt64): UInt64 {
        pre {
            min < max:
                "Provided min of ".concat(min.toString()).concat(" and max of ".concat(max.toString())
                .concat(" - min must be less than max"))
        }
        let range = max - min // Calculate the inclusive range of the random number
        let bitsRequired = UInt256(self._mostSignificantBit(range)) // Number of bits needed to cover the range
        let mask: UInt256 = (1 << bitsRequired) - 1 // Create a bitmask to extract relevant bits

        let shiftLimit: UInt256 = 256 / bitsRequired // Number of shifts needed to cover 256 bits
        var shifts: UInt256 = 0 // Initialize shift counter

        var candidate: UInt64 = 0 // Initialize candidate
        var value: UInt256 = prg.nextUInt256() // Assign the first 256 bits of randomness

        while true {
            candidate = UInt64(value & mask) // Apply the bitmask to extract bits
            if candidate <= range {
                break
            }

            // Shift by the number of bits covered by the mask
            value = value >> bitsRequired
            shifts = shifts + 1

            // Get a new value if we've exhausted the current one
            if shifts == shiftLimit {
                value = prg.nextUInt256()
                shifts = 0
            }
        }
        
        // Scale candidate to the range [min, max]
        return min + candidate
    }
    
    /// Returns a new Consumer resource
    ///
    /// @return A Consumer resource
    ///
    access(all) fun createConsumer(): @Consumer {
        return <-create Consumer()
    }

    ///////////////////
    // CONSTRUCTS
    ///////////////////

    access(all) entitlement Commit
    access(all) entitlement Reveal

    /// Interface to allow for a Request to be contained within another resource. The existing default implementations
    /// enable an implementing resource to simple list the conformance without any additional implementation aside from
    /// the nested Request resource. However, implementations should properly consider the optional type when 
    /// interacting with the Request resource outside of the default implementations. The post-conditions ensure that
    /// implementations cannot act dishonestly even if they override the default implementations.
    ///
    access(all) resource interface RequestWrapper {
        /// The Request contained within the resource
        access(all) var request: @Request?

        /// Returns the block height of the Request contained within the resource
        ///
        /// @return The block height of the Request or nil if no Request is contained
        ///
        access(all) view fun getRequestBlock(): UInt64? {
            post {
                result == nil || result! == self.request?.block:
                "RequestWrapper.getRequestBlock() must return nil or the block height of RequestWrapper.request"
            }
            return self.request?.block ?? nil
        }

        /// Returns whether the Request contained within the resource can be fulfilled or not
        ///
        /// @return Whether the Request can be fulfilled
        ///
        access(all) view fun canFullfillRequest(): Bool {
            post {
                result == self.request?.canFullfill() ?? false:
                "RequestWrapper.canFullfillRequest() must return the result of RequestWrapper.request.canFullfill()"
            }
            return self.request?.canFullfill() ?? false
        }

        /// Pops the Request from the resource and returns it
        ///
        /// @return The Request that was contained within the resource
        ///
        access(Reveal) fun popRequest(): @Request {
            pre {
                self.request != nil: "RequestWrapper.request must not be nil before popRequest"
            }
            post {
                self.request == nil:
                "RequestWrapper.request must be nil after popRequest"
                result.uuid == before((self.request?.uuid)!):
                "RequestWrapper.request.uuid must match result.uuid"
            }
            let req <- self.request <- nil
            return <- req!
        }
    }

    /// A resource representing a request for randomness
    ///
    access(all) resource Request {
        /// The block height at which the request was made
        access(all) let block: UInt64
        /// Whether the request has been fulfilled
        access(all) var fulfilled: Bool

        init() {
            self.block = getCurrentBlock().height
            self.fulfilled = false
        }

        access(all) view fun canFullfill(): Bool {
            return !self.fulfilled && self.block < getCurrentBlock().height
        }

        /// Returns the Flow's random source for the requested block height
        ///
        /// @return The random source for the requested block height containing at least 16 bytes (128 bits) of entropy
        ///
        access(contract) fun _fulfill(): [UInt8] {
            pre {
                !self.fulfilled:
                "Request has already been fulfilled"
                self.block < getCurrentBlock().height:
                "Attempting to fulfill random request before the eligible block height of "
                .concat((self.block + 1).toString())
            }
            self.fulfilled = true
            let res = RandomBeaconHistory.sourceOfRandomness(atBlockHeight: self.block).value

            emit RandomnessSourced(requestUUID: self.uuid, block: self.block, randomSource: res)

            return res
        }
    }

    /// This resource enables the easy implementation of secure randomness, implementing the commit-reveal pattern and
    /// using a PRG to generate random numbers from the protocol's random source.
    ///
    access(all) resource Consumer {

        /* ----- COMMIT STEP ----- */
        //
        /// Requests randomness, returning a Request resource
        ///
        /// @return A Request resource
        ///
        access(Commit) fun requestRandomness(): @Request {
            let req <-create Request()
            emit RandomnessRequested(requestUUID: req.uuid, block: req.block)
            return <-req
        }

        /* ----- REVEAL STEP ----- */
        //
        /// Fulfills a random request, returning a random number
        ///
        /// @param request: The Request to fulfill
        ///
        /// @return A random number
        ///
        access(Reveal) fun fulfillRandomRequest(_ request: @Request): UInt64 {
            let reqUUID = request.uuid

            // Create PRG from the provided request & generate a random number
            let prg = self._getPRGFromRequest(request: <-request)
            let res = prg.nextUInt64()

            emit RandomnessFulfilled(requestUUID: reqUUID, randomResult: res)
            return res
        }

        /// Fulfills a random request, returning a random number in the range [min, max]
        ///
        /// @param request: The Request to fulfill
        /// @param min: The minimum value of the range
        /// @param max: The maximum value of the range
        ///
        /// @return A random number in the range [min, max]
        ///
        access(Reveal) fun fulfillRandomInRange(request: @Request, min: UInt64, max: UInt64): UInt64 {
            pre {
                min < max:
                "Provided min of ".concat(min.toString()).concat(" and max of ".concat(max.toString())
                .concat(" - min must be less than max"))
            }
            let reqUUID = request.uuid
            
            // Create PRG from the provided request & generate a random number & generate a random number in the range
            let prg = self._getPRGFromRequest(request: <-request)
            let res = RandomConsumer.getNumberInRange(prg: prg, min: min, max: max)

            emit RandomnessFulfilled(requestUUID: reqUUID, randomResult: res)

            return res
        }

        /* --- INTERNAL --- */
        //
        /// Creates a PRG from a Request, using the request's block height source of randomness and UUID as a salt
        ///
        /// @param request: The Request to use for PRG creation
        ///
        /// @return A PRG object
        ///
        access(self) fun _getPRGFromRequest(request: @Request): Xorshift128plus.PRG {
            let source = request._fulfill()
            let salt = request.uuid.toBigEndianBytes()
            Burner.burn(<-request)

            return Xorshift128plus.PRG(sourceOfRandomness: source, salt: salt)
        }
    }

    /// Returs the most significant bit of a UInt64
    ///
    /// @param x: The UInt64 to find the most significant bit of
    ///
    /// @return The most significant bit of x
    ///
    access(self) view fun _mostSignificantBit(_ x: UInt64): UInt8 {
        var bits: UInt8 = 0
        var tmp: UInt64 = x
        while tmp > 0 {
            tmp = tmp >> 1
            bits = bits + 1
        }
        return bits
    }

    init() {
        self.ConsumerStoragePath = StoragePath(identifier: "RandomConsumer_".concat(self.account.address.toString()))!
    }
}
