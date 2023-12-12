// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {KeepyUppy} from "../src/KeepyUppy.sol";

contract KeepyUppyHarness is KeepyUppy {
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

    // TODO: Add a fuzzy version of this test.
    function test_updateState_BlockTimeMovesBalloonDown() public {
        address player = vm.addr(1);
        uint256 amount = 1 ether;
        uint256 blockNumber = playerBumpsBalloon(player, amount);
        assertEq(game.balloonHeight(), amount);

        vm.roll(blockNumber + 1);
        game.updateState();
        assertEq(game.balloonHeight(), amount - game.ACCELERATION_GWEI_PER_BLOCK());
    }

    function test_updateState_NonOwnerCallingShouldRevert() public {
        vm.prank(vm.addr(2));
        vm.expectRevert();
        game.updateState();
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
