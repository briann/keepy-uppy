// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "lib/forge-std/src/Script.sol";
import {KeepyUppy} from "src/KeepyUppy.sol";

contract KeepyUppyScript is Script {
    function run() public {
        vm.broadcast(vm.envUint("PRIVATE_KEY"));
        KeepyUppy game = new KeepyUppy(100, 10 wei);
        console2.log("Deployed game to", address(game));
    }
}
