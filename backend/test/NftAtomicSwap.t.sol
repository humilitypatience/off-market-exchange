// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../src/NftAtomicswap.sol";
import "../src/mockerc721.sol";

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "forge-std/StdCheats.sol";
import "forge-std/Vm.sol";

contract TestNftAtomicSwap is Test {
    NftAtomicSwap public nftAtomicSwap;
    MockERC721 public mockERC721;
    address public owner;
    address public receiver;

    function setUp() public {
        owner = address(1); 
        receiver = address(2); 

        mockERC721 = new MockERC721("TestNFT", "TNFT");

        nftAtomicSwap = new NftAtomicSwap();

        vm.startPrank(owner);
        mockERC721.mint(owner);
        mockERC721.approve(address(nftAtomicSwap), 1);
        vm.stopPrank();
    }

    function testdepositNFT() public {
        setUp();

        bytes32 id = keccak256("unique_swap_id");
        address nftAddress = address(mockERC721);
        uint256 tokenId = 1; 
        
        bytes20 secretHash =  ripemd160(abi.encodePacked(sha256(abi.encodePacked("secret_value"))));
        uint64 lockTime = uint64(block.timestamp + 1 days);

        vm.startPrank(owner);
        nftAtomicSwap.depositNFT(id, nftAddress, tokenId, receiver, secretHash, lockTime);
        vm.stopPrank();

        (bytes20 paymentHash, uint64 lockTimeRecord, NftAtomicSwap.PaymentState state,address _tokenAddress , uint256 _tokenId) = nftAtomicSwap.payments(id);
        console.logBytes20(paymentHash);
        assertEq(uint256(state), uint256(NftAtomicSwap.PaymentState.PaymentSent));

        address currentOwner = IERC721(nftAddress).ownerOf(tokenId);
        assertEq(currentOwner, address(nftAtomicSwap));
    }   

function testCompleteNFTSwap() public {
    testdepositNFT(); 

    bytes32 id = keccak256("unique_swap_id");
    bytes32 secret = bytes32(abi.encodePacked("secret_value")); 

    vm.startPrank(receiver); 
    bytes20 paymentHash1 = ripemd160(abi.encodePacked(
        msg.sender, 
        owner,
        ripemd160(abi.encodePacked(sha256(abi.encodePacked("secret_value")))),
        address(mockERC721),
        uint256(1)
    ));
    console.logBytes20(paymentHash1);

    (bytes20 paymentHash, , , , ) = nftAtomicSwap.payments(id);
    console.logBytes20(paymentHash);

    
    nftAtomicSwap.completeNFTSwap(id, secret, address(mockERC721), 1, owner);
    vm.stopPrank();

    address currentOwner = IERC721(address(mockERC721)).ownerOf(1);
    assertEq(currentOwner, receiver, "NFT should be transferred to the receiver");

    (, , NftAtomicSwap.PaymentState state, , ) = nftAtomicSwap.payments(id);
    assertEq(uint256(state), uint256(NftAtomicSwap.PaymentState.ReceiverSpent));
}
}