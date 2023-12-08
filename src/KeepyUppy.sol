// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract KeepyUppy {
    uint256 public storedValue = 0;

    function bumpBalloon(uint256 bumpStrength) public {
        storedValue += bumpStrength;
    }
}
