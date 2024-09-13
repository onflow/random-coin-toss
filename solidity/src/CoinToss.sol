// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./CadenceRandomConsumer.sol";

contract CoinToss is CadenceRandomConsumer {
    uint8 constant betMultiplier = 2;

    mapping(address => uint256) public coinTosses;
    mapping(uint256 => uint256) public bets;

    function flipCoin() public payable {
        require(msg.value > 0, "Must send ETH to place a bet");
        uint256 requestId = _requestRandomness();
        coinTosses[msg.sender] = requestId;
        bets[requestId] = msg.value;
    }

    function revealCoin() public {
        // reveal random result and calculate winnings
        uint256 requestId = coinTosses[msg.sender];
        uint64 randomResult = _fulfillRandomness(uint32(requestId));
        uint256 bet = bets[requestId];
        uint256 winnings = bet * betMultiplier;
        if (randomResult % 2 == 0) {
            // win
            payable(msg.sender).transfer(winnings);
        }
    }
}
