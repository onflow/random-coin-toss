// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "../src/CadenceRandomConsumer.sol";
import "../src/test/TestCadenceRandomConsumer.sol";
import "../src/Xorshift128plus.sol";

contract CadenceRandomConsumerTest is Test {
    TestCadenceRandomConsumer private consumer;
    address payable user = payable(address(100));
    uint64 mockFlowBlockHeight = 12345;

    event RandomnessRequested(uint256 requestId, uint64 flowBlockHeight, uint256 blockNumber);

    // Initialize the test environment
    function setUp() public {
        consumer = new TestCadenceRandomConsumer();

        // Fund test accounts
        vm.deal(address(consumer), 10 ether);
        vm.deal(user, 10 ether);

        // Mock the Cadence Arch precompile for flowBlockHeight() call
        vm.mockCall(
            consumer.cadenceArch(), abi.encodeWithSignature("flowBlockHeight()"), abi.encode(mockFlowBlockHeight)
        );

        // Mock the Cadence Arch precompile for getRandomSource(uint64) call
        vm.mockCall(
            consumer.cadenceArch(), abi.encodeWithSignature("getRandomSource(uint64)", 100), abi.encode(uint64(0))
        );

        // Mock the Cadence Arch precompile for revertibleRandom() call
        vm.mockCall(consumer.cadenceArch(), abi.encodeWithSignature("revertibleRandom()"), abi.encode(uint64(0)));
    }

    /**
     * Test _getRevertibleRandomInRange.
     * Verifies that the random number is within the given range.
     */
    function testGetRevertibleRandomInRange() public {
        uint64 min = 10;
        uint64 max = 100;

        vm.mockCall(consumer.cadenceArch(), abi.encodeWithSignature("revertibleRandom()"), abi.encode(uint64(999)));
        vm.prank(user);

        uint64 randomValue = consumer.getRevertibleRandomInRange(min, max);

        // Assert that the random value is within the expected range
        assertTrue(randomValue >= min && randomValue <= max, "Random value is out of range");
    }

    /**
     * Test _requestRandomness.
     * Ensures a randomness request is created and emits the appropriate event.
     */
    function testRequestRandomness() public {
        vm.mockCall(
            consumer.cadenceArch(), abi.encodeWithSignature("flowBlockHeight()"), abi.encode(mockFlowBlockHeight)
        );

        uint256 requestId = consumer.requestRandomness();

        // Assert that the request ID is greater than 0
        assertGt(requestId, 0, "Request ID is invalid");
    }

    /**
     * Test _fulfillRandomRequest.
     * Verifies that fulfilling a random request returns a valid random number.
     */
    function testFulfillRandomRequest() public {
        vm.mockCall(
            consumer.cadenceArch(), abi.encodeWithSignature("flowBlockHeight()"), abi.encode(mockFlowBlockHeight)
        );
        // First, request randomness
        uint256 requestId = consumer.requestRandomness();

        vm.mockCall(
            consumer.cadenceArch(), abi.encodeWithSignature("flowBlockHeight()"), abi.encode(mockFlowBlockHeight + 1)
        );
        // Mock the Cadence Arch precompile for getRandomSource(uint64) call
        vm.mockCall(
            consumer.cadenceArch(),
            abi.encodeWithSignature("getRandomSource(uint64)", mockFlowBlockHeight),
            abi.encode(bytes32(0x0000000000000000000000000000000000000000000000000000000000000011))
        );
        // Fulfill the request
        uint64 randomResult = consumer.fulfillRandomRequest(requestId);

        // Assert that the result is non-zero
        assertGt(randomResult, 0, "Random result should be greater than 0");
    }

    /**
     * Test _fulfillRandomInRange.
     * Verifies that fulfilling a random request returns a number within the specified range.
     */
    function testFulfillRandomInRange() public {
        uint64 min = 5;
        uint64 max = 50;

        vm.mockCall(
            consumer.cadenceArch(), abi.encodeWithSignature("flowBlockHeight()"), abi.encode(mockFlowBlockHeight)
        );
        // First, request randomness
        uint256 requestId = consumer.requestRandomness();

        vm.mockCall(
            consumer.cadenceArch(), abi.encodeWithSignature("flowBlockHeight()"), abi.encode(mockFlowBlockHeight + 1)
        );
        // Mock the Cadence Arch precompile for getRandomSource(uint64) call
        vm.mockCall(
            consumer.cadenceArch(),
            abi.encodeWithSignature("getRandomSource(uint64)", mockFlowBlockHeight),
            abi.encode(bytes32(0x0000000000000000000000000000000000000000000000000000000000000011))
        );
        // Fulfill the request and get a random number within the range [min, max]
        uint64 randomResult = consumer.fulfillRandomInRange(requestId, min, max);

        // Assert that the result is within the specified range
        assertTrue(randomResult >= min && randomResult <= max, "Random result is out of range");
    }
}
