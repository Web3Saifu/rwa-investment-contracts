// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "bundle/periphery/interfaces/IInvestmentNFT.sol";
import "bundle/investment/interfaces/IInvestment.sol";

/**
 * @title InvestmentNFT
 * @dev NFT contract to manage investment units
 */


contract InvestmentNFT is IInvestmentNFT, ERC721, Ownable {
    // Token ID counter (managed with uint256 instead of Counters library)
    uint256 public tokenIdCounter;

    // Product ID
    uint256 public productId;

    // Investment contract address
    address public investmentContract;

    // Base URI for token metadata (single fixed metadata.json URL for all NFTs)
    string private baseTokenURI;

    // Mapping from token ID to investment amount
    mapping(uint256 => uint256) private _investmentAmounts;

    event BaseTokenURIUpdated(string newBaseTokenURI);

    /**
     * @notice Constructor for the contract
     * @param name Name of the NFT collection
     * @param symbol Symbol of the NFT collection
     * @param _productId The product ID associated with this contract
     * @param _baseTokenURI Single fixed metadata.json URL for all NFTs (e.g., "https://s3.../metadata.json")
     * @param _investmentContract Address of the Investment contract
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 _productId,
        string memory _baseTokenURI,
        address _investmentContract
    ) ERC721(name, symbol) Ownable(msg.sender) {
        tokenIdCounter = 0;
        productId = _productId;
        baseTokenURI = _baseTokenURI;
        investmentContract = _investmentContract;
    }

    /**
     * @notice Returns the base URI for token metadata
     * @dev Overrides ERC721._baseURI() to return the baseTokenURI
     * @return The base URI string
     */
    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @notice Returns the token URI (same for all tokens)
     * @dev Overrides ERC721.tokenURI() to return a single fixed metadata URL for all NFTs
     *      All NFTs in this contract share the same metadata.json file
     * @param tokenId The token ID (unused, but required by interface)
     * @return The metadata URI (same for all tokens)
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        return baseTokenURI;
    }

    /**
     * @notice Sets the metadata URI (single fixed URL for all NFTs, admin-only version)
     * @dev Only callable by Investment contract admins
     *      All NFTs in this contract will return this same metadata.json URL
     * @param newBaseTokenURI The new metadata.json URL (e.g., "https://s3.../metadata.json")
     */
    function setURI(string memory newBaseTokenURI) external {
        // Get admin list from Investment contract
        address[] memory adminList = IInvestment(investmentContract).getAdminList();

        // Check if sender is an admin
        bool isAdmin = false;
        for (uint256 i = 0; i < adminList.length; i++) {
            if (adminList[i] == msg.sender) {
                isAdmin = true;
                break;
            }
        }

        if (!isAdmin) {
            revert Ownable.OwnableUnauthorizedAccount(msg.sender);
        }

        baseTokenURI = newBaseTokenURI;
        emit BaseTokenURIUpdated(newBaseTokenURI);
    }

    /**
     * @notice Function to mint an NFT for an investor
     * @param to Address to receive the minted NFT
     * @param amount Investment amount
     * @return tokenId The ID of the minted token
     */
    function mint(address to, uint256 amount) external onlyOwner returns (uint256 tokenId) {
        // Revert if the investment amount is zero or less
        if (amount <= 0) {
            revert IInvestmentNFT.ZeroAmount();
        }
        // Increment the token ID counter
        tokenIdCounter++;
        // Mint the token
        _safeMint(to, tokenIdCounter);
        // Record the investment amount
        _investmentAmounts[tokenIdCounter] = amount;
        emit IInvestmentNFT.NFTMinted(tokenIdCounter, productId, to, amount);
        return tokenIdCounter;
    }

    /**
     * @notice Function to burn an NFT
     * @param tokenId The ID of the token to burn
     */
    function burn(uint256 tokenId) external onlyOwner {
        address owner = ownerOf(tokenId);
        _burn(tokenId);
        emit IInvestmentNFT.NFTBurned(tokenId, productId, owner, _investmentAmounts[tokenId]);
        delete _investmentAmounts[tokenId];
    }

    /**
     * @notice Function to retrieve NFT information
     * @param startTokenId The starting token ID
     * @return nftInfos An array of NFT information
     */
    function getNFTInfos(uint256 startTokenId) external view returns (NFTInfo[] memory) {
        // Calculate the ending token ID (up to 50 items)
        uint256 endTokenId = startTokenId + 49 < tokenIdCounter ? startTokenId + 49 : tokenIdCounter;

        // Calculate the number of NFTs to retrieve
        uint256 length = endTokenId >= startTokenId ? endTokenId - startTokenId + 1 : 0;

        // Initialize the array for NFT information
        NFTInfo[] memory nftInfos = new NFTInfo[](length);

        // Retrieve NFT information
        for (uint256 i = 0; i < length; i++) {
            uint256 tokenId = startTokenId + i;
            nftInfos[i] =
                NFTInfo({tokenId: tokenId, owner: ownerOf(tokenId), investmentAmount: _investmentAmounts[tokenId]});
        }

        return nftInfos;
    }

    /**
     * @notice Retrieve the investment amount for a specific token ID
     * @param tokenId The ID of the token
     * @return The investment amount
     */
    function getInvestmentAmount(uint256 tokenId) external view returns (uint256) {
        return _investmentAmounts[tokenId];
    }
}

// Testing
import "forge-std/Test.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {Schema} from "bundle/investment/storage/Schema.sol";

// Mock Investment contract for testing
contract MockInvestment is IInvestment {
    address[] public admins;

    function setAdmins(address[] memory _admins) external {
        admins = _admins;
    }

    function getAdminList() external view returns (address[] memory) {
        return admins;
    }

    // Empty implementations for other interface functions
    function registerProduct(Schema.RegisterProductArgs calldata) external {}
    function invest(uint256, uint256) external {}
    function mintNFT(uint256, uint256, address) external {}
    function withdraw(uint256, uint256) external {}
    function deposit(uint256, uint256) external {}
    function distributeYield(uint256) external {}
    function maturity(uint256) external {}
    function claimYield(uint256, uint256, uint256) external {}
    function claimPrincipal(uint256, uint256) external {}
    function addAdmin(address) external {}
    function deleteAdmin(address) external {}
    function addMinter(address) external {}
    function deleteMinter(address) external {}
    function getProduct(uint256) external pure returns (Schema.Product memory) {}
    function getAllProducts() external pure returns (Schema.Product[] memory) {}
    function getActiveProducts() external pure returns (Schema.Product[] memory) {}

    function simulatePeriodYield(uint256) external pure returns (uint256[] memory) {
        return new uint256[](0);
    }

    function simulateTotalYield(uint256) external pure returns (uint256) {
        return 0;
    }

    function setAllowedByTierAddress(uint8, address[] calldata) external {}

    function setAllowedByTierId(uint8, address, uint256[] calldata) external {}

    function setProductRequiredTier(uint256, uint8) external {}

    function getAllowedByTierAddress(uint8) external pure returns (address[] memory) {
        return new address[](0);
    }

    function getAllowedByTierId(uint8, address) external pure returns (uint256[] memory) {
        return new uint256[](0);
    }

    function getDistributionDates(uint256) external pure returns (uint256[] memory) {
        return new uint256[](0);
    }

    function simulateIndividualPeriodYield(uint256, uint256) external pure returns (uint256[] memory) {
        return new uint256[](0);
    }

    function simulateIndividualTotalYield(uint256, uint256) external pure returns (uint256) {
        return 0;
    }

    function getUnclaimedYield(uint256, uint256, uint256) external pure returns (uint256) {
        return 0;
    }

    function getUnclaimedPrincipal(uint256, uint256) external pure returns (uint256) {
        return 0;
    }

    function getClaimableYieldSlots(uint256, uint256) external pure returns (Schema.ClaimableYieldSlot[] memory) {
        return new Schema.ClaimableYieldSlot[](0);
    }

    function getClaimableForToken(uint256, uint256, address)
        external
        pure
        returns (Schema.TokenClaimableStatus memory status)
    {
        return status;
    }
}

contract InvestmentNFTTest is Test {
    event BaseTokenURIUpdated(string newBaseTokenURI);

    InvestmentNFT investmentNFT;
    MockInvestment mockInvestment;
    address owner;
    address minter1;
    address minter2;
    address nonOwner;
    address admin1;

    using stdStorage for StdStorage;

    function setUp() public {
        owner = makeAddr("owner");
        minter1 = makeAddr("minter1");
        minter2 = makeAddr("minter2");
        nonOwner = makeAddr("nonOwner");
        admin1 = makeAddr("admin1");

        // Deploy mock Investment contract
        mockInvestment = new MockInvestment();
        address[] memory admins = new address[](1);
        admins[0] = admin1;
        mockInvestment.setAdmins(admins);

        // Deploy the contract as the owner
        vm.prank(owner);
        investmentNFT = new InvestmentNFT(
            "InvestmentNFT",
            "INVT",
            99,
            "https://example.com/metadata/",
            address(mockInvestment) // Mock investment contract address for testing
        );
    }

    /// @notice Test case for successful minting
    function testMint_success() public {
        vm.expectEmit(true, true, true, true);
        emit IInvestmentNFT.NFTMinted(1, 99, minter1, 100);

        // Owner mints a token
        vm.prank(owner);
        investmentNFT.mint(minter1, 100);

        // Verify that token ID 1 is minted correctly
        assertEq(investmentNFT.ownerOf(1), minter1);
        uint256 investmentAmount = investmentNFT.getInvestmentAmount(1);
        assertEq(investmentAmount, 100);
    }

    /// @notice Test case where non-owner tries to mint and fails
    function testMint_fail_nonOwner() public {
        // Non-owner tries to mint
        vm.prank(nonOwner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, nonOwner));
        investmentNFT.mint(minter1, 100);
    }

    /// @notice Test case where minting with zero investment amount fails
    function testMint_fail_zeroInvestmentAmount() public {
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(IInvestmentNFT.ZeroAmount.selector));
        investmentNFT.mint(minter1, 0);
    }

    /// @notice Test case for successful burning of a token
    function testBurn_success() public {
        // Owner mints two tokens
        vm.startPrank(owner);
        investmentNFT.mint(minter1, 100);
        investmentNFT.mint(minter2, 200);

        vm.expectEmit(true, true, true, true);
        emit IInvestmentNFT.NFTBurned(1, 99, minter1, 100);

        // Owner burns the first token
        investmentNFT.burn(1);

        // Verify that the token no longer exists
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, 1));
        investmentNFT.ownerOf(1);

        // Verify that the investment amount is removed
        uint256 investmentAmount = investmentNFT.getInvestmentAmount(1);
        assertEq(investmentAmount, 0);
    }

    /// @notice Test case where non-owner tries to burn and fails
    function testBurn_fail_nonOwner() public {
        // Owner mints a token
        vm.prank(owner);
        investmentNFT.mint(minter1, 100);

        // Non-owner tries to burn the token
        vm.prank(nonOwner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, nonOwner));
        investmentNFT.burn(1);
    }

    /// @notice Test case for minting after burning a token
    function testMint_afterBurn_newTokenId() public {
        vm.startPrank(owner);
        investmentNFT.mint(minter1, 100);
        investmentNFT.burn(1);
        investmentNFT.mint(minter1, 200);
        vm.stopPrank();

        // Verify that the new token ID is assigned correctly
        assertEq(investmentNFT.ownerOf(2), minter1);
        uint256 investmentAmount = investmentNFT.getInvestmentAmount(2);
        assertEq(investmentAmount, 200);

        // Verify that the old token ID no longer exists
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, 1));
        investmentNFT.ownerOf(1);
    }

    /// @notice Test case for getNFTInfos function when 50 tokens exist
    function testgetNFTInfos_full() public {
        // Owner mints 50 NFTs
        vm.startPrank(owner);
        for (uint256 i = 1; i <= 50; i++) {
            investmentNFT.mint(minter1, i);
        }
        vm.stopPrank();

        // Retrieve NFT information
        IInvestmentNFT.NFTInfo[] memory nftInfos = investmentNFT.getNFTInfos(1);

        // Verify the number of retrieved NFTs
        assertEq(nftInfos.length, 50);

        // Verify each NFT's information
        for (uint256 i = 0; i < 50; i++) {
            assertEq(nftInfos[i].tokenId, i + 1);
            assertEq(nftInfos[i].owner, minter1);
            assertEq(nftInfos[i].investmentAmount, i + 1);
        }
    }


    /// @notice Test case for getNFTInfos function when fewer than 50 tokens exist
    function testgetNFTInfos_partial() public {
        // Owner mints 30 NFTs
        vm.startPrank(owner);
        for (uint256 i = 1; i <= 30; i++) {
            investmentNFT.mint(minter1, i * 10);
        }
        vm.stopPrank();

        // Retrieve NFT information
        IInvestmentNFT.NFTInfo[] memory nftInfos = investmentNFT.getNFTInfos(1);

        // Verify the number of retrieved NFTs
        assertEq(nftInfos.length, 30);

        // Verify each NFT's information
        for (uint256 i = 0; i < 30; i++) {
            assertEq(nftInfos[i].tokenId, i + 1);
            assertEq(nftInfos[i].owner, minter1);
            assertEq(nftInfos[i].investmentAmount, (i + 1) * 10);
        }
    }

    /// @notice Test case for getNFTInfos function when the starting token ID does not exist
    function testgetNFTInfos_startTokenIdNonExistent() public {
        vm.prank(owner);
        investmentNFT.mint(minter1, 100);

        // Start from a non-existent token ID
        IInvestmentNFT.NFTInfo[] memory nftInfos = investmentNFT.getNFTInfos(10);

        // Verify that the result is empty
        assertEq(nftInfos.length, 0);
    }

    /// @notice Test case for getNFTInfos function when exceeding token ID range
    function testgetNFTInfos_exceedingTokenIdRange() public {
        vm.startPrank(owner);
        for (uint256 i = 1; i <= 5; i++) {
            investmentNFT.mint(minter1, i * 10);
        }

        // Retrieve NFTs from a range exceeding the maximum token ID
        IInvestmentNFT.NFTInfo[] memory nftInfos = investmentNFT.getNFTInfos(3);

        // Verify that only existing NFTs are returned
        assertEq(nftInfos.length, 3);
        for (uint256 i = 0; i < 3; i++) {
            assertEq(nftInfos[i].tokenId, i + 3);
        }
    }

    /// @notice Test case for ownership transfer functionality
    function testOwnershipTransfer() public {
        // Owner mints a token
        vm.prank(owner);
        investmentNFT.mint(minter1, 100);

        // Owner transfers ownership
        vm.prank(owner);
        investmentNFT.transferOwnership(nonOwner);

        // Verify that the new owner can mint tokens
        vm.prank(nonOwner);
        investmentNFT.mint(minter2, 200);

        // Verify that the old owner cannot mint tokens
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, owner));
        investmentNFT.mint(minter1, 300);
    }

    /// @notice Test case for successfully retrieving the investment amount
    function testGetInvestmentAmount_success() public {
        // Owner mints a token
        vm.prank(owner);
        investmentNFT.mint(minter1, 200);

        // Verify the investment amount is retrieved correctly
        uint256 investmentAmount = investmentNFT.getInvestmentAmount(1);
        assertEq(investmentAmount, 200);
    }

    /// @notice Test case for successful NFT transfer
    function testTransferToken_success() public {
        // Owner mints a token
        vm.prank(owner);
        investmentNFT.mint(minter1, 100);

        // minter1 transfers the token to minter2
        vm.prank(minter1);
        investmentNFT.safeTransferFrom(minter1, minter2, 1);

        // Verify that the ownership is updated
        assertEq(investmentNFT.ownerOf(1), minter2);
    }

    /// @notice Test case where unauthorized user attempts token transfer and fails
    function testTransferToken_fail_unauthorized() public {
        // Owner mints a token
        vm.prank(owner);
        investmentNFT.mint(minter1, 100);

        // Non-owner attempts to transfer the token and fails
        uint256 tokenId = 1;
        vm.prank(nonOwner);
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InsufficientApproval.selector, nonOwner, tokenId));
        investmentNFT.safeTransferFrom(minter1, nonOwner, tokenId);
    }

    /// @notice Test case for successful approval and transfer of a token
    function testApproveAndTransfer() public {
        // Owner mints a token
        vm.prank(owner);
        investmentNFT.mint(minter1, 100);

        // minter1 approves nonOwner to transfer the token
        vm.prank(minter1);
        investmentNFT.approve(nonOwner, 1);

        // nonOwner transfers the token to minter2
        vm.prank(nonOwner);
        investmentNFT.safeTransferFrom(minter1, minter2, 1);

        // Verify that the ownership is updated
        assertEq(investmentNFT.ownerOf(1), minter2);
    }

    // Fuzz test zone

    /// @notice Fuzz test for minting with various investment amounts
    function testFuzz_Mint(uint256 investmentAmount) public {
        vm.assume(investmentAmount > 0 && investmentAmount < type(uint256).max);

        vm.expectEmit(true, true, true, true);
        emit IInvestmentNFT.NFTMinted(1, 99, minter1, investmentAmount);

        vm.prank(owner);
        uint256 tokenId = investmentNFT.mint(minter1, investmentAmount);

        assertEq(investmentNFT.ownerOf(tokenId), minter1);
        uint256 retrievedAmount = investmentNFT.getInvestmentAmount(tokenId);
        assertEq(retrievedAmount, investmentAmount);
    }

    /// @notice Fuzz test for burning tokens with various token IDs
    function testFuzz_Burn(uint256 tokenId) public {
        vm.assume(tokenId > 0 && tokenId <= 1000); // Assuming a reasonable upper limit
        // Mint tokens up to tokenId
        vm.startPrank(owner);
        for (uint256 i = 1; i <= tokenId; i++) {
            investmentNFT.mint(minter1, 100);
        }
        vm.stopPrank();

        vm.expectEmit(true, true, true, true);
        emit IInvestmentNFT.NFTBurned(tokenId, 99, minter1, 100);

        // Owner burns the token
        vm.prank(owner);
        investmentNFT.burn(tokenId);

        // Verify that the token no longer exists
        vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721NonexistentToken.selector, tokenId));
        investmentNFT.ownerOf(tokenId);
    }

    /// @notice Fuzz test for transferring tokens with various addresses
    function testFuzz_Transfer(uint256 investmentAmount) public {
        vm.assume(investmentAmount > 0);

        // Owner mints a token to 'from' address
        vm.prank(owner);
        uint256 tokenId = investmentNFT.mint(minter1, investmentAmount);

        // 'From' address transfers the token to 'to' address
        vm.prank(minter1);
        investmentNFT.safeTransferFrom(minter1, minter2, tokenId);

        // Verify that the ownership is updated
        assertEq(investmentNFT.ownerOf(tokenId), minter2);
    }

    /// @notice Fuzz test for getInvestmentAmount with various token IDs
    function testFuzz_GetInvestmentAmount(uint256 tokenId, uint256 investmentAmount) public {
        vm.assume(tokenId <= 1000);
        vm.assume(tokenId > 0 && investmentAmount > 0);

        // Mint a token with the specified tokenId and investmentAmount
        vm.startPrank(owner);
        for (uint256 i = 1; i <= tokenId; i++) {
            investmentNFT.mint(minter1, investmentAmount);
        }
        vm.stopPrank();

        // Retrieve the investment amount
        uint256 retrievedAmount = investmentNFT.getInvestmentAmount(tokenId);
        assertEq(retrievedAmount, investmentAmount);
    }

    /// @notice Test case for successfully setting URI
    function testSetURI_success() public {
        string memory newURI = "https://new-example.com/metadata.json";

        vm.expectEmit(false, false, false, true);
        emit BaseTokenURIUpdated(newURI);

        vm.prank(admin1);
        investmentNFT.setURI(newURI);

        // Verify that the URI is updated by checking tokenURI
        vm.prank(owner);
        investmentNFT.mint(minter1, 100);

        // All NFTs return the same metadata URL
        string memory tokenURI = investmentNFT.tokenURI(1);
        assertEq(tokenURI, newURI);
    }

    /// @notice Test case where non-admin tries to set URI and fails
    function testSetURI_fail_nonAdmin() public {
        string memory newURI = "https://new-example.com/metadata/";

        vm.prank(nonOwner);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, nonOwner));
        investmentNFT.setURI(newURI);
    }

    /// @notice Test case for setting URI with empty string
    function testSetURI_emptyString() public {
        vm.prank(admin1);
        investmentNFT.setURI("");

        vm.prank(owner);
        investmentNFT.mint(minter1, 100);

        // All NFTs return the same metadata URL (empty string in this case)
        string memory tokenURI = investmentNFT.tokenURI(1);
        assertEq(tokenURI, "");
    }

    function testTokenURI_allTokensReturnSameURI() public {
        vm.prank(admin1);
        investmentNFT.setURI("https://example.com/metadata.json");

        vm.startPrank(owner);
        investmentNFT.mint(minter1, 100);
        investmentNFT.mint(minter1, 200);
        vm.stopPrank();

        assertEq(investmentNFT.tokenURI(1), "https://example.com/metadata.json");
        assertEq(investmentNFT.tokenURI(2), "https://example.com/metadata.json");
    }
}
