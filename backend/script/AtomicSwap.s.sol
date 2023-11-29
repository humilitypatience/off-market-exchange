// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../src/AtomicSwap.sol";
import "../src/NftAtomicswap.sol";
import "../src/Tokens.sol";

import {Script, console2} from "forge-std/Script.sol";
import "forge-std/console2.sol"; 
import "forge-std/StdCheats.sol";
import "forge-std/Vm.sol";
import "forge-std/Test.sol";

contract DeployAtomicSwap is Script {
    function setUp() public {}

    function run() public {
        uint256 privatekey =  vm.envUint("PRIVATE_KEY");
       address account = vm.addr(privatekey);
       console.log(account);

       
        vm.startBroadcast(privatekey);
        // AtomicSwap atomicswap  = new AtomicSwap();
        // Token token = new Token();
        NftAtomicSwap nftAtomicSwap = new NftAtomicSwap();

        vm.stopBroadcast();
    }
}
