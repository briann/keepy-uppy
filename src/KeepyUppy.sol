// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract KeepyUppy {

    address public lastBumper;

    function bumpBalloon() external payable {
        require(msg.value > 0);
        lastBumper = msg.sender;
    }
}
