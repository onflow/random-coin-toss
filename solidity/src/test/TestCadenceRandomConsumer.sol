// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../CadenceRandomConsumer.sol";

/**
 * @dev This contract extends CadenceRandomConsumer to expose internal functions for testing.
 */
contract TestCadenceRandomConsumer is CadenceRandomConsumer {
    // Expose internal _getRevertibleRandomInRange function for testing
    function getRevertibleRandomInRange(uint64 min, uint64 max) public view returns (uint64) {
        return _getRevertibleRandomInRange(min, max);
    }

    // Expose internal _requestRandomness function for testing
    function requestRandomness() public returns (uint256) {
        return _requestRandomness();
    }

    // Expose internal _fulfillRandomRequest function for testing
    function fulfillRandomRequest(uint256 requestId) public returns (uint64) {
        return _fulfillRandomRequest(requestId);
    }

    // Expose internal _fulfillRandomInRange function for testing
    function fulfillRandomInRange(uint256 requestId, uint64 min, uint64 max) public returns (uint64) {
        return _fulfillRandomInRange(requestId, min, max);
    }
}
