// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract KeepyUppy {
    uint256 public constant ACCELERATION_WEI_PER_BLOCK = 10;

    address public owner;

    // Game state
    address public lastBumper;
    uint256 public lastBumpBlockNumber;
    uint256 public lastUpdateBlockNumber;
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
        lastUpdateBlockNumber = block.number;
        // Instantly transport the balloon into the "air".
        velocity = 0;
        balloonHeight = msg.value;
    }

    function updateState() external onlyOwner {
        (uint256 fallDistance, uint256 newVelocity) = calculateFallDistanceAndNewVelocity(
            velocity, block.number - lastUpdateBlockNumber, ACCELERATION_WEI_PER_BLOCK
        );
        if (fallDistance > balloonHeight) {
            endGame();
        } else {
            lastUpdateBlockNumber = block.number;
            velocity = newVelocity;
            balloonHeight -= fallDistance;
        }
    }

    function calculateFallDistanceAndNewVelocity(uint256 initialVelocity, uint256 blocksElapsed, uint256 acceleration)
        internal
        pure
        returns (uint256 fallDistance, uint256 newVelocity)
    {
        newVelocity = initialVelocity + (blocksElapsed * acceleration);
        fallDistance = uint256((initialVelocity + newVelocity) * blocksElapsed / 2);
    }

    function endGame() internal onlyOwner {
        payable(lastBumper).transfer(address(this).balance);
        resetGameState();
    }

    function resetGameState() private {
        lastBumper = address(0);
        lastBumpBlockNumber = 0;
        lastUpdateBlockNumber = 0;
        velocity = 0;
        balloonHeight = 0;
    }
}
