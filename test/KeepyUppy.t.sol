// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "lib/forge-std/src/Test.sol";
import {KeepyUppy} from "../src/KeepyUppy.sol";

contract KeepyUppyHarness is KeepyUppy {
    function exposed_calculateFallDistanceAndNewVelocity(
        uint256 initialVelocity,
        uint256 blocksElapsed,
        uint256 acceleration
    ) external pure returns (uint256 fallDistance, uint256 newVelocity) {
        return calculateFallDistanceAndNewVelocity(initialVelocity, blocksElapsed, acceleration);
    }

    function exposed_endGame() external {
        return endGame();
    }
}

contract KeepyUppyTest is Test {
    KeepyUppyHarness public game;

    function setUp() public {
        game = new KeepyUppyHarness();
    }

    function playerBumpsBalloon(address _player, uint256 _amount) private returns (uint256) {
        return playerBumpsBalloon(_player, _amount, 100);
    }

    function playerBumpsBalloon(address _player, uint256 _amount, uint256 _blockNumber) private returns (uint256) {
        vm.prank(_player);
        vm.deal(_player, _amount);
        vm.roll(_blockNumber);
        game.bumpBalloon{value: _amount}();
        return _blockNumber;
    }

    function test_bumpBalloon_IncreasesContractBalance() public {
        address player = vm.addr(1);
        uint256 amount = 1 ether;
        uint256 blockNumber = playerBumpsBalloon(player, amount);
        vm.roll(blockNumber + 1);

        // Asserts
        assertEq(address(game).balance, amount);
        assertEq(game.lastBumper(), player);
        assertEq(game.balloonHeight(), amount);
        assertEq(game.lastBumpBlockNumber(), blockNumber);
    }

    function testFuzz_bumpBalloon_IncreasesContractBalance(uint256 amount) public {
        vm.assume(amount > 0);
        address player = vm.addr(1);
        uint256 blockNumber = playerBumpsBalloon(player, amount);
        vm.roll(blockNumber + 1);

        // Asserts
        assertEq(address(game).balance, amount);
        assertEq(game.lastBumper(), player);
        assertEq(game.balloonHeight(), amount);
        assertEq(game.lastBumpBlockNumber(), blockNumber);
    }

    function test_updateState_BlockTimeMovesBalloonDown() public {
        address player = vm.addr(1);
        uint256 amount = 1 ether;
        uint256 blockNumber = playerBumpsBalloon(player, amount);
        assertEq(game.balloonHeight(), amount);

        // 1 block elapsed since bump
        blockNumber++;
        vm.roll(blockNumber);
        game.updateState();
        assertEq(game.balloonHeight(), amount - 5);

        // 2 blocks elapsed since bump
        blockNumber++;
        vm.roll(blockNumber);
        game.updateState();
        assertEq(game.balloonHeight(), amount - 20);

        // 3 blocks elapsed since bump
        blockNumber++;
        vm.roll(blockNumber);
        game.updateState();
        assertEq(game.balloonHeight(), amount - 45);

        // 100 blocks elapsed since bump
        blockNumber = blockNumber + 97;
        vm.roll(blockNumber);
        game.updateState();
        assertEq(game.balloonHeight(), amount - 50000);
    }

    function test_updateState_NonOwnerCallingShouldRevert() public {
        vm.prank(vm.addr(2));
        vm.expectRevert();
        game.updateState();
    }

    function test_calculateFallDistanceAndNewVelocity() public {
        uint256 fallDistance;
        uint256 newVelocity;

        // Basic calculations with zero initial velocity.

        (fallDistance, newVelocity) = game.exposed_calculateFallDistanceAndNewVelocity(0, 1, 9);
        assertEq(fallDistance, 4);
        assertEq(newVelocity, 9);

        (fallDistance, newVelocity) = game.exposed_calculateFallDistanceAndNewVelocity(0, 2, 9);
        assertEq(fallDistance, 18);
        assertEq(newVelocity, 18);

        (fallDistance, newVelocity) = game.exposed_calculateFallDistanceAndNewVelocity(0, 3, 9);
        assertEq(fallDistance, 40);
        assertEq(newVelocity, 27);

        (fallDistance, newVelocity) = game.exposed_calculateFallDistanceAndNewVelocity(0, 100, 9);
        assertEq(fallDistance, 45000);
        assertEq(newVelocity, 900);

        // Calculations with some initial velocity.
        (fallDistance, newVelocity) = game.exposed_calculateFallDistanceAndNewVelocity(55, 1, 9);
        assertEq(fallDistance, 59);
        assertEq(newVelocity, 64);

        (fallDistance, newVelocity) = game.exposed_calculateFallDistanceAndNewVelocity(55, 2, 9);
        assertEq(fallDistance, 128);
        assertEq(newVelocity, 73);

        (fallDistance, newVelocity) = game.exposed_calculateFallDistanceAndNewVelocity(55, 3, 9);
        assertEq(fallDistance, 205);
        assertEq(newVelocity, 82);

        (fallDistance, newVelocity) = game.exposed_calculateFallDistanceAndNewVelocity(55, 100, 9);
        assertEq(fallDistance, 50500);
        assertEq(newVelocity, 955);
    }

    function test_calculateFallDistanceAndNewVelocity_WithMaxVelocity() public {
        uint256 fallDistance;
        uint256 newVelocity;

        (fallDistance, newVelocity) = game.exposed_calculateFallDistanceAndNewVelocity(UINT256_MAX - 1, 1, 100);
        assertEq(fallDistance, game.MAX_VELOCITY());
        assertEq(newVelocity, game.MAX_VELOCITY());

        (fallDistance, newVelocity) = game.exposed_calculateFallDistanceAndNewVelocity(game.MAX_VELOCITY() - 1, 1, 2);
        assertEq(fallDistance, game.MAX_VELOCITY() - 1);
        assertEq(newVelocity, game.MAX_VELOCITY());

        (fallDistance, newVelocity) = game.exposed_calculateFallDistanceAndNewVelocity(game.MAX_VELOCITY() - 1, 2, 1);
        assertEq(fallDistance, game.MAX_VELOCITY() * 2 - 1);
        assertEq(newVelocity, game.MAX_VELOCITY());
    }

    function test_endGame_PaysOutAndResetsState() public {
        address player = vm.addr(1);
        uint256 amount = 1 ether;

        uint256 blockNumber = playerBumpsBalloon(player, amount);
        vm.roll(blockNumber + 1);
        game.exposed_endGame();

        // Asserts
        assertEq(address(game).balance, 0);
        assertEq(player.balance, 1 ether);
        assertEq(game.velocity(), 0);
        assertEq(game.balloonHeight(), 0);
        assertEq(game.lastBumpBlockNumber(), 0);
        assertEq(game.lastBumper(), address(0));
    }

    function test_endGame_NonOwnerCallingShouldRevert() public {
        vm.prank(vm.addr(2));
        vm.expectRevert();
        game.exposed_endGame();
    }
}
