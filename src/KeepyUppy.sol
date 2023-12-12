// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract KeepyUppy {
    uint256 public constant ACCELERATION_GWEI_PER_BLOCK = 10;

    address public owner;

    // Game state
    address public lastBumper;
    uint256 public lastBumpBlockNumber;
    uint256 public velocity = 0;
    uint256 public balloonHeight = 0;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner allowed");
        _;
    }

    function bumpBalloon() external payable {
        require(msg.value > 0);
        lastBumper = msg.sender;
        lastBumpBlockNumber = block.number;
        balloonHeight = msg.value;
    }

    function updateState() external onlyOwner {
        velocity = (block.number - lastBumpBlockNumber) * ACCELERATION_GWEI_PER_BLOCK;
        if (velocity > balloonHeight) {
            endGame();
        } else {
            balloonHeight -= velocity;
        }
    }

    function endGame() internal onlyOwner {
        payable(lastBumper).transfer(address(this).balance);
        resetGameState();
    }

    function resetGameState() private {
        velocity = 0;
        balloonHeight = 0;
        lastBumpBlockNumber = 0;
        lastBumper = address(0);
    }
}
