// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @dev This contract is a base contract for secure consumption of Flow's protocol-native randomness via the Cadence
 * Arch pre-compile. Implementing contracts benefit from the commit-reveal scheme below, ensuring that callers cannot
 * revert on undesirable random results.
 */
abstract contract CadenceRandomConsumer {
    // Cadence Arch pre-compile address
    address public constant cadenceArch = 0x0000000000000000000000010000000000000001;

    // A struct to store the request details
    struct Request {
        // The Flow block height at which the request was made
        uint64 flowHeight;
        // The EVM block height at which the request was made
        uint256 evmHeight;
    }

    // Events
    event RandomnessRequested(uint256 requestId, uint64 flowHeight, uint256 evmHeight);
    event RandomnessFulfilled(uint256 requestId, uint64 flowHeight, uint256 evmHeight, uint256 randomResult);

    // A list of requests where each request is identified by its index in the array
    Request[] private _requests;
    // A counter to keep track of the number of requests made, serving as the request ID
    uint256 private _requestCounter;

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
    function _requestRandomness() public returns (uint256) {
        // Identify the request by the current request counter, incrementing first so implementations can use 0 for
        // invalid requests - e.g. myRequests[msg.sender] == 0 means the caller has no pending requests
        _requestCounter++;
        uint256 requestId = _requestCounter;
        // Store the heights at which the request was made. Note that the Flow block height and EVM block height are
        // not the same. But since Flow blocks ultimately determine usage of secure randomness, we gate requests by
        // Flow block height.
        Request memory request = Request(_getFlowBlockHeight(), block.number);

        // Store the request in the list of requests
        _requests.push(request);

        emit RandomnessRequested(requestId, request.flowHeight, request.evmHeight);

        // Finally return the request ID
        return requestId;
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
    function _fulfillRandomness(uint32 requestId) internal returns (uint64) {
        // Get the request details. Recall that request IDs are 1-indexed to allow for 0 to be used as an invalid value
        uint32 requestIndex = requestId - 1;
        require(requestIndex < _requests.length, "Invalid request ID - value exceeds the number of existing requests");
        Request memory request = _requests[requestIndex];

        // Ensure that the request is fulfilled at a Flow block height greater than the one at which the request was made
        uint64 flowHeight = _getFlowBlockHeight();
        require(request.flowHeight < flowHeight, "Cannot fulfill request until subsequent Flow network block height");

        // Get the random source for the Flow block at which the request was made
        uint64 randomResult = _getRandomSource(request.flowHeight); // returns bytes32
        // Pack the randomResult into a uint64, hashing with the requestId to vary results across shared block heights
        randomResult = uint64(uint256(keccak256(abi.encodePacked(randomResult, requestId))));

        emit RandomnessFulfilled(requestId, request.flowHeight, request.evmHeight, randomResult);

        // Return the random result
        return randomResult;
    }

    /**
     * @dev This method returns the current Flow block height
     *
     * @return flowBlockHeight The current Flow block height.
     */
    function _getFlowBlockHeight() internal view returns (uint64) {
        (bool ok, bytes memory data) = cadenceArch.staticcall(abi.encodeWithSignature("flowBlockHeight()"));
        require(ok, "Unsuccessful call to Cadence Arch pre-compile when fetching Flow block height");

        uint64 output = abi.decode(data, (uint64));
        return output;
    }

    /**
     * @dev This method uses the Cadence Arch pre-compiles to returns a random source for a given Flow block height.
     * The provided height must be at least one block in the past.
     *
     * @param flowHeight The Flow block height for which to get the random source.
     * @return randomSource The random source for the given Flow block height.
     */
    function _getRandomSource(uint64 flowHeight) private view returns (uint64) {
        (bool ok, bytes memory data) =
            cadenceArch.staticcall(abi.encodeWithSignature("getRandomSource(uint64)", flowHeight));
        require(ok, "Unsuccessful call to Cadence Arch pre-compile when fetching random source");

        uint64 output = abi.decode(data, (uint64));
        return output;
    }
}
