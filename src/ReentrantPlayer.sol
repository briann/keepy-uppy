// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {console2} from "lib/forge-std/src/Test.sol";
import {KeepyUppy} from "src/KeepyUppy.sol";

contract ReentrantPlayer {
    receive() external payable {
        KeepyUppy game = KeepyUppy(msg.sender);
        game.refundPlayers();
    }
}
