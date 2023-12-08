// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {KeepyUppy} from "../src/KeepyUppy.sol";

contract KeepyUppyTest is Test {
    KeepyUppy public game;

    function setUp() public {
        game = new KeepyUppy();
    }

    function test_bumpBalloon() public {
        game.bumpBalloon(1);
        assertEq(game.storedValue(), 1);
    }

    function testFuzz_bumpBalloon(uint256 x) public {
        game.bumpBalloon(x);
        assertEq(game.storedValue(), x);
    }
}
