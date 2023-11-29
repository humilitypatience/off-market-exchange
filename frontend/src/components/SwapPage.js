import { ConnectButton } from "@rainbow-me/rainbowkit";
import React, { useState, useEffect } from "react";
import { AiOutlineSwap } from "react-icons/ai";
import { useAccount } from "wagmi";
import SwapSession from "./SwapSession";
import { Alchemy, Network } from "alchemy-sdk";
import sha256 from "crypto-js/sha256";
import { ethers } from "ethers";
import { depositFromAcc1, completeSwap } from "../utils/Interact";
const config = {
  apiKey: "Jyuuy4MI_u6RLY8TlkGasdskg1CJeIhE",
  network: Network.MATIC_MUMBAI,
};
const alchemy = new Alchemy(config);

const SwapPage = () => {
  const [amount, setAmount] = useState("");
  const [freezeClicked, setFreezeClicked] = useState(false); // Track Freeze button click
  const { address, isConnected } = useAccount();
  const [nfts, setNfts] = useState([]);
  const [selectedNft, setSelectedNft] = useState(null);
  const [showNftSelector, setShowNftSelector] = useState(false);
  const [sessionURL, setSessionURL] = useState("");
  const baseURL = "https://atomic-swap98.vercel.app/swap";

  const fetchNFTs = async (walletAddress) => {
    console.log("Fetching NFTs for address:", walletAddress);
    try {
      const balances = await alchemy.core.getTokenBalances("0xd8da6bf26964af9d7eed9e03e53415d37aa96045");

      const metadataPromises = balances.tokenBalances.map(async (token) => {
        const metadata = await alchemy.core.getTokenMetadata(token.contractAddress);
        return metadata
      })

      const metadatas = await Promise.all(metadataPromises)

      const formattedDatas = metadatas.map((data, key) => {
        return {
        address: key,
        title: data.name,
        tokenId: key,
        image: data.logo
      }})

      console.log("metadatas", metadatas)

      setNfts(formattedDatas);
      // console.log("formatted data", formattedDatas)
    } catch (error) {
      console.error("Error fetching NFTs:", error);
    }
  };

  const initializeEthers = async () => {
    try {
      // Connect to an Ethereum provider (e.g., MetaMask)
      const provider = new ethers.providers.Web3Provider(window.ethereum);

      // Access the user's account address
      const [account] = await provider.listAccounts();
      console.log("Connected account:", account);

      // Example: Retrieve the balance
      const balance = await provider.getBalance(account);
      console.log("Balance:", ethers.utils.formatEther(balance));
      return provider;
    } catch (error) {
      console.error("Error initializing ethers:", error.message);
    }
  };
  useEffect(() => {
    const getEthers = async () => {
      const provider = await initializeEthers();
      console.log(provider);
    };
    getEthers();
  }, []);

  const handleNftSelect = (nft) => {
    console.log("Selected NFT:", nft);
    setSelectedNft(nft);
    setShowNftSelector(false);
  };

  useEffect(() => {
    if (isConnected && address) {
      fetchNFTs(address);
    }
  }, [address, isConnected]);
  const handleConnect = () => {
    setShowModal(true);
  };

  const handleDisconnect = () => {
    // Implement disconnect logic if needed
    setShowModal(false);
  };

  const handleAmountChange = (e) => {
    setAmount(e.target.value);
  };

  const handleConfirm = () => {
    // Implement logic to handle the confirmed amount
    console.log("Amount confirmed:", amount);
    setShowModal(false);
  };
  const handleCopyLink = () => {
    // Implement copy link logic
    console.log("Link copied to clipboard");
  };

  const generateSessionId = () => {
    if (!address || !selectedNft.address || !selectedNft.tokenId) {
      setError("Invalid token or user information.");
      return;
    }

    // setIsLoading(true);
    console.log("Generating session ID...");

    try {
      const uniqueId = sha256(
        `${address}-${selectedNft.address}-${selectedNft.tokenId}-${Date.now()}`
      ).toString();
      // setSessionId(uniqueId);
      console.log("Session ID set:", uniqueId);
      const sessionURL = `${baseURL}?session_id=${uniqueId}&userAddress=${encodeURIComponent(
        address
      )}&title=${encodeURIComponent(selectedNft.title)}`;
      setSessionURL(sessionURL);
      return sessionURL;
    } catch (e) {
      console.error("Error generating session ID:", e);
      // setError("Failed to generate session ID.");
    } finally {
      // setIsLoading(false);
    }
  };

  const handleFreezeClick = async () => {
    setFreezeClicked(true);
    const provider = await initializeEthers();
    console.log("this is the URL which we r sending from user1 for bytes 32 hash", sessionURL);
    depositFromAcc1(
      sessionURL,
      provider,
      selectedNft.address,
      selectedNft.tokenId
    );
  };

  const handleSignClick = async () => {
    const provider = await initializeEthers();
    const bytes32SessionId = ethers.utils.solidityKeccak256(
      ["string"],
      [sessionURL],
    );
    completeSwap(provider, bytes32SessionId);

  }

  return (
    <div className="flex h-screen bg-gradient-to-r from-blue-500 to-indigo-500 text-white">
      {/* Left Side */}
      <div className="flex-1 flex flex-col items-center justify-center p-6">
        <ConnectButton accountStatus="address" chainStatus="icon" />

        {isConnected ? (
          <div className="mt-4">
            <h2 className="text-lg font-semibold">Selected NFT</h2>

            {selectedNft && (
              <div className="bg-gray-200 p-2 my-1 rounded text-black">
                {selectedNft.title} - ID: {selectedNft.tokenId}
              </div>
            )}

            <button
              onClick={() => setShowNftSelector(!freezeClicked && true)} // Enable button if Freeze not clicked
              className={`${freezeClicked
                  ? "bg-gray-400 cursor-not-allowed"
                  : "bg-blue-700 hover:bg-blue-600"
                } text-white px-4 py-2 mt-2 rounded transition-all duration-300`}
              disabled={freezeClicked}
            >
              Select NFT
            </button>
          </div>
        ) : (
          <p className="mt-4">Please connect your wallet</p>
        )}

        {showNftSelector && (
          <div className="absolute w-72 max-h-96 overflow-y-auto bg-white border border-gray-300 p-4 rounded-lg shadow-lg">
            <h2 className="text-lg font-semibold mb-2 text-black">
              Select an NFT for swap
            </h2>

            {nfts.map((nft) => (
              <div
                key={`${nft.address}-${nft.tokenId}`}
                onClick={() => handleNftSelect(nft)}
                className="p-2 bg-transparent border-b border-gray-300 cursor-pointer hover:bg-gray-100 text-black flex items-center"
              >
                <img
                  src={nft.image}
                  alt={nft.title}
                  className="w-10 h-10 mr-2"
                />
                {nft.title}
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Center */}
      <div className="w-12 flex flex-col items-center justify-center p-6">
        <div className="bg-white p-2 rounded-full">
          <AiOutlineSwap size={30} color="#4A5568" />
        </div>

        <div className="flex flex-col space-y-4 mt-6">
          <button
            onClick={handleFreezeClick}
            className={`${freezeClicked
                ? "bg-gray-400 cursor-not-allowed"
                : "bg-green-500 hover:bg-green-400"
              } text-white py-2 px-4 rounded transition-all duration-300`}
            disabled={freezeClicked}
          >
            Freeze
          </button>

          <button
            onClick={handleSignClick}
            className={`${false
                ? "bg-gray-400 cursor-not-allowed"
                : "bg-red-500 hover:bg-red-400"
              } text-white py-2 px-4 rounded transition-all duration-300`}
          >
            Sign
          </button>
        </div>
      </div>

      {/* Right Side */}
      <div className="flex-1 flex flex-col items-center justify-center p-6">
        <div className="flex flex-col items-center space-y-4">
          {selectedNft && (
            <SwapSession
              sessionID={sessionURL}
              generateSessionId={generateSessionId}
              userAddress={address}
              tokenContractAddress={selectedNft.address}
              tokenId={selectedNft.tokenId}
              title={selectedNft.title}
            />
          )}
        </div>
      </div>
    </div>
  );
};

export default SwapPage;
