// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Storage} from "bundle/investment/storage/Storage.sol";
import {Schema} from "bundle/investment/storage/Schema.sol";
import {IInvestmentErrors} from "bundle/investment/interfaces/IInvestmentErrors.sol";
import {IInvestmentEvents} from "bundle/investment/interfaces/IInvestmentEvents.sol";
import {OnlyMintersBase} from "bundle/investment/functions/onlyMinters/OnlyMintersBase.sol";

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IInvestmentNFT} from "bundle/periphery/interfaces/IInvestmentNFT.sol";

/**
 * @title MintNFT
 * @notice Mints NFTs for investors after off-chain JPY settlement (minter-operated batch path).
 * @dev Inherits from OnlyMintersBase. Does not enforce `requiredTier` on-chain; eligibility is verified off-chain before mint.
 */
contract MintNFT is ReentrancyGuard, OnlyMintersBase {
    /**
     * @notice Mints NFTs for investors representing their investment in a product
     * @dev Can only be called by minters
     * @param productId The ID of the investment product
     * @param unitCount The number of units to purchase
     * @param investor The address of the investor receiving the NFT
     * @custom:throws IInvestmentErrors.ZeroAddress If investor address is zero address
     * @custom:throws IInvestmentErrors.ProductNotFound If the specified product ID does not exist
     * @custom:throws IInvestmentErrors.ZeroAmount If unit count is zero
     * @custom:throws IInvestmentErrors.MaturedProduct If the product has matured
     * @custom:throws IInvestmentErrors.OperationStartDatePassed If operation start date has passed
     * @custom:throws IInvestmentErrors.ExceedOfferingAmount If the investment would exceed the offering amount
     */
     
    function mintNFT(uint256 productId, uint256 unitCount, address investor) external nonReentrant onlyMinters {
        if (investor == address(0)) {
            revert IInvestmentErrors.ZeroAddress();
        }

        Schema.Product storage product = Storage.ProductsState().products[productId];//!

        if (product.productId == 0) {
            revert IInvestmentErrors.ProductNotFound();
        }
        if (unitCount == 0) {
            revert IInvestmentErrors.ZeroAmount();
        }
        if (product.isMaturity) {
            revert IInvestmentErrors.MaturedProduct();
        }
        // Check if operation start date is not passed
        if (block.timestamp >= product.operationStartDate) { // @audit why stop minting after operation start date?
            revert IInvestmentErrors.OperationStartDatePassed();
        }

        // Calculate investment amount
        uint256 investmentAmount = product.minInvestment * unitCount;//!

        if (product.raisedAmount + investmentAmount > product.offeringAmount) {//check offering cap
            revert IInvestmentErrors.ExceedOfferingAmount();
        }

        // Update product state
        product.raisedAmount += investmentAmount;

        // NFT mint
        IInvestmentNFT nft = IInvestmentNFT(product.nftContract);
        uint256 tokenId = nft.mint(investor, investmentAmount);

        // Emit event
        emit IInvestmentEvents.Invested(productId, investor, unitCount, investmentAmount, tokenId);
    }
}

// Testing
import {MCTest} from "@mc-devkit/Flattened.sol";
import {InvestmentNFT} from "bundle/periphery/InvestmentNFT.sol";
import {MockTierSBT} from "test/investment/mocks/MockTierSBT.sol";

/**
 * @title MintNFTTest
 * @notice Test contract for the MintNFT function contract
 */
contract MintNFTTest is MCTest {
    // Constants for test setup
    uint256 constant PRODUCT_ID = 1;
    uint256 constant OFFERING_AMOUNT = 1_000_000_000_000; // 1_000_000USD(1USD = 150JPY: 150_000_000JPY)
    uint256 constant MIN_INVESTMENT = 250_000_000; // 250USD(1USD = 150JPY: 37_500JPY)
    uint256 constant OFFERING_END_DATE = 1737763200; // 2025-01-25 00:00:00 UTC
    uint256 constant MATURITY_DATE = 1767225600; // 2026-01-01 00:00:00 UTC
    uint256 constant EXPECTED_YIELD = 500; // 5%
    uint256 constant OPERATION_STARTDATE = 1738368000; // 2025-02-01 00:00:00 UTC
    uint256 constant DISTRIBUTION_START_DATE = 1748736000; // 2025-06-01 00:00:00 UTC
    uint256 constant TOTAL_DISTRIBUTION_COUNT = 3;
    uint256 constant DISTRIBUTION_INTERVAL = 3; // 3 months

    // Test accounts
    address admin = address(0x1);
    address investor = address(0x2);
    address notAdmin = address(0x3);

    // Contract instances
    IInvestmentNFT nft;

    function setUp() public {
        // Setup NFT
        nft = new InvestmentNFT("NFT", "NFT", PRODUCT_ID, "", address(0));

        // Setup MintNFT contract
        _use(MintNFT.mintNFT.selector, address(new MintNFT()));

        // Register test product
        Schema.Product memory product = Schema.Product({
            productId: PRODUCT_ID,
            nftContract: address(nft),
            offeringAmount: OFFERING_AMOUNT,
            minInvestment: MIN_INVESTMENT,
            offeringEndDate: OFFERING_END_DATE,
            raisedAmount: 0,
            productPool: 0,
            maturityDate: MATURITY_DATE,
            expectedYield: EXPECTED_YIELD,
            operationStartDate: OPERATION_STARTDATE,
            distributionStartDate: DISTRIBUTION_START_DATE,
            totalDistributionCount: TOTAL_DISTRIBUTION_COUNT,
            distributionInterval: DISTRIBUTION_INTERVAL,
            distributedCount: 0,
            distributedYieldPerCount: 0,
            distributedTokenId: 0,
            totalReturnedAmount: 0,
            maturedTokenId: 0,
            requiredTier: 0,
            isMaturity: false,
            isInsufficientBalance: false,
            isMonthEnd: false
        });

        // Setup storage
        Storage.ProductsState().products[PRODUCT_ID] = product;
        Storage.ProductsState().productIdKeys.push(PRODUCT_ID);
        Storage.WhiteListsState().admins.push(admin);
        Storage.MintersState().minters.push(admin);

        for (uint8 t = 0; t <= 4; ++t) {
            address[] storage sbts = Storage.TierRegistryState().allowedByTierAddress[t];
            uint256 sbtsLen = sbts.length;
            for (uint256 i = 0; i < sbtsLen;) {
                delete Storage.TierRegistryState().allowedByTierId[t][sbts[i]];
                unchecked {
                    ++i;
                }
            }
            delete Storage.TierRegistryState().allowedByTierAddress[t];
        }
    }

    function test_mintNFT_success() public {
        uint256 unitCount = 1;
        uint256 investAmount = MIN_INVESTMENT * unitCount;
        uint256 tokenId = 1;

        vm.startPrank(admin);

        vm.expectEmit(true, true, false, true);
        emit IInvestmentEvents.Invested(PRODUCT_ID, investor, unitCount, investAmount, tokenId);

        MintNFT(target).mintNFT(PRODUCT_ID, unitCount, investor);

        Schema.Product memory product = Storage.ProductsState().products[PRODUCT_ID];
        assertEq(product.raisedAmount, investAmount);
        assertEq(nft.balanceOf(investor), 1);
        assertEq(nft.ownerOf(tokenId), investor);

        vm.stopPrank();
    }

    function testFuzz_mintNFT_success(uint256 unitCount) public {
        vm.assume(unitCount > 0);
        vm.assume(unitCount <= OFFERING_AMOUNT / MIN_INVESTMENT);

        uint256 investAmount = MIN_INVESTMENT * unitCount;
        uint256 tokenId = 1;

        vm.startPrank(admin);

        vm.expectEmit(true, true, false, true);
        emit IInvestmentEvents.Invested(PRODUCT_ID, investor, unitCount, investAmount, tokenId);

        MintNFT(target).mintNFT(PRODUCT_ID, unitCount, investor);

        Schema.Product memory product = Storage.ProductsState().products[PRODUCT_ID];
        assertEq(product.raisedAmount, investAmount);
        assertEq(nft.balanceOf(investor), 1);
        assertEq(nft.ownerOf(tokenId), investor);

        vm.stopPrank();
    }

    function test_mintNFT_revert_whenNotMinter() public {
        uint256 unitCount = 1;

        vm.startPrank(notAdmin);

        vm.expectRevert(IInvestmentErrors.NotMinter.selector);
        MintNFT(target).mintNFT(PRODUCT_ID, unitCount, investor);

        Schema.Product memory product = Storage.ProductsState().products[PRODUCT_ID];
        assertEq(product.raisedAmount, 0);
        assertEq(nft.balanceOf(investor), 0);

        vm.stopPrank();
    }

    function test_mintNFT_revert_whenZeroAddress() public {
        uint256 unitCount = 1;

        vm.startPrank(admin);

        vm.expectRevert(IInvestmentErrors.ZeroAddress.selector);
        MintNFT(target).mintNFT(PRODUCT_ID, unitCount, address(0));

        Schema.Product memory product = Storage.ProductsState().products[PRODUCT_ID];
        assertEq(product.raisedAmount, 0);
        assertEq(nft.balanceOf(investor), 0);

        vm.stopPrank();
    }

    function test_mintNFT_revert_whenProductNotFound() public {
        uint256 invalidProductId = 99;
        uint256 unitCount = 1;

        vm.startPrank(admin);

        vm.expectRevert(IInvestmentErrors.ProductNotFound.selector);
        MintNFT(target).mintNFT(invalidProductId, unitCount, investor);

        Schema.Product memory product = Storage.ProductsState().products[PRODUCT_ID];
        assertEq(product.raisedAmount, 0);
        assertEq(nft.balanceOf(investor), 0);

        vm.stopPrank();
    }

    function test_mintNFT_revert_whenZeroAmount() public {
        uint256 unitCount = 0;

        vm.startPrank(admin);

        vm.expectRevert(IInvestmentErrors.ZeroAmount.selector);
        MintNFT(target).mintNFT(PRODUCT_ID, unitCount, investor);

        Schema.Product memory product = Storage.ProductsState().products[PRODUCT_ID];
        assertEq(product.raisedAmount, 0);
        assertEq(nft.balanceOf(investor), 0);

        vm.stopPrank();
    }

    function test_mintNFT_revert_whenMaturedProduct() public {
        Storage.ProductsState().products[PRODUCT_ID].isMaturity = true;
        uint256 unitCount = 1;

        vm.startPrank(admin);

        vm.expectRevert(IInvestmentErrors.MaturedProduct.selector);
        MintNFT(target).mintNFT(PRODUCT_ID, unitCount, investor);

        Schema.Product memory product = Storage.ProductsState().products[PRODUCT_ID];
        assertEq(product.raisedAmount, 0);
        assertEq(nft.balanceOf(investor), 0);

        vm.stopPrank();
    }

    function test_mintNFT_revert_OperationStartDatePassed() public {
        vm.warp(OPERATION_STARTDATE);

        uint256 unitCount = 1;

        vm.startPrank(admin);

        vm.expectRevert(IInvestmentErrors.OperationStartDatePassed.selector);
        MintNFT(target).mintNFT(PRODUCT_ID, unitCount, investor);

        Schema.Product memory product = Storage.ProductsState().products[PRODUCT_ID];
        assertEq(product.raisedAmount, 0);
        assertEq(nft.balanceOf(investor), 0);

        vm.stopPrank();
    }

    function test_mintNFT_success_whenRequiredTier_withoutSbtBalance() public {
        MockTierSBT sbt = new MockTierSBT("Tier", "T");
        Storage.TierRegistryState().allowedByTierAddress[1].push(address(sbt));
        Storage.ProductsState().products[PRODUCT_ID].requiredTier = 1;

        uint256 unitCount = 1;
        uint256 investAmount = MIN_INVESTMENT * unitCount;
        uint256 tokenId = 1;

        vm.startPrank(admin);
        vm.expectEmit(true, true, false, true);
        emit IInvestmentEvents.Invested(PRODUCT_ID, investor, unitCount, investAmount, tokenId);
        MintNFT(target).mintNFT(PRODUCT_ID, unitCount, investor);
        vm.stopPrank();

        assertEq(Storage.ProductsState().products[PRODUCT_ID].raisedAmount, investAmount);
        assertEq(nft.balanceOf(investor), 1);
        assertEq(sbt.balanceOf(investor), 0);
    }

    function test_mintNFT_revert_whenExceedOfferingAmount() public {
        // Case 1: Single mint overflow
        {
            uint256 unitCount = (OFFERING_AMOUNT / MIN_INVESTMENT) + 1;

            vm.startPrank(admin);

            vm.expectRevert(IInvestmentErrors.ExceedOfferingAmount.selector);
            MintNFT(target).mintNFT(PRODUCT_ID, unitCount, investor);

            Schema.Product memory product = Storage.ProductsState().products[PRODUCT_ID];
            assertEq(product.raisedAmount, 0);
            assertEq(nft.balanceOf(investor), 0);

            vm.stopPrank();
        }

        // Case 2: Cumulative mint overflow with existing balance
        {
            uint256 raiseAmount = OFFERING_AMOUNT - (MIN_INVESTMENT / 2);
            uint256 unitCount = 1;

            Storage.ProductsState().products[PRODUCT_ID].raisedAmount = raiseAmount;

            vm.startPrank(admin);

            vm.expectRevert(IInvestmentErrors.ExceedOfferingAmount.selector);
            MintNFT(target).mintNFT(PRODUCT_ID, unitCount, investor);

            Schema.Product memory product = Storage.ProductsState().products[PRODUCT_ID];
            assertEq(product.raisedAmount, raiseAmount);
            assertEq(nft.balanceOf(investor), 0);

            vm.stopPrank();
        }
    }

    receive() external payable {}
}
