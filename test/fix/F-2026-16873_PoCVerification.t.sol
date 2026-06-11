// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {MCTest} from "@mc-devkit/Flattened.sol";
import {Storage} from "bundle/investment/storage/Storage.sol";
import {Schema} from "bundle/investment/storage/Schema.sol";
import {Getter} from "bundle/investment/functions/Getter.sol";
import {RegisterProduct} from "bundle/investment/functions/onlyWhiteLists/RegisterProduct.sol";
import {Maturity} from "bundle/investment/functions/onlyWhiteLists/Maturity.sol";
import {IInvestmentErrors} from "bundle/investment/interfaces/IInvestmentErrors.sol";
import {IInvestmentEvents} from "bundle/investment/interfaces/IInvestmentEvents.sol";
import {MockInvestmentERC20} from "test/investment/mocks/MockInvestmentERC20.sol";
import {InvestmentNFT} from "bundle/periphery/InvestmentNFT.sol";
import {IInvestmentNFT} from "bundle/periphery/interfaces/IInvestmentNFT.sol";

/**
 * @title F-2026-16873 PoC Verification
 * @notice Verifies that matured products are removed from activeProductIdKeys
 *         and that getActiveProducts() excludes them, preventing DoS on checkUpkeep.
 */
contract F2026_16873_PoCVerification is MCTest {
    uint256 constant PRODUCT_A = 1;
    uint256 constant PRODUCT_B = 2;
    uint256 constant PRODUCT_C = 3;
    uint256 constant OFFERING_AMOUNT = 1_000_000_000_000;
    uint256 constant MIN_INVESTMENT = 250_000_000;
    uint256 constant MATURITY_DATE = 1767225600; // 2026-01-01
    uint256 constant OFFERING_END_DATE = 1737763200; // 2025-01-25
    uint256 constant OPERATION_STARTDATE = 1738368000; // 2025-02-01
    uint256 constant DISTRIBUTION_START_DATE = 1748736000; // 2025-06-01

    address admin = address(0x1);
    address investor1 = address(0x3);

    MockInvestmentERC20 usdt;
    IInvestmentNFT nftA;
    IInvestmentNFT nftB;
    IInvestmentNFT nftC;

    function setUp() public {
        usdt = new MockInvestmentERC20();
        nftA = new InvestmentNFT("NFT-A", "NFTA", PRODUCT_A, "", address(0));
        nftB = new InvestmentNFT("NFT-B", "NFTB", PRODUCT_B, "", address(0));
        nftC = new InvestmentNFT("NFT-C", "NFTC", PRODUCT_C, "", address(0));

        Getter getter = new Getter();
        _use(Getter.getAllProducts.selector, address(getter));
        _use(Getter.getActiveProducts.selector, address(getter));
        _use(Maturity.maturity.selector, address(new Maturity()));

        Storage.WhiteListsState().admins.push(admin);
        Storage.ConfigState().USDT_ADDRESS = address(usdt);

        _registerProduct(PRODUCT_A, address(nftA));
        _registerProduct(PRODUCT_B, address(nftB));
        _registerProduct(PRODUCT_C, address(nftC));
    }

    function _registerProduct(uint256 productId, address nftContract) internal {
        Schema.Product memory product = Schema.Product({
            productId: productId,
            nftContract: nftContract,
            offeringAmount: OFFERING_AMOUNT,
            minInvestment: MIN_INVESTMENT,
            offeringEndDate: OFFERING_END_DATE,
            raisedAmount: 0,
            productPool: 0,
            maturityDate: MATURITY_DATE,
            expectedYield: 500,
            operationStartDate: OPERATION_STARTDATE,
            distributionStartDate: DISTRIBUTION_START_DATE,
            totalDistributionCount: 3,
            distributionInterval: 3,
            distributedCount: 3,
            distributedYieldPerCount: 0,
            distributedTokenId: 0,
            totalReturnedAmount: 0,
            maturedTokenId: 0,
            requiredTier: 0,
            isMaturity: false,
            isInsufficientBalance: false,
            isMonthEnd: false
        });

        Storage.ProductsState().products[productId] = product;
        Storage.ProductsState().productIdKeys.push(productId);
        Storage.ProductsState().activeProductIdKeys.push(productId);
        Storage.ProductsState().activeIndex[productId] = Storage.ProductsState().activeProductIdKeys.length;
    }

    /// @notice All three products start as active
    function test_initialState_allProductsActive() public view {
        Schema.Product[] memory all = Getter(target).getAllProducts();
        Schema.Product[] memory active = Getter(target).getActiveProducts();

        assertEq(all.length, 3, "should have 3 total products");
        assertEq(active.length, 3, "should have 3 active products");
    }

    /// @notice After maturing product B, activeProducts drops to 2
    function test_maturityRemovesFromActiveProducts() public {
        uint256 investment = OFFERING_AMOUNT / 2;

        Schema.Product storage prodB = Storage.ProductsState().products[PRODUCT_B];
        prodB.raisedAmount = investment;
        prodB.productPool = investment;

        nftB.mint(investor1, investment);
        usdt.mint(address(this), investment);

        vm.startPrank(admin);
        vm.warp(MATURITY_DATE);

        Maturity(target).maturity(PRODUCT_B);

        vm.stopPrank();

        Schema.Product[] memory active = Getter(target).getActiveProducts();
        assertEq(active.length, 2, "should have 2 active products after maturity");

        for (uint256 i = 0; i < active.length; i++) {
            assertTrue(active[i].productId != PRODUCT_B, "matured product should not be in active list");
        }

        assertEq(Storage.ProductsState().activeIndex[PRODUCT_B], 0, "activeIndex should be cleared");

        Schema.Product[] memory all = Getter(target).getAllProducts();
        assertEq(all.length, 3, "all products should still exist");
    }

    /// @notice Zero-investor maturity path should also prune activeProductIdKeys
    function test_maturityZeroInvestor_removesFromActiveProducts() public {
        vm.startPrank(admin);
        vm.warp(MATURITY_DATE);

        Maturity(target).maturity(PRODUCT_A);

        vm.stopPrank();

        Schema.Product[] memory active = Getter(target).getActiveProducts();
        assertEq(active.length, 2, "should have 2 active products after zero-investor maturity");

        for (uint256 i = 0; i < active.length; i++) {
            assertTrue(active[i].productId != PRODUCT_A, "matured product should not be in active list");
        }

        assertEq(Storage.ProductsState().activeIndex[PRODUCT_A], 0, "activeIndex should be cleared");
    }

    /// @notice After maturing all products, activeProducts should be empty
    function test_allProductsMatured_activeListEmpty() public {
        _setupAndMature(PRODUCT_A, nftA);
        _setupAndMature(PRODUCT_B, nftB);
        _setupAndMature(PRODUCT_C, nftC);

        Schema.Product[] memory active = Getter(target).getActiveProducts();
        assertEq(active.length, 0, "active list should be empty after all matured");

        Schema.Product[] memory all = Getter(target).getAllProducts();
        assertEq(all.length, 3, "all products should still exist");
    }

    /// @notice Swap-and-pop preserves correct indices for remaining products
    function test_swapAndPop_indicesCorrect() public {
        _setupAndMature(PRODUCT_A, nftA);

        uint256[] memory activeKeys = Storage.ProductsState().activeProductIdKeys;
        assertEq(activeKeys.length, 2, "2 products remain");

        for (uint256 i = 0; i < activeKeys.length; i++) {
            uint256 pid = activeKeys[i];
            assertEq(Storage.ProductsState().activeIndex[pid], i + 1, "1-indexed position mismatch");
        }
    }

    function _setupAndMature(uint256 productId, IInvestmentNFT nft) internal {
        uint256 investment = OFFERING_AMOUNT / 2;

        Schema.Product storage prod = Storage.ProductsState().products[productId];
        prod.raisedAmount = investment;
        prod.productPool = investment;

        nft.mint(investor1, investment);
        usdt.mint(address(this), investment);

        vm.startPrank(admin);
        vm.warp(MATURITY_DATE);
        Maturity(target).maturity(productId);
        vm.stopPrank();
    }

    receive() external payable {}
}
