// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "forge-std/StdCheats.sol";
import "forge-std/Vm.sol";


import "../src/AtomicSwap.sol";
import "../src/Tokens.sol";

contract TestAtomicSwap is Test {
    AtomicSwap atomicswap;
    Token token; 
    address public User1 = address(1);
    address public receiver = address(2);

    function setUp() public {
        atomicswap = new AtomicSwap();
        token = new Token();
        console.log("Atomic Swap and Token deployed successfully");
    }

    function testEth_payment() public {
         setUp();
          uint256 initialBalance = atomicswap.viewBalance();
          assertEq(initialBalance, 0);
         bytes32 testId = keccak256(abi.encodePacked("Eth_payment"));
         bytes20 secretHash = ripemd160(abi.encodePacked("secret"));
         uint64 lockTime = uint64(block.timestamp + 1 hours);

        vm.deal(User1 , 1 ether);
        vm.prank(User1);
        atomicswap.ethPayment{value : 1 ether}(testId,receiver,secretHash,lockTime);
        uint256 balance = atomicswap.viewBalance();
        assertEq(balance , 1 ether);
        uint256 msgvalue = 1 ether;

        (bytes20 Id , uint64 locktime ,AtomicSwap.PaymentState state) = atomicswap.payments(testId);
        // assertEq(Id, ripemd160(abi.encodePacked(receiver, address(this), secretHash, address(0), msgvalue)));
        assertEq(locktime, lockTime);
        assertEq(uint256(state), uint(AtomicSwap.PaymentState.PaymentSent));
    }
    function toHexString(bytes20 data) internal pure returns (string memory) {
    bytes memory alphabet = "0123456789abcdef";
    bytes memory str = new bytes(40);
    for (uint256 i = 0; i < 20; i++) {
        str[i*2] = alphabet[uint8(data[i] >> 4)];
        str[1+i*2] = alphabet[uint8(data[i] & 0x0f)];
    }
    return string(str);
}


   function testNewContractHasUninitializedPayments() public {
    setUp();
    bytes32 testId = keccak256(abi.encodePacked("test"));
    (,, AtomicSwap.PaymentState state) = atomicswap.payments(testId);
    console.log(uint256(state));
    assertEq(uint(state), uint(AtomicSwap.PaymentState.Uninitialized), "Payment should be uninitialized");
}


    // function testUser1SubmitsEthAndUser2SubmitsErc20() public {
    //     bytes32 ethPaymentId = keccak256(abi.encodePacked("ethPayment"));
    //     bytes32 erc20PaymentId = keccak256(abi.encodePacked("erc20Payment"));
    //     bytes20 secretHash = ripemd160(abi.encodePacked("secret"));
    //     uint64 lockTime = uint64(block.timestamp + 1 hours);
    //     uint256 ethAmount = 1 ether;
    //     uint256 erc20Amount = 30; 

       
    //     vm.prank(receiver);
    //     token.mint(receiver ,erc20Amount);  
    //     testEth_payment();



    //     vm.startPrank(receiver);
    //     token.approve(address(atomicswap), erc20Amount);
    //     atomicswap.erc20Payment(erc20PaymentId, erc20Amount, address(token), User1, secretHash, lockTime);
    //     vm.stopPrank();

    // }
}
