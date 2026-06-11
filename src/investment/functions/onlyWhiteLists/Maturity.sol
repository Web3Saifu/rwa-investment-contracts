// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Storage} from "bundle/investment/storage/Storage.sol";
import {Schema} from "bundle/investment/storage/Schema.sol";
import {IInvestmentErrors} from "bundle/investment/interfaces/IInvestmentErrors.sol";
import {IInvestmentEvents} from "bundle/investment/interfaces/IInvestmentEvents.sol";
import {OnlyWhiteListsBase} from "bundle/investment/functions/onlyWhiteLists/OnlyWhiteListsBase.sol";
import {UsdtTransferLib} from "bundle/investment/utils/UsdtTransferLib.sol";

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IInvestmentNFT} from "bundle/periphery/interfaces/IInvestmentNFT.sol";

/**
 * @title Maturity
 * @notice Contract for managing the maturity process of investment products
 * @dev Inherits from OnlyWhiteListsBase to restrict access to admins only
 */
contract Maturity is ReentrancyGuard, OnlyWhiteListsBase {
    /**
     * @notice Execute the maturity process for an investment product
     * @dev Returns investment amounts to NFT holders and burns their NFTs when product reaches maturity
     * @param productId ID of the product to process maturity
     * @custom:throws ProductNotFound If the specified product does not exist
     * @custom:throws MaturedProduct If the product has already been matured
     * @custom:throws BeforeMaturityDate If executed before the maturity date
     * @custom:throws InsufficientFunds If the contract balance is insufficient
     */
    function maturity(uint256 productId) external nonReentrant onlyWhiteLists {
        Schema.Product storage product = Storage.ProductsState().products[productId];
        IERC20 usdt = IERC20(Storage.ConfigState().USDT_ADDRESS);
        IInvestmentNFT nft = IInvestmentNFT(product.nftContract);

        if (product.productId == 0) {
            revert IInvestmentErrors.ProductNotFound();
        }
        if (product.isMaturity) {
            revert IInvestmentErrors.MaturedProduct();
        }
        // Check to prevent maturity execution before maturity date
        if (product.maturityDate > block.timestamp) {
            revert IInvestmentErrors.BeforeMaturityDate();
        }
        // Check to prevent maturity execution before distribution is completed
        if (product.totalDistributionCount > product.distributedCount) {
            revert IInvestmentErrors.BeforeDistributionCompleted();
        }

        if (product.raisedAmount == 0) {
            product.isMaturity = true;
            if (product.isInsufficientBalance) {
                product.isInsufficientBalance = false;
            }
            _removeFromActiveProducts(productId);
            emit IInvestmentEvents.ProductMatured(productId, 0, 0, 0);
            return;
        }

        // Check product pool balance
        if (product.raisedAmount - product.totalReturnedAmount > product.productPool) {
            product.isInsufficientBalance = true;
            emit IInvestmentEvents.InsufficientProductPoolForMaturity(productId);
            return;
        }
        // Check contract balance
        if (product.raisedAmount - product.totalReturnedAmount > usdt.balanceOf(address(this))) {
            revert IInvestmentErrors.InsufficientFunds();
        }

        uint256 startTokenId = product.maturedTokenId + 1;
        IInvestmentNFT.NFTInfo[] memory nftInfos = nft.getNFTInfos(startTokenId);
        uint256 lastTokenId = nft.tokenIdCounter();
        uint256 _returnedAmount = 0;
        Schema.$EscrowState storage escrow = Storage.EscrowState();

        // Redeem to each NFT holder
        for (uint256 i = 0; i < nftInfos.length; i++) {
            uint256 investmentAmount = nftInfos[i].investmentAmount;
            uint256 tokenId = nftInfos[i].tokenId;
            address owner = nftInfos[i].owner;

            uint256 totalUnclaimedYield = 0;
            for (uint256 j = 1; j <= product.distributedCount; j++) {
                totalUnclaimedYield += escrow.unclaimedYield[productId][tokenId][j];
            }

            uint256 totalAmount = investmentAmount + totalUnclaimedYield;

            if (UsdtTransferLib.tryTransfer(usdt, owner, totalAmount)) {
                for (uint256 j = 1; j <= product.distributedCount; j++) {
                    uint256 yieldAmount = escrow.unclaimedYield[productId][tokenId][j];
                    if (yieldAmount > 0) {
                        escrow.unclaimedYield[productId][tokenId][j] = 0;
                        emit IInvestmentEvents.YieldReceived(productId, tokenId, owner, yieldAmount);
                        emit IInvestmentEvents.YieldClaimed(productId, tokenId, owner, yieldAmount, j);
                    }
                }
                nft.burn(tokenId);
                _returnedAmount += investmentAmount;
                emit IInvestmentEvents.InvestmentReturned(productId, tokenId, owner, investmentAmount);
            } else {
                if (escrow.unclaimedPrincipal[productId][tokenId] != 0) {
                    revert IInvestmentErrors.EscrowAlreadySet();
                }
                escrow.unclaimedPrincipal[productId][tokenId] = investmentAmount;
                _returnedAmount += investmentAmount;
                emit IInvestmentEvents.PrincipalTransferFailed(productId, tokenId, owner, investmentAmount);
            }

            // Processing when the last NFT is reached
            if (nftInfos[i].tokenId == lastTokenId) {
                product.isMaturity = true;
                product.maturedTokenId = nftInfos[i].tokenId;
                _removeFromActiveProducts(productId);
                emit IInvestmentEvents.ProductMatured(productId, startTokenId, lastTokenId, _returnedAmount);

                // In the case of the last batch processing
            } else if (i == nftInfos.length - 1) {
                product.maturedTokenId = nftInfos[i].tokenId;
                emit IInvestmentEvents.ProductMatured(productId, startTokenId, nftInfos[i].tokenId, _returnedAmount);
            }
        }

        product.totalReturnedAmount += _returnedAmount;
        product.productPool -= _returnedAmount;
        if (product.isInsufficientBalance) {
            product.isInsufficientBalance = false;
        }
    }

    function _removeFromActiveProducts(uint256 productId) internal {
        Schema.$ProductsState storage s = Storage.ProductsState();
        uint256 oneIndexed = s.activeIndex[productId];
        if (oneIndexed == 0) return;

        uint256 idx = oneIndexed - 1;
        uint256 lastIdx = s.activeProductIdKeys.length - 1;

        if (idx != lastIdx) {
            uint256 lastId = s.activeProductIdKeys[lastIdx];
            s.activeProductIdKeys[idx] = lastId;
            s.activeIndex[lastId] = oneIndexed;
        }

        s.activeProductIdKeys.pop();
        delete s.activeIndex[productId];
    }
}

// Testing
import {MCTest} from "@mc-devkit/Flattened.sol";
import {MockInvestmentERC20} from "test/investment/mocks/MockInvestmentERC20.sol";
import {InvestmentNFT} from "bundle/periphery/InvestmentNFT.sol";

/**
 * @title MaturityTest
 * @notice Test contract for the Maturity function contract
 */
contract MaturityTest is MCTest {
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
    address notAdmin = address(0x2);
    address investor1 = address(0x3);
    address investor2 = address(0x4);
    address investor3 = address(0x5);

    // Contract instances
    MockInvestmentERC20 usdt;
    IInvestmentNFT nft;

    function setUp() public {
        // Setup mock USDT
        usdt = new MockInvestmentERC20();

        // Setup NFT
        nft = new InvestmentNFT("NFT", "NFT", PRODUCT_ID, "", address(0));

        // Setup Maturity contract
        _use(Maturity.maturity.selector, address(new Maturity()));

        // Setup admin

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
            distributedCount: 3,
            distributedYieldPerCount: 0,
            distributedTokenId: 0,
            totalReturnedAmount: 0,
            maturedTokenId: 0,
            requiredTier: 0,
            isMaturity: false,
            isInsufficientBalance: true,
            isMonthEnd: false
        });

        // Setup storage
        Storage.ProductsState().products[PRODUCT_ID] = product;
        Storage.ProductsState().productIdKeys.push(PRODUCT_ID);
        Storage.ProductsState().activeProductIdKeys.push(PRODUCT_ID);
        Storage.ProductsState().activeIndex[PRODUCT_ID] = 1;
        Storage.WhiteListsState().admins.push(admin);
        Storage.ConfigState().USDT_ADDRESS = address(usdt);
    }

    function test_maturity_success() public {
        uint256 startTokenId = 1;
        uint256 endTokenId = 2;
        uint256 investment1 = OFFERING_AMOUNT / 2;
        uint256 investment2 = OFFERING_AMOUNT / 2;

        // Setup product
        Schema.Product storage product = Storage.ProductsState().products[PRODUCT_ID];
        product.raisedAmount = investment1 + investment2;
        product.productPool = investment1 + investment2;

        nft.mint(investor1, investment1);
        nft.mint(investor2, investment2);

        usdt.mint(address(this), investment1 + investment2);

        vm.startPrank(admin);
        vm.warp(MATURITY_DATE);

        vm.expectEmit(true, true, true, true);
        emit IInvestmentEvents.InvestmentReturned(PRODUCT_ID, startTokenId, investor1, investment1);

        vm.expectEmit(true, true, true, true);
        emit IInvestmentEvents.InvestmentReturned(PRODUCT_ID, startTokenId + 1, investor2, investment2);

        vm.expectEmit(true, false, false, true);
        emit IInvestmentEvents.ProductMatured(PRODUCT_ID, startTokenId, endTokenId, investment1 + investment2);

        Maturity(target).maturity(PRODUCT_ID);

        assertTrue(product.isMaturity);
        assertEq(product.totalReturnedAmount, investment1 + investment2);
        assertEq(product.maturedTokenId, endTokenId);
        assertEq(usdt.balanceOf(investor1), investment1);
        assertEq(usdt.balanceOf(investor2), investment2);
        assertEq(usdt.balanceOf(address(this)), 0);
        assertEq(product.productPool, 0);
        assertEq(product.isInsufficientBalance, false);
        assertEq(Storage.ProductsState().activeProductIdKeys.length, 0, "active array should be empty after maturity");
        assertEq(Storage.ProductsState().activeIndex[PRODUCT_ID], 0, "activeIndex should be cleared after maturity");

        vm.stopPrank();
    }

    function test_maturity_success_investorsMoreThan51() public {
        uint256 startTokenId = 1;
        uint256 endTokenId = 100;
        uint256 investmentPerUser = OFFERING_AMOUNT / endTokenId;
        uint256 totalInvestment = investmentPerUser * endTokenId;
        uint256 totalInvestmentPerBatch = investmentPerUser * 50;

        // Setup product
        Schema.Product storage product = Storage.ProductsState().products[PRODUCT_ID];
        product.raisedAmount = totalInvestment;
        product.productPool = totalInvestment;

        // Mint NFTs for investors
        for (uint256 i = 0; i < endTokenId; i++) {
            nft.mint(address(uint160(uint160(investor1) + i)), investmentPerUser);
        }

        usdt.mint(address(this), totalInvestment);

        // Execute first batch
        vm.startPrank(admin);
        vm.warp(MATURITY_DATE);

        for (uint256 i = 0; i < 50; i++) {
            vm.expectEmit(true, true, true, true);
            emit IInvestmentEvents.InvestmentReturned(
                PRODUCT_ID, startTokenId + i, address(uint160(uint160(investor1) + i)), investmentPerUser
            );
        }

        vm.expectEmit(true, false, false, true);
        emit IInvestmentEvents.ProductMatured(PRODUCT_ID, startTokenId, 50, totalInvestmentPerBatch);

        Maturity(target).maturity(PRODUCT_ID);

        assertFalse(product.isMaturity, "mismatch maturity");
        assertEq(product.maturedTokenId, 50, "mismatch maturedTokenId 50");
        assertEq(
            Storage.ProductsState().activeProductIdKeys.length,
            1,
            "active array should still contain product after first batch"
        );
        assertEq(Storage.ProductsState().activeIndex[PRODUCT_ID], 1, "activeIndex should remain set after first batch");
        for (uint256 i = 0; i < 50; i++) {
            assertEq(
                usdt.balanceOf(address(uint160(uint160(investor1) + i))),
                investmentPerUser,
                "mismatch usdt balance investmentPerUser"
            );
        }
        assertEq(
            product.productPool, usdt.balanceOf(address(this)), "mismatch productPool usdt.balanceOf(address(this))"
        );
        assertEq(
            product.totalReturnedAmount, totalInvestmentPerBatch, "mismatch totalReturnedAmount totalInvestmentPerBatch"
        );

        // Execute second batch
        for (uint256 i = 50; i < endTokenId; i++) {
            vm.expectEmit(true, true, true, true);
            emit IInvestmentEvents.InvestmentReturned(
                PRODUCT_ID, startTokenId + i, address(uint160(uint160(investor1) + i)), investmentPerUser
            );
        }

        vm.expectEmit(true, false, false, true);
        emit IInvestmentEvents.ProductMatured(PRODUCT_ID, 51, endTokenId, totalInvestmentPerBatch);

        Maturity(target).maturity(PRODUCT_ID);

        assertTrue(product.isMaturity, "mismatch maturity");
        assertEq(product.maturedTokenId, endTokenId, "mismatch maturedTokenId endTokenId");
        for (uint256 i = 50; i < endTokenId; i++) {
            assertEq(
                usdt.balanceOf(address(uint160(uint160(investor1) + i))),
                investmentPerUser,
                "mismatch usdt balance investmentPerUser"
            );
        }
        assertEq(
            product.productPool, usdt.balanceOf(address(this)), "mismatch productPool usdt.balanceOf(address(this))"
        );
        assertEq(product.totalReturnedAmount, totalInvestment, "mismatch totalReturnedAmount totalInvestment");
        assertEq(product.isInsufficientBalance, false);
        assertEq(
            Storage.ProductsState().activeProductIdKeys.length, 0, "active array should be empty after final batch"
        );
        assertEq(Storage.ProductsState().activeIndex[PRODUCT_ID], 0, "activeIndex should be cleared after final batch");

        vm.stopPrank();
    }

    function testFuzz_maturity_success(uint256 investment1, uint256 investment2, uint256 maturityDate) public {
        investment1 = bound(investment1, MIN_INVESTMENT, OFFERING_AMOUNT);
        investment2 = bound(investment2, MIN_INVESTMENT, OFFERING_AMOUNT);
        vm.assume(investment1 + investment2 <= OFFERING_AMOUNT);
        maturityDate = bound(maturityDate, MATURITY_DATE, MATURITY_DATE + 1095 days);

        uint256 startTokenId = 1;
        uint256 endTokenId = 2;

        Schema.Product storage product = Storage.ProductsState().products[PRODUCT_ID];
        product.raisedAmount = investment1 + investment2;
        product.productPool = investment1 + investment2;
        product.maturityDate = maturityDate;

        nft.mint(investor1, investment1);
        nft.mint(investor2, investment2);

        usdt.mint(address(this), investment1 + investment2);

        vm.startPrank(admin);
        vm.warp(maturityDate);

        vm.expectEmit(true, true, true, true);
        emit IInvestmentEvents.InvestmentReturned(PRODUCT_ID, startTokenId, investor1, investment1);

        vm.expectEmit(true, true, true, true);
        emit IInvestmentEvents.InvestmentReturned(PRODUCT_ID, startTokenId + 1, investor2, investment2);

        vm.expectEmit(true, false, false, true);
        emit IInvestmentEvents.ProductMatured(PRODUCT_ID, startTokenId, endTokenId, investment1 + investment2);

        Maturity(target).maturity(PRODUCT_ID);

        assertTrue(product.isMaturity);
        assertEq(product.totalReturnedAmount, investment1 + investment2);
        assertEq(product.maturedTokenId, endTokenId);
        assertEq(usdt.balanceOf(investor1), investment1);
        assertEq(usdt.balanceOf(investor2), investment2);
        assertEq(usdt.balanceOf(address(this)), 0);
        assertEq(product.productPool, 0);
        assertEq(product.isInsufficientBalance, false);

        vm.stopPrank();
    }

    function test_maturity_revert_whenNotAdmin() public {
        vm.startPrank(notAdmin);

        vm.expectRevert(IInvestmentErrors.NotAdmin.selector);
        Maturity(target).maturity(PRODUCT_ID);

        vm.stopPrank();
    }

    function test_maturity_revert_whenProductNotFound() public {
        uint256 invalidProductId = 99;

        vm.startPrank(admin);

        vm.expectRevert(IInvestmentErrors.ProductNotFound.selector);
        Maturity(target).maturity(invalidProductId);

        vm.stopPrank();
    }

    function test_maturity_revert_whenBeforeMaturityDate() public {
        vm.startPrank(admin);
        vm.warp(MATURITY_DATE - 1);

        vm.expectRevert(IInvestmentErrors.BeforeMaturityDate.selector);
        Maturity(target).maturity(PRODUCT_ID);

        vm.stopPrank();
    }

    function test_maturity_revert_whenMaturedProduct() public {
        Storage.ProductsState().products[PRODUCT_ID].isMaturity = true;

        vm.startPrank(admin);
        vm.warp(MATURITY_DATE);

        vm.expectRevert(IInvestmentErrors.MaturedProduct.selector);
        Maturity(target).maturity(PRODUCT_ID);

        vm.stopPrank();
    }

    function test_maturity_revert_whenInsufficientProductPool() public {
        uint256 investment1 = MIN_INVESTMENT;

        Schema.Product storage product = Storage.ProductsState().products[PRODUCT_ID];
        product.raisedAmount = investment1;
        product.productPool = investment1 / 2;
        product.isInsufficientBalance = false;

        nft.mint(investor1, investment1);

        vm.startPrank(admin);
        vm.warp(MATURITY_DATE);

        vm.expectEmit(true, false, false, true);
        emit IInvestmentEvents.InsufficientProductPoolForMaturity(PRODUCT_ID);
        Maturity(target).maturity(PRODUCT_ID);
        assertTrue(product.isInsufficientBalance);

        vm.stopPrank();
    }

    function test_maturity_revert_whenInsufficientFunds() public {
        uint256 investment1 = MIN_INVESTMENT;

        Schema.Product storage product = Storage.ProductsState().products[PRODUCT_ID];
        product.raisedAmount = investment1;
        product.productPool = investment1;

        nft.mint(investor1, investment1);
        // Note: Not calling usdt.mint() intentionally

        vm.startPrank(admin);
        vm.warp(MATURITY_DATE);

        vm.expectRevert(IInvestmentErrors.InsufficientFunds.selector);
        Maturity(target).maturity(PRODUCT_ID);

        vm.stopPrank();
    }

    function test_maturity_escrowOnTransferRevert() public {
        uint256 investment1 = MIN_INVESTMENT;
        uint256 investment2 = MIN_INVESTMENT;

        Schema.Product storage product = Storage.ProductsState().products[PRODUCT_ID];
        product.raisedAmount = investment1 + investment2;
        product.productPool = investment1 + investment2;
        product.distributedCount = TOTAL_DISTRIBUTION_COUNT;

        nft.mint(investor1, investment1);
        nft.mint(investor2, investment2);
        usdt.mint(address(this), investment1 + investment2);
        usdt.setBlocked(investor2, true);

        vm.startPrank(admin);
        vm.warp(MATURITY_DATE);

        vm.expectEmit(true, true, true, true);
        emit IInvestmentEvents.InvestmentReturned(PRODUCT_ID, 1, investor1, investment1);

        vm.expectEmit(true, true, true, true);
        emit IInvestmentEvents.PrincipalTransferFailed(PRODUCT_ID, 2, investor2, investment2);

        Maturity(target).maturity(PRODUCT_ID);

        assertTrue(product.isMaturity);
        assertEq(Storage.EscrowState().unclaimedPrincipal[PRODUCT_ID][2], investment2);
        assertEq(nft.ownerOf(2), investor2);

        vm.stopPrank();
    }

    receive() external payable {}
}
