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
        address(game).call{value: 100}(abi.encodeWithSignature("bumpBalloon"));
    }

    function testFuzz_bumpBalloon(uint256 _amount) public {
        address(game).call{value: _amount}(abi.encodeWithSignature("bumpBalloon"));
    }
}
