// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "../src/CoinToss.sol";

contract CoinTossTest is Test {
    CoinToss private coinToss;

    address payable user = payable(address(100));
    uint64 mockFlowBlockHeight = 12345;

    function setUp() public {
        // Deploy the CoinToss contract before each test
        coinToss = new CoinToss();

        // Fund test accounts
        vm.deal(address(coinToss), 10 ether);
        vm.deal(user, 10 ether);

        // Mock the Cadence Arch precompile for flowBlockHeight() call
        vm.mockCall(
            coinToss.cadenceArch(), abi.encodeWithSignature("flowBlockHeight()"), abi.encode(mockFlowBlockHeight)
        );

        // Mock the Cadence Arch precompile for getRandomSource(uint64) call
        vm.mockCall(
            coinToss.cadenceArch(), abi.encodeWithSignature("getRandomSource(uint64)", 100), abi.encode(uint64(0))
        );
    }

    function testFlipCoin() public {
        // Move forward one Flow block when called
        vm.mockCall(
            coinToss.cadenceArch(),
            abi.encodeWithSignature("flowBlockHeight()"),
            abi.encode(mockFlowBlockHeight) // Simulate a new Flow block
        );

        // Simulate that the next call is made by `user`
        vm.prank(user);
        coinToss.flipCoin{value: 1 ether}();

        // Check that the value amount was stored correctly
        uint256 requestId = coinToss.coinTosses(user);
        assertEq(coinToss.openRequests(requestId), 1 ether, "Value amount sent should be 1 full FLOW");
    }

    function testFlipCoinFailNoValue() public {
        vm.prank(user);
        vm.expectRevert("Must send FLOW to place flip a coin"); // Expect a revert since no Ether is sent
        coinToss.flipCoin();
    }

    function testRevealCoinFailSameBlock() public {
        vm.mockCall(
            coinToss.cadenceArch(), abi.encodeWithSignature("flowBlockHeight()"), abi.encode(mockFlowBlockHeight)
        );
        vm.prank(user);
        coinToss.flipCoin{value: 1 ether}();

        vm.mockCall(
            coinToss.cadenceArch(), abi.encodeWithSignature("flowBlockHeight()"), abi.encode(mockFlowBlockHeight)
        );
        vm.prank(user);
        vm.expectRevert("Cannot fulfill request until subsequent Flow network block height"); // Expect a revert since the block hasn't advanced
        coinToss.revealCoin();
    }

    function testRevealCoinWins() public {
        vm.mockCall(
            coinToss.cadenceArch(), abi.encodeWithSignature("flowBlockHeight()"), abi.encode(mockFlowBlockHeight)
        );

        // First, flip the coin
        uint256 sentValue = 1 ether;
        vm.prank(user);
        coinToss.flipCoin{value: sentValue}();

        // Get the user's balance before revealing the coin
        uint256 initialBalance = user.balance;

        vm.mockCall(
            coinToss.cadenceArch(), abi.encodeWithSignature("flowBlockHeight()"), abi.encode(mockFlowBlockHeight + 1)
        );
        // The result gets hashed in CadenceRandomConsumer with the request ID. Unfortunately we can't mockCall internal
        // functions, so we just use a mocked value that should result in a win (even number).
        vm.mockCall(
            coinToss.cadenceArch(),
            abi.encodeWithSignature("getRandomSource(uint64)", mockFlowBlockHeight),
            abi.encode(bytes32(0x0000000000000000000000000000000000000000000000000000000000000011))
        );
        vm.prank(user);
        coinToss.revealCoin();

        uint256 finalBalance = user.balance;

        // Ensure the user has received their prize
        uint8 multiplier = coinToss.multiplier();
        uint256 expectedPrize = sentValue * multiplier;
        assertEq(finalBalance, initialBalance + expectedPrize, "User should have received a prize");

        bool hasOpenRequest = coinToss.hasOpenRequest(user);
        assertEq(false, hasOpenRequest, "User should not have an open request after revealing the coin");

        bool canFullfillRequest = coinToss.canFulfillRequest(uint256(1));
        assertEq(false, canFullfillRequest, "Request should not be fulfillable after revealing the coin");
    }

    function testRevealCoinLoses() public {
        vm.mockCall(
            coinToss.cadenceArch(), abi.encodeWithSignature("flowBlockHeight()"), abi.encode(mockFlowBlockHeight)
        );

        vm.prank(user);
        coinToss.flipCoin{value: 1 ether}();

        vm.mockCall(
            coinToss.cadenceArch(), abi.encodeWithSignature("flowBlockHeight()"), abi.encode(mockFlowBlockHeight + 1)
        );
        vm.mockCall(
            coinToss.cadenceArch(),
            abi.encodeWithSignature("getRandomSource(uint64)", mockFlowBlockHeight),
            abi.encode(bytes32(0xff00000000000000000000000000000000000000000000000000000000000001))
        );
        // abi.encode(bytes32(0x0000000000000000000000000000000000000000000000000000000000000099))

        // Ensure that the user doesn't get paid
        uint256 initialBalance = user.balance;
        vm.prank(user);
        coinToss.revealCoin();
        uint256 finalBalance = user.balance;

        // Ensure the user balance hasn't changed (no winnings)
        assertEq(finalBalance, initialBalance, "User should not receive winnings");
    }
}
