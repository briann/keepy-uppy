// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {KeepyUppy} from "../src/KeepyUppy.sol";

contract KeepyUppyTest is Test {
    KeepyUppy public game;
    address player;

    function setUp() public {
        player = vm.addr(1);
        game = new KeepyUppy();
    }

    function test_bumpBalloon() public {
        vm.prank(player);
        vm.deal(player, 1 ether);
        game.bumpBalloon{value: 1 ether}();
        assertEq(address(game).balance, 1 ether);
    }

    function testFuzz_bumpBalloon(uint256 _amount) public {
        vm.assume(_amount > 0);
        vm.prank(player);
        vm.deal(player, _amount);
        game.bumpBalloon{value: _amount}();
        assertEq(address(game).balance, _amount);
    }

    function test_payout() public {
        vm.prank(player);
        vm.deal(player, 1 ether);
        game.bumpBalloon{value: 1 ether}();

        game.payout();
        assertEq(address(game).balance, 0);
        assertEq(player.balance, 1 ether);
    }

    function test_payout_onlyOwner() public {
        vm.prank(player);
        vm.deal(player, 1 ether);
        game.bumpBalloon{value: 1 ether}();

        vm.prank(vm.addr(2));
        vm.expectRevert();
        game.payout();
    }
}
