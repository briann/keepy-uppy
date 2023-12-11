// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract KeepyUppy {

    address public lastBumper;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner allowed");
        _;
    }

    function bumpBalloon() external payable {
        require(msg.value > 0);
        lastBumper = msg.sender;
    }

    function payout() public onlyOwner {
        payable(lastBumper).transfer(address(this).balance);
    }
}
