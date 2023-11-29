// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NftAtomicSwap {
    enum SwapState {
        Uninitialized,
        User1Deposited,
        User2Deposited,
        Completed,
        Refunded
    }

    struct SwapSession {
        SwapState state;
        address user1;
        address user2;
        address nftAddress1;
        address nftAddress2;
        uint256 tokenId1;
        uint256 tokenId2;
        uint64 lockTime;
    }

    mapping (bytes32 => SwapSession) public swapSessions;

    // Events
    event User1NftDeposited(bytes32 indexed sessionId, address indexed depositor, address nftAddress, uint256 tokenId);
    event User2NftDeposited(bytes32 indexed sessionId, address indexed depositor, address nftAddress, uint256 tokenId);
    event SwapCompleted(bytes32 indexed sessionId);
    event SwapCancelled(bytes32 indexed sessionId);

    // User 1 deposits their NFT
    function depositUser1NFT(
        bytes32 _sessionId,
        address _nftAddress,
        uint256 _tokenId
    ) external {
        require(_nftAddress != address(0), "Invalid NFT address");
        require(swapSessions[_sessionId].state == SwapState.Uninitialized, "Session already initialized");

        IERC721 nft = IERC721(_nftAddress);
        require(nft.ownerOf(_tokenId) == msg.sender, "Sender does not own the NFT");
        require(nft.getApproved(_tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)), "Contract not approved to transfer NFT");

        uint64 _lockTime = uint64(block.timestamp + 3600); 

        swapSessions[_sessionId] = SwapSession(
            SwapState.User1Deposited,
            msg.sender,
            address(0),
            _nftAddress,
            address(0),
            _tokenId,
            0,
            _lockTime
        );

        nft.transferFrom(msg.sender, address(this), _tokenId);
        emit User1NftDeposited(_sessionId, msg.sender, _nftAddress, _tokenId);
    }

    // User 2 deposits their NFT
    function depositUser2NFT(
        bytes32 _sessionId,
        address _nftAddress,
        uint256 _tokenId
    ) external {
        SwapSession storage session = swapSessions[_sessionId];
        require(session.state == SwapState.User1Deposited, "User 1 NFT not deposited");
        require(_nftAddress != address(0), "Invalid NFT address");
        IERC721 nft = IERC721(_nftAddress);
        require(nft.ownerOf(_tokenId) == msg.sender, "Sender does not own the NFT");
        require(nft.getApproved(_tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)), "Contract not approved to transfer NFT");
        session.user2 = msg.sender;
        session.nftAddress2 = _nftAddress;
        session.tokenId2 = _tokenId;
        session.state = SwapState.User2Deposited;

        nft.transferFrom(msg.sender, address(this), _tokenId);
        emit User2NftDeposited(_sessionId, msg.sender, _nftAddress, _tokenId);
    }

    // Completing the Swap
    function completeSwap(bytes32 _sessionId) external {
        SwapSession storage session = swapSessions[_sessionId];
        require(session.state == SwapState.User2Deposited, "Both NFTs must be deposited");
        require(block.timestamp <= session.lockTime, "Lock time expired");

        IERC721 nft1 = IERC721(session.nftAddress1);
        IERC721 nft2 = IERC721(session.nftAddress2);

        nft1.transferFrom(address(this), session.user2, session.tokenId1);
        nft2.transferFrom(address(this), session.user1, session.tokenId2);

        session.state = SwapState.Completed;
        emit SwapCompleted(_sessionId);
    }

    function refundNFT(bytes32 _sessionId) external {
    SwapSession storage session = swapSessions[_sessionId];
    // Ensure the session is in a state where a refund is possible
    require(
        session.state == SwapState.User1Deposited || session.state == SwapState.User2Deposited,
        "Refund not applicable"
    );
    require(block.timestamp > session.lockTime, "Lock time has not expired");

    // Check if the sender is either User 1 or User 2
    bool isUser1 = (session.user1 == msg.sender);
    bool isUser2 = (session.user2 == msg.sender);

    require(isUser1 || isUser2, "Unauthorized refund request");

    if (isUser1 && session.nftAddress1 != address(0)) {
        IERC721 nft1 = IERC721(session.nftAddress1);
        nft1.transferFrom(address(this), session.user1, session.tokenId1);
        session.nftAddress1 = address(0); 
    }

    if (isUser2 && session.nftAddress2 != address(0)) {
        IERC721 nft2 = IERC721(session.nftAddress2);
        nft2.transferFrom(address(this), session.user2, session.tokenId2);
        session.nftAddress2 = address(0); 
    }

    if (session.nftAddress1 == address(0) && session.nftAddress2 == address(0)) {
        session.state = SwapState.Refunded;
        emit SwapCancelled(_sessionId);
    }
}

}