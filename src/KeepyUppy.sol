// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract KeepyUppy {
    uint256 public constant ACCELERATION_PER_BLOCK = 10 wei;
    uint256 public constant MAX_VELOCITY = 1 ether;
    uint256 public constant LONGEST_ALLOWABLE_BLOCK_CADENCE_FOR_UPDATES = 100;

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
        // TODO: If the number of blocks elapsed has been too long, we should return money back because we weren't
        // keeping the game clock ticking as participants expect.
        (uint256 fallDistance, uint256 newVelocity) =
            calculateFallDistanceAndNewVelocity(velocity, block.number - lastUpdateBlockNumber, ACCELERATION_PER_BLOCK);
        if (fallDistance > balloonHeight) {
            endGame();
        } else {
            lastUpdateBlockNumber = block.number;
            velocity = newVelocity;
            balloonHeight -= fallDistance;
        }
    }

    // TODO: Add a function to return funds if blocks elapsed has exceeded limits.

    function calculateFallDistanceAndNewVelocity(uint256 initialVelocity, uint256 blocksElapsed, uint256 acceleration)
        internal
        pure
        returns (uint256 fallDistance, uint256 newVelocity)
    {
        require(blocksElapsed <= LONGEST_ALLOWABLE_BLOCK_CADENCE_FOR_UPDATES);
        if (initialVelocity >= MAX_VELOCITY) {
            initialVelocity = MAX_VELOCITY;
        }
        newVelocity = initialVelocity + (blocksElapsed * acceleration);
        if (newVelocity > MAX_VELOCITY) {
            newVelocity = MAX_VELOCITY;
        }
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
