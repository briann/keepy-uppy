// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {console2} from "lib/forge-std/src/console2.sol";
import {EnumerableMap} from "lib/openzeppelin-contracts/contracts/utils/structs/EnumerableMap.sol";
import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

contract KeepyUppy is ReentrancyGuard {
    uint256 public constant ACCELERATION_PER_BLOCK = 10 wei;
    uint256 public constant MAX_VELOCITY = 1 ether;

    address public owner;

    // Game state
    address public lastBumper;
    uint256 public lastBumpBlockNumber;
    uint256 public lastUpdateBlockNumber;
    uint256 public velocity = 0;
    uint256 public balloonHeight = 0;

    // Array of games played, each game is represented by a map of players to their total contributions to the game.
    EnumerableMap.AddressToUintMap[] private gamePlayerHistory;
    uint256 private currentGameIndex;

    // Game parameters
    uint256 public longestAllowableBlockCadenceForUpdates;

    constructor(uint256 _longestAllowableBlockCadenceForUpdates) {
        owner = msg.sender;
        gamePlayerHistory.push();
        longestAllowableBlockCadenceForUpdates = _longestAllowableBlockCadenceForUpdates;
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

        // Record contributions for this player.
        EnumerableMap.AddressToUintMap storage currentGameContributions = gamePlayerHistory[currentGameIndex];
        uint256 contributions = 0;
        if (EnumerableMap.contains(currentGameContributions, msg.sender)) {
            contributions = EnumerableMap.get(currentGameContributions, msg.sender);
        }
        EnumerableMap.set(currentGameContributions, msg.sender, contributions + msg.value);
    }

    function updateState() external onlyOwner {
        uint256 blocksElapsed = block.number - lastUpdateBlockNumber;
        if (blocksElapsed > longestAllowableBlockCadenceForUpdates) {
            this.refundPlayers();
        } else {
            (uint256 fallDistance, uint256 newVelocity) = calculateFallDistanceAndNewVelocity(
                velocity, block.number - lastUpdateBlockNumber, ACCELERATION_PER_BLOCK
            );
            if (fallDistance > balloonHeight) {
                endGame();
            } else {
                lastUpdateBlockNumber = block.number;
                velocity = newVelocity;
                balloonHeight -= fallDistance;
            }
        }
    }

    function refundPlayers() external nonReentrant {
        uint256 blocksElapsed = block.number - lastUpdateBlockNumber;
        require(blocksElapsed > longestAllowableBlockCadenceForUpdates);
        EnumerableMap.AddressToUintMap storage currentGameContributions = gamePlayerHistory[currentGameIndex];
        for (uint256 i = 0; i < EnumerableMap.length(currentGameContributions); i++) {
            (address player, uint256 totalContributions) = EnumerableMap.at(currentGameContributions, i);
            // TODO: Gas fees here need to be considered.
            (bool success,) = player.call{value: totalContributions}("");
            if (!success) {
                console2.log("Failed to refund ", player, " amount of ", totalContributions);
            }
        }
        resetGameState();
    }

    function calculateFallDistanceAndNewVelocity(uint256 initialVelocity, uint256 blocksElapsed, uint256 acceleration)
        internal
        view
        returns (uint256 fallDistance, uint256 newVelocity)
    {
        require(blocksElapsed <= longestAllowableBlockCadenceForUpdates);
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
        // TODO: Change to call()
        payable(lastBumper).transfer(address(this).balance);
        resetGameState();
    }

    function resetGameState() private {
        lastBumper = address(0);
        lastBumpBlockNumber = 0;
        lastUpdateBlockNumber = 0;
        velocity = 0;
        balloonHeight = 0;
        gamePlayerHistory.push();
        currentGameIndex++;
    }
}
