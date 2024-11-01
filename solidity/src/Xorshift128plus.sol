// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;

/**
 * @dev This library implements the Xorshift128+ pseudo-random number generator (PRG) algorithm.
 */
library Xorshift128plus {
    /**
     * @dev While not limited to 128 bits of state, this PRG is largely informed by xorshift128+
     */
    struct PRG {
        uint64 state0;
        uint64 state1;
    }

    /**
     * @dev Initializer for PRG struct
     *
     * @param prg The PRG struct to seed
     * @param sourceOfRandomness The entropy bytes used to seed the PRG. It is recommended to use at least 16
     * bytes of entropy.
     * @param salt The bytes used to salt the source of randomness
     */
    function seed(PRG memory prg, bytes memory sourceOfRandomness, bytes memory salt) internal pure {
        require(
            sourceOfRandomness.length >= 16, "At least 16 bytes of entropy should be used when initializing the PRG"
        );
        bytes memory tmp = abi.encodePacked(sourceOfRandomness, salt);
        bytes32 hash = keccak256(tmp);

        prg.state0 = _bigEndianBytesToUint64(abi.encodePacked(hash), 0);
        prg.state1 = _bigEndianBytesToUint64(abi.encodePacked(hash), 8);

        _requireNonZero(prg);
    }

    /**
     * @dev Advances the PRG state and generates the next UInt64 value
     * See https://arxiv.org/pdf/1404.0390.pdf for implementation details and reasoning for triplet selection.
     * Note that state only advances when this function is called from a transaction. Calls from within a script
     * will not advance state and will return the same value.
     *
     * @return The next UInt64 value
     */
    function nextUInt64(PRG memory prg) internal pure returns (uint64) {
        _requireNonZero(prg);

        uint64 a = prg.state0;
        uint64 b = prg.state1;

        prg.state0 = b;

        // Allow the states to wrap around
        unchecked {
            a ^= a << 23; // a
            a ^= a >> 17; // b
            a ^= b ^ (b >> 26); // c
        }

        prg.state1 = a;

        unchecked {
            return a + b; // Addition with wrapping
        }
    }

    /**
     * @dev Advances the PRG state and generates the next UInt256 value by concatenating 4 UInt64 values
     *
     * @return The next UInt256 value
     */
    function nextUInt256(PRG memory prg) internal pure returns (uint256) {
        uint256 result = uint256(nextUInt64(prg));
        result |= uint256(nextUInt64(prg)) << 64;
        result |= uint256(nextUInt64(prg)) << 128;
        result |= uint256(nextUInt64(prg)) << 192;
        return result;
    }

    /**
     * @dev Helper function to convert an array of big endian bytes to Word64
     *
     * @param input The bytes to convert
     * @param start The index of the first byte to convert
     *
     * @return The Word64 value
     */
    function _bigEndianBytesToUint64(bytes memory input, uint256 start) private pure returns (uint64) {
        require(input.length >= start + 8, "Invalid byte length");
        uint64 value = 0;
        for (uint256 i = 0; i < 8; i++) {
            value = (value << 8) | uint64(uint8(input[start + i]));
        }
        return value;
    }

    function _requireNonZero(PRG memory prg) private pure {
        require(prg.state0 != 0 || prg.state1 != 0, "PRG initial state is 0 - must be initialized as non-zero");
    }
}
