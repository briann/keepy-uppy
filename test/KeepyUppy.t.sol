// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "lib/forge-std/src/Test.sol";
import {KeepyUppy} from "src/KeepyUppy.sol";

contract KeepyUppyHarness is KeepyUppy(100, 10 wei, 1 ether) {
    function exposed_calculateFallDistanceAndNewVelocity(
        uint256 initialVelocity,
        uint256 blocksElapsed,
        uint256 acceleration
    ) external view returns (uint256 fallDistance, uint256 newVelocity) {
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

    // Utilities

    function playerBumpsBalloon(address _player, uint256 _amount, uint256 _blockNumber) private {
        vm.deal(_player, _amount);
        vm.roll(_blockNumber);
        vm.prank(_player);
        game.bumpBalloon{value: _amount}();
    }

    function assertGameStateIsReset() private {
        assertEq(game.lastBumper(), address(0));
        assertEq(game.lastBumpBlockNumber(), 0);
        assertEq(game.lastUpdateBlockNumber(), 0);
        assertEq(game.velocity(), 0);
        assertEq(game.balloonHeight(), 0);
    }

    // Tests

    // bumpBalloon()

    function test_bumpBalloon_IncreasesContractBalance() public {
        address player = vm.addr(1);
        uint256 amount = 1 ether;
        playerBumpsBalloon(player, amount, 1);
        vm.roll(2);

        // Asserts
        assertEq(address(game).balance, amount);
        assertEq(game.lastBumper(), player);
        assertEq(game.balloonHeight(), amount);
        assertEq(game.lastBumpBlockNumber(), 1);
    }

    function testFuzz_bumpBalloon_IncreasesContractBalance(uint256 amount) public {
        vm.assume(amount > 0);
        address player = vm.addr(1);
        playerBumpsBalloon(player, amount, 1);
        vm.roll(2);

        // Asserts
        assertEq(address(game).balance, amount);
        assertEq(game.lastBumper(), player);
        assertEq(game.balloonHeight(), amount);
        assertEq(game.lastBumpBlockNumber(), 1);
    }

    // updateState()

    function test_updateState_BlockTimeMovesBalloonDown() public {
        address player = vm.addr(1);
        uint256 amount = 1 ether;
        uint256 blockNumberOfBump = 1;
        playerBumpsBalloon(player, amount, blockNumberOfBump);
        assertEq(game.balloonHeight(), amount);

        // 1 block elapsed since bump
        vm.roll(blockNumberOfBump + 1);
        game.updateState();
        assertEq(game.balloonHeight(), amount - 5);

        // 2 blocks elapsed since bump
        vm.roll(blockNumberOfBump + 2);
        game.updateState();
        assertEq(game.balloonHeight(), amount - 20);

        // 3 blocks elapsed since bump
        vm.roll(blockNumberOfBump + 3);
        game.updateState();
        assertEq(game.balloonHeight(), amount - 45);

        // 100 blocks elapsed since bump
        vm.roll(blockNumberOfBump + 100);
        game.updateState();
        assertEq(game.balloonHeight(), amount - 50000);
    }

    function test_updateState_NonOwnerCallingShouldRevert() public {
        vm.prank(vm.addr(2));
        vm.expectRevert();
        game.updateState();
    }

    function test_updateState_CallRefundPlayersIfTooLongSinceLastUpdate() public {
        address player = vm.addr(1);
        uint256 amount = 1 ether;
        uint256 blockNumberOfBump = 1;
        playerBumpsBalloon(player, amount, blockNumberOfBump);
        assertEq(game.balloonHeight(), amount);

        // 1 block elapsed since bump
        vm.roll(blockNumberOfBump + 1);
        game.updateState();
        assertEq(game.balloonHeight(), amount - 5);

        // This should refund the player and reset state.
        vm.roll(blockNumberOfBump + 1 + game.longestAllowableBlockCadenceForUpdates() + 1);
        game.updateState();
        assertEq(player.balance, 1 ether);
        assertGameStateIsReset();
    }

    // refundPlayers()

    function test_refundPlayers_NotAllowedWithinUpdateCadence() public {
        address player1 = vm.addr(1);
        address player2 = vm.addr(2);
        uint256 lastGameUpdateBlock = 0;

        // Player 1 bumps balloon by 100 ETH.
        playerBumpsBalloon(player1, 100 ether, lastGameUpdateBlock);

        // Refunds should not be allowed in the same block.
        vm.expectRevert();
        game.refundPlayers();
        assertEq(player1.balance, 0);
        assertEq(player2.balance, 0);

        // Update state.
        lastGameUpdateBlock++;
        vm.roll(lastGameUpdateBlock);
        game.updateState();

        // Player 2 bumps balloon by 1 ETH.
        playerBumpsBalloon(player2, 1 ether, lastGameUpdateBlock + 1);

        // Update state
        lastGameUpdateBlock++;
        game.updateState();

        // Refunds should not be allowed in the subsequent block.
        vm.roll(lastGameUpdateBlock + 1);
        vm.expectRevert();
        game.refundPlayers();
        assertEq(player1.balance, 0);
        assertEq(player2.balance, 0);

        // Refunds should not be allowed at the limit.
        vm.roll(lastGameUpdateBlock + game.longestAllowableBlockCadenceForUpdates());
        vm.expectRevert();
        game.refundPlayers();
        assertEq(player1.balance, 0);
        assertEq(player2.balance, 0);
    }

    function test_refundPlayers_AllowedAfterUpdateCadencePassed() public {
        address player1 = vm.addr(1);
        address player2 = vm.addr(2);
        uint256 lastGameUpdateBlock = 0;

        // Player 1 bumps balloon by 100 ETH.
        playerBumpsBalloon(player1, 100 ether, lastGameUpdateBlock);

        // Player 2 bumps balloon by 1 ETH.
        playerBumpsBalloon(player2, 1 ether, lastGameUpdateBlock);

        // Update state
        lastGameUpdateBlock++;
        game.updateState();

        // Refunds should be allowed after limit passed.
        vm.roll(lastGameUpdateBlock + game.longestAllowableBlockCadenceForUpdates() + 1);
        game.refundPlayers();
        assertEq(player1.balance, 100 ether);
        assertEq(player2.balance, 1 ether);

        // Game state should be reset.
        assertGameStateIsReset();
    }

    // calculateFallDistanceAndNewVelocity()

    function test_calculateFallDistanceAndNewVelocity_WithZeroVelocity() public {
        uint256 fallDistance;
        uint256 newVelocity;

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
    }

    function test_calculateFallDistanceAndNewVelocity_WithSomeInitialVelocity() public {
        uint256 fallDistance;
        uint256 newVelocity;

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
        assertEq(fallDistance, game.maxVelocity());
        assertEq(newVelocity, game.maxVelocity());

        (fallDistance, newVelocity) = game.exposed_calculateFallDistanceAndNewVelocity(game.maxVelocity() - 1, 1, 2);
        assertEq(fallDistance, game.maxVelocity() - 1);
        assertEq(newVelocity, game.maxVelocity());

        (fallDistance, newVelocity) = game.exposed_calculateFallDistanceAndNewVelocity(game.maxVelocity() - 1, 2, 1);
        assertEq(fallDistance, game.maxVelocity() * 2 - 1);
        assertEq(newVelocity, game.maxVelocity());
    }

    function test_calculateFallDistanceAndNewVelocity_WithNoAcceleration() public {
        uint256 fallDistance;
        uint256 newVelocity;

        (fallDistance, newVelocity) = game.exposed_calculateFallDistanceAndNewVelocity(100, 5, 0);
        assertEq(fallDistance, 500);
        assertEq(newVelocity, 100);
    }

    function test_calculateFallDistanceAndNewVelocity_WithExcessiveBlocksSinceLastUpdate_ShouldRevert() public {
        vm.expectRevert();
        game.exposed_calculateFallDistanceAndNewVelocity(0, UINT256_MAX - 1, 0);
    }

    // endGame()

    function test_endGame_PaysOutAndResetsState() public {
        address player = vm.addr(1);
        uint256 amount = 1 ether;

        playerBumpsBalloon(player, amount, 1);
        game.exposed_endGame();

        // Asserts
        assertEq(address(game).balance, 0);
        assertEq(player.balance, 1 ether);
        assertGameStateIsReset();
    }

    function test_endGame_NonOwnerCalling_ShouldRevert() public {
        vm.prank(vm.addr(2));
        vm.expectRevert();
        game.exposed_endGame();
    }
}
