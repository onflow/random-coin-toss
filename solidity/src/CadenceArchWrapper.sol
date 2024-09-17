// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @dev This contract is a base contract to facilitate easier consumption of the Cadence Arch pre-compiles. Implementing
 * contracts can use this contract to fetch the current Flow block height and fetch random numbers from the Cadence
 * runtime.
 */
abstract contract CadenceArchWrapper {
    // Cadence Arch pre-compile address
    address public constant cadenceArch = 0x0000000000000000000000010000000000000001;

    /**
     * @dev This method returns the current Flow block height.
     *
     * @return flowBlockHeight The current Flow block height.
     */
    function _flowBlockHeight() internal view returns (uint64) {
        (bool ok, bytes memory data) = cadenceArch.staticcall(abi.encodeWithSignature("flowBlockHeight()"));
        require(ok, "Unsuccessful call to Cadence Arch pre-compile when fetching Flow block height");

        uint64 output = abi.decode(data, (uint64));
        return output;
    }

    /**
     * @dev This method uses the Cadence Arch pre-compiles to return a random number from the Cadence runtime. Consumers
     * should know this is a revertible random source and should only be used as a source of randomness when called by
     * trusted callers - i.e. with trust that the caller won't revert on result.
     *
     * @return randomSource The random source.
     */
    function _revertibleRandom() internal view returns (uint64) {
        (bool ok, bytes memory data) = cadenceArch.staticcall(abi.encodeWithSignature("revertibleRandom()"));
        require(ok, "Unsuccessful call to Cadence Arch pre-compile when fetching revertible random number");

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
    function _getRandomSource(uint64 flowHeight) internal view returns (uint64) {
        (bool ok, bytes memory data) =
            cadenceArch.staticcall(abi.encodeWithSignature("getRandomSource(uint64)", flowHeight));
        require(ok, "Unsuccessful call to Cadence Arch pre-compile when fetching random source");

        uint64 output = abi.decode(data, (uint64));
        return output;
    }
}
