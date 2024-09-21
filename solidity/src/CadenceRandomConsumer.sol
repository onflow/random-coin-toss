// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {CadenceArchWrapper} from "./CadenceArchWrapper.sol";

/**
 * @dev This contract is a base contract for secure consumption of Flow's protocol-native randomness via the Cadence
 * Arch pre-compile. Implementing contracts benefit from the commit-reveal scheme below, ensuring that callers cannot
 * revert on undesirable random results.
 */
abstract contract CadenceRandomConsumer is CadenceArchWrapper {
    // A struct to store the request details
    struct Request {
        // The Flow block height at which the request was made
        uint64 flowHeight;
        // The EVM block height at which the request was made
        uint256 evmHeight;
        // Whether the request has been fulfilled
        bool fulfilled;
    }

    // Events
    event RandomnessRequested(uint256 indexed requestId, uint64 flowHeight, uint256 evmHeight);
    event RandomnessSourced(uint256 indexed requestId, uint64 flowHeight, uint256 evmHeight, bytes32 randomSource);
    event RandomnessFulfilled(uint256 indexed requestId, uint64 randomResult);

    // A list of requests where each request is identified by its index in the array
    Request[] private _requests;
    // A counter to keep track of the number of requests made, serving as the request ID
    uint256 private _requestCounter;

    ///////////////////
    // PUBLIC FUNCTIONS
    ///////////////////

    /**
     * @dev This method checks if a request can be fulfilled.
     *
     * @param requestId The ID of the randomness request to check.
     * @return canFulfill Whether the request can be fulfilled.
     */
    function canFulfillRequest(uint256 requestId) public view returns (bool) {
        uint256 requestIndex = requestId - 1;
        if (requestIndex >= _requests.length) {
            return false;
        }
        Request memory request = _requests[requestIndex];
        uint64 flowHeight = _flowBlockHeight();
        return !request.fulfilled && request.flowHeight < flowHeight;
    }

    /////////////////////
    // INTERNAL FUNCTIONS
    /////////////////////

    /**
     * @dev This method returns a ***REVERTIBLE** random number in the range [min, max].
     * NOTE: The fact that this method is revertible means that it should only be used in cases where the caller is
     * trusted not to revert on the result.
     *
     * @param min The minimum value of the range (inclusive).
     * @param max The maximum value of the range (inclusive).
     * @return random The random number in the range [min, max].
     */
    function _getRevertibleRandomInRange(uint64 min, uint64 max) internal view returns (uint64) {
        uint256 randomValue = _aggregateRevertibleRandom256();
        return _getNumberInRange(randomValue, min, max);
    }

    /**
     * ----- COMMIT STEP -----
     */

    /**
     * @dev This method serves as the commit step in this contract's commit-reveal scheme
     *
     * Here a caller places commits at Flow block n to reveal a random number at >= block n+1
     * This is because the random source for a Flow block is not available until after the finalization of that block.
     * Implementing contracts may wish to affiliate the request ID with the caller's address or some other identifier
     * so the relevant request can be fulfilled.
     * Emits a {RandomnessRequested} event.
     *
     * @return requestId The ID of the request.
     */
    function _requestRandomness() internal returns (uint256) {
        // Identify the request by the current request counter, incrementing first so implementations can use 0 for
        // invalid requests - e.g. myRequests[msg.sender] == 0 means the caller has no pending requests
        _requestCounter++;
        uint256 requestId = _requestCounter;
        // Store the heights at which the request was made. Note that the Flow block height and EVM block height are
        // not the same. But since Flow blocks ultimately determine usage of secure randomness, we gate requests by
        // Flow block height.
        Request memory request = Request(_flowBlockHeight(), block.number, false);

        // Store the request in the list of requests
        _requests.push(request);

        emit RandomnessRequested(requestId, request.flowHeight, request.evmHeight);

        // Finally return the request ID
        return requestId;
    }

    /**
     * ----- REVEAL STEP -----
     */

    /**
     * @dev This method fulfills a random request and returns a random number as a uint64.
     *
     * @param requestId The ID of the randomness request to fulfill.
     * @return randomResult The random number.
     */
    function _fulfillRandomRequest(uint256 requestId) internal returns (uint64) {
        bytes32 randomValue = _fulfillRandomness(requestId);
        uint64 randomResult = uint64(uint256(keccak256(abi.encodePacked(randomValue, requestId))));

        emit RandomnessFulfilled(requestId, randomResult);

        return randomResult;
    }

    /**
     * @dev This method fulfills a random request and returns a random number in the range [min, max].
     *
     * @param requestId The ID of the randomness request to fulfill.
     * @param min The minimum value of the range (inclusive).
     * @param max The maximum value of the range (inclusive).
     * @return randomResult The random number in the range [min, max].
     */
    function _fulfillRandomInRange(uint256 requestId, uint64 min, uint64 max) internal returns (uint64) {
        // Ensure that the request is fulfilled at a Flow block height greater than the one at which the request was made
        // Get the random source for the Flow block at which the request was made
        bytes32 randomSource = _fulfillRandomness(requestId);
        // Pack the randomResult into a uint256, hashing with the requestId to vary results across shared block heights.
        uint256 randomValue = uint256(keccak256(abi.encodePacked(randomSource, requestId)));

        uint64 randomResult = _getNumberInRange(randomValue, min, max);

        emit RandomnessFulfilled(requestId, randomResult);

        return randomResult;
    }

    ////////////////////
    // PRIVATE FUNCTIONS
    ////////////////////

    /**
     * @dev This method returns a random number in the range [min, max].
     *
     * @param min The minimum value of the range (inclusive).
     * @param max The maximum value of the range (inclusive).
     * @return random The random number in the range [min, max].
     */
    function _getNumberInRange(uint256 randomValue, uint64 min, uint64 max) private pure returns (uint64) {
        require(max > min, "Max must be greater than min");

        uint64 range = max - min + 1;
        uint64 bitsRequired = _mostSignificantBit(range - 1); // Number of bits needed to cover the range
        // uint256 randomValue = _aggregateRandom256(); // Aggregate 256 bits from 4 calls to _revertibleRandom()
        uint256 mask = (1 << bitsRequired) - 1; // Create a bitmask to extract relevant bits
        uint64 candidate = 0; // Initialize candidate

        while (true) {
            candidate = uint64(randomValue & mask); // Apply bitmask to extract bits
            // If candidate is in range, break and return
            if (candidate < range) {
                break;
            }
            // Shift to the next chunk of bits
            randomValue = randomValue >> bitsRequired;
            require(randomValue > 0, "Random number source exhausted");
        }

        uint64 randomResult = candidate + min; // Scale candidate to the range [min, max]
        require(randomResult >= min && randomResult <= max, "Random number out of range");
        return randomResult;
    }

    /**
     * @dev This method serves as the reveal step in this contract's commit-reveal scheme
     *
     * Here a caller reveals a random number at least one block after the commit block
     * This is because the random source for a Flow block is not available until after the finalization of that block.
     * Note that the random source for a given Flow block is singular. In order to ensure that requests made at the same
     * block height are unique, implementing contracts should use some pseudo-random method to generate a unique value
     * from the seed along with a salt.
     * Emits a {RandomnessFulfilled} event.
     *
     * @param requestId The ID of the randomness request to fulfill.
     * @return randomResult The random value generated from the Flow block.
     */
    function _fulfillRandomness(uint256 requestId) private returns (bytes32) {
        // Get the request details. Recall that request IDs are 1-indexed to allow for 0 to be used as an invalid value
        uint256 requestIndex = requestId - 1;
        require(requestIndex < _requests.length, "Invalid request ID - value exceeds the number of existing requests");

        // Access & validate the request
        Request memory request = _requests[requestIndex];
        _validateRequest(request);
        request.fulfilled = true; // Mark the request as fulfilled

        // Get the random source for the Flow block at which the request was made, emit & return
        bytes32 randomSource = _getRandomSource(request.flowHeight);

        emit RandomnessSourced(requestId, request.flowHeight, request.evmHeight, randomSource);

        return randomSource;
    }

    /**
     * @dev This method aggregates 256 bits of randomness by calling _revertibleRandom() 4 times.
     *
     * @return randomValue The aggregated 256 bits of randomness.
     */
    function _aggregateRevertibleRandom256() private view returns (uint256) {
        // Call _revertibleRandom() 4 times to aggregate 256 bits of randomness
        uint256 randomValue = uint256(_revertibleRandom());
        randomValue |= (uint256(_revertibleRandom()) << 64);
        randomValue |= (uint256(_revertibleRandom()) << 128);
        randomValue |= (uint256(_revertibleRandom()) << 192);
        return randomValue;
    }

    /**
     * @dev This method returns the most significant bit of a uint64.
     *
     * @param x The input value.
     * @return bits The most significant bit of the input value.
     */
    function _mostSignificantBit(uint64 x) private pure returns (uint64) {
        uint64 bits = 0;
        while (x > 0) {
            x >>= 1;
            bits++;
        }
        return bits;
    }

    /**
     * @dev This method validates a given request, ensuring that it has not been fulfilled and that the Flow block height
     * has passed.
     *
     * @param request The request to validate.
     */
    function _validateRequest(Request memory request) private view {
        require(!request.fulfilled, "Request already fulfilled");
        require(
            request.flowHeight < _flowBlockHeight(), "Cannot fulfill request until subsequent Flow network block height"
        );
    }
}
