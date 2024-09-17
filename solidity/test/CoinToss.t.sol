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
            abi.encode(mockFlowBlockHeight + 1) // Simulate a new Flow block
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

    function testRevealCoinWins() public {
        vm.mockCall(
            coinToss.cadenceArch(), abi.encodeWithSignature("flowBlockHeight()"), abi.encode(mockFlowBlockHeight + 1)
        );

        // First, flip the coin
        uint256 sentValue = 1 ether;
        vm.prank(user);
        coinToss.flipCoin{value: sentValue}();

        // Get the user's balance before revealing the coin
        uint256 initialBalance = user.balance;

        vm.mockCall(
            coinToss.cadenceArch(),
            abi.encodeWithSignature("flowBlockHeight()"),
            abi.encode(mockFlowBlockHeight + 2) // Simulate a new Flow block
        );
        // The result gets hashed in CadenceRandomConsumer with the request ID. Unfortunately we can't mockCall internal
        // functions, so we just use a mocked value that should result in a win (even number).
        vm.mockCall(
            coinToss.cadenceArch(),
            abi.encodeWithSignature("getRandomSource(uint64)", mockFlowBlockHeight + 1),
            abi.encode(uint64(1)) // Mocked result
        );
        vm.prank(user);
        coinToss.revealCoin();

        uint256 finalBalance = user.balance;

        // Ensure the user has received their prize
        uint8 multiplier = coinToss.multiplier();
        uint256 expectedPrize = sentValue * multiplier;
        assertEq(finalBalance, initialBalance + expectedPrize, "User should have received a prize");
    }

    function testRevealCoinLoses() public {
        vm.mockCall(
            coinToss.cadenceArch(),
            abi.encodeWithSignature("flowBlockHeight()"),
            abi.encode(mockFlowBlockHeight + 1)
        );

        vm.prank(user);
        coinToss.flipCoin{value: 1 ether}();

        vm.mockCall(
            coinToss.cadenceArch(),
            abi.encodeWithSignature("flowBlockHeight()"),
            abi.encode(mockFlowBlockHeight + 2)
        );
        vm.mockCall(
            coinToss.cadenceArch(),
            abi.encodeWithSignature("getRandomSource(uint64)", mockFlowBlockHeight + 1),
            abi.encode(uint64(0))
        );

        // Ensure that the user doesn't get paid
        uint256 initialBalance = user.balance;
        vm.prank(user);
        coinToss.revealCoin();
        uint256 finalBalance = user.balance;

        // Ensure the user balance hasn't changed (no winnings)
        assertEq(finalBalance, initialBalance, "User should not receive winnings");
    }
}
