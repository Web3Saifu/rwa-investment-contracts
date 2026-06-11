// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IInvestmentNFT is IERC721 {
    /**
     * @dev Struct to store NFT information
     */
    struct NFTInfo {
        uint256 tokenId;
        address owner;
        uint256 investmentAmount;
    }

    /**
     * @notice Thrown when attempting to deposit zero amount
     */
    error ZeroAmount();

    /**
     * @notice Issued when a new NFT is issued for investment
     * @param tokenId Unique identifier of the issued NFT
     * @param productId Investment product identifier
     * @param to Address of user who received the issued NFT
     * @param investmentAmount Investment amount that triggered the NFT issuance
     */
    event NFTMinted(uint256 indexed tokenId, uint256 indexed productId, address indexed to, uint256 investmentAmount);

    /**
     * @notice Issued when an NFT is burned
     * @param tokenId Unique identifier of the burned NFT
     * @param productId Investment product identifier
     * @param from Address of user who burned the NFT
     * @param investmentAmount Investment amount that triggered the NFT burn
     */
    event NFTBurned(uint256 indexed tokenId, uint256 indexed productId, address indexed from, uint256 investmentAmount);

    /**
     * @notice Get the current token ID counter value
     * @return The next token ID to be minted
     */
    function tokenIdCounter() external view returns (uint256);

    /**
     * @notice Get the product ID associated with this NFT contract
     * @return The unique identifier of the investment product
     */
    function productId() external view returns (uint256);

    /**
     * @notice Function to mint an NFT for an investor
     * @param to Address to receive the minted NFT
     * @param amount Investment amount
     * @return tokenId The ID of the minted token
     */
    function mint(address to, uint256 amount) external returns (uint256 tokenId);

    /**
     * @notice Function to burn an NFT
     * @param tokenId The ID of the token to burn
     */
    function burn(uint256 tokenId) external;

    /**
     * @notice Function to retrieve NFT information
     * @param startTokenId The starting token ID
     * @return nftInfos An array of NFT information
     */
    function getNFTInfos(uint256 startTokenId) external view returns (NFTInfo[] memory);

    /**
     * @notice Retrieve the investment amount for a specific token ID
     * @param tokenId The ID of the token
     * @return The investment amount
     */
    function getInvestmentAmount(uint256 tokenId) external view returns (uint256);
}
