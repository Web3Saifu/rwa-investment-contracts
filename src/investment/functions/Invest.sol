// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Storage} from "bundle/investment/storage/Storage.sol";
import {Schema} from "bundle/investment/storage/Schema.sol";
import {IInvestmentErrors} from "bundle/investment/interfaces/IInvestmentErrors.sol";
import {IInvestmentEvents} from "bundle/investment/interfaces/IInvestmentEvents.sol";

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IInvestmentNFT} from "bundle/periphery/interfaces/IInvestmentNFT.sol";
import {PurchasePermissionLib} from "bundle/investment/utils/PurchasePermissionLib.sol";

/**
 * @title Invest
 * @notice Contract for managing investments in investment products
 */
contract Invest is ReentrancyGuard {
    using SafeERC20 for IERC20;

    /**
     * @notice Invest in a specified product
     * @param productId ID of the product to invest in
     * @param unitCount Number of units to invest
     * @dev
     * - Investment amount is calculated as minInvestment * unitCount
     * - Requires prior USDT approval for the investment amount
     * - Transfers USDT to the contract upon investment
     * - Mints NFT based on investment amount
     * - Investment only possible during product's offering period
     * @custom:throws ProductNotFound when product does not exist
     * @custom:throws ZeroAmount when unit count is 0
     * @custom:throws MaturedProduct when product has matured
     * @custom:throws OfferingPeriodEnded when offering period has ended
     * @custom:throws ExceedOfferingAmount when exceeding offering amount
     * @custom:throws InsufficientFunds when USDT balance is insufficient
     * @custom:throws InsufficientAllowance when USDT allowance is insufficient
     * @custom:throws IInvestmentErrors.NotEligible when the caller does not satisfy the product required tier
     */
    function invest(uint256 productId, uint256 unitCount) external nonReentrant {
        Schema.Product storage product = Storage.ProductsState().products[productId];

        if (product.productId == 0) {
            revert IInvestmentErrors.ProductNotFound();
        }
        if (unitCount == 0) {
            revert IInvestmentErrors.ZeroAmount();
        }
        if (product.isMaturity) {
            revert IInvestmentErrors.MaturedProduct();
        }
        // Check if within offering period(JST)
        if (block.timestamp >= product.offeringEndDate) {
            revert IInvestmentErrors.OfferingPeriodEnded();
        }

        if (!PurchasePermissionLib.hasPurchasePermission(msg.sender, product.requiredTier)) {
            revert IInvestmentErrors.NotEligible(product.requiredTier);
        }

        // Calculate investment amount
        uint256 investmentAmount = product.minInvestment * unitCount;
        if (product.raisedAmount + investmentAmount > product.offeringAmount) {
            revert IInvestmentErrors.ExceedOfferingAmount();
        }

        // USDT token
        IERC20 usdt = IERC20(Storage.ConfigState().USDT_ADDRESS);
        if (usdt.balanceOf(msg.sender) < investmentAmount) {
            revert IInvestmentErrors.InsufficientFunds();
        }
        uint256 allowance = usdt.allowance(msg.sender, address(this));
        if (allowance < investmentAmount) {
            revert IInvestmentErrors.InsufficientAllowance();
        }

        // Update product state
        product.raisedAmount += investmentAmount;
        product.productPool += investmentAmount;

        usdt.safeTransferFrom(msg.sender, address(this), investmentAmount);

        // NFT mint
        IInvestmentNFT nft = IInvestmentNFT(product.nftContract);
        uint256 tokenId = nft.mint(msg.sender, investmentAmount);

        emit IInvestmentEvents.Invested(productId, msg.sender, unitCount, investmentAmount, tokenId);
    }
}

// Testing
import {MCTest} from "@mc-devkit/Flattened.sol";
import {MockInvestmentERC20} from "test/investment/mocks/MockInvestmentERC20.sol";
import {InvestmentNFT} from "bundle/periphery/InvestmentNFT.sol";
import {MockTierSBT} from "test/investment/mocks/MockTierSBT.sol";

/**
 * @title InvestTest
 * @notice Test contract for the Invest function contract
 */
contract InvestTest is MCTest {
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
    address investor = address(0x1);
    address admin = address(0x2);

    // Contract instances
    MockInvestmentERC20 usdt;
    IInvestmentNFT nft;

    function setUp() public {
        // Setup mock USDT
        usdt = new MockInvestmentERC20();

        // Setup NFT
        nft = new InvestmentNFT("NFT", "NFT", PRODUCT_ID, "", address(0));

        // Setup Invest contract
        _use(Invest.invest.selector, address(new Invest()));

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
        Storage.ConfigState().USDT_ADDRESS = address(usdt);

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

    function test_invest_success() public {
        uint256 unitCount = 1;
        uint256 investAmount = MIN_INVESTMENT * unitCount;
        uint256 tokenId = 1;

        vm.startPrank(investor);

        usdt.mint(investor, investAmount);
        usdt.approve(address(this), investAmount);

        vm.expectEmit(true, true, false, true);
        emit IInvestmentEvents.Invested(PRODUCT_ID, investor, unitCount, investAmount, tokenId);

        Invest(target).invest(PRODUCT_ID, unitCount);

        Schema.Product memory product = Storage.ProductsState().products[PRODUCT_ID];
        assertEq(product.raisedAmount, investAmount);
        assertEq(product.productPool, investAmount);
        assertEq(usdt.balanceOf(address(this)), investAmount);
        assertEq(nft.balanceOf(investor), 1);
        assertEq(nft.ownerOf(tokenId), investor);

        vm.stopPrank();
    }

    function testFuzz_invest_success(uint256 unitCount) public {
        vm.assume(unitCount > 0);
        vm.assume(unitCount <= OFFERING_AMOUNT / MIN_INVESTMENT);

        uint256 investAmount = MIN_INVESTMENT * unitCount;
        uint256 tokenId = 1;

        vm.startPrank(investor);

        usdt.mint(investor, investAmount);
        usdt.approve(address(this), investAmount);

        vm.expectEmit(true, true, false, true);
        emit IInvestmentEvents.Invested(PRODUCT_ID, investor, unitCount, investAmount, tokenId);

        Invest(target).invest(PRODUCT_ID, unitCount);

        Schema.Product memory product = Storage.ProductsState().products[PRODUCT_ID];
        assertEq(product.raisedAmount, investAmount);
        assertEq(product.productPool, investAmount);
        assertEq(usdt.balanceOf(address(this)), investAmount);
        assertEq(nft.balanceOf(investor), 1);
        assertEq(nft.ownerOf(tokenId), investor);

        vm.stopPrank();
    }

    function test_invest_success_whenRequiredTier_andCallerHoldsSbt() public {
        MockTierSBT sbt = new MockTierSBT("Tier", "T");
        Storage.TierRegistryState().allowedByTierAddress[1].push(address(sbt));
        Storage.ProductsState().products[PRODUCT_ID].requiredTier = 1;
        sbt.mint(investor);

        uint256 unitCount = 1;
        uint256 investAmount = MIN_INVESTMENT * unitCount;
        uint256 tokenId = 1;

        vm.startPrank(investor);
        usdt.mint(investor, investAmount);
        usdt.approve(address(this), investAmount);
        vm.expectEmit(true, true, false, true);
        emit IInvestmentEvents.Invested(PRODUCT_ID, investor, unitCount, investAmount, tokenId);
        Invest(target).invest(PRODUCT_ID, unitCount);
        vm.stopPrank();

        Schema.Product memory product = Storage.ProductsState().products[PRODUCT_ID];
        assertEq(product.raisedAmount, investAmount);
        assertEq(nft.balanceOf(investor), 1);
    }

    function test_invest_revert_NotEligible_whenRequiredTier_emptyRegistry() public {
        Storage.ProductsState().products[PRODUCT_ID].requiredTier = 1;
        uint256 unitCount = 1;
        uint256 investAmount = MIN_INVESTMENT * unitCount;

        vm.startPrank(investor);
        usdt.mint(investor, investAmount);
        usdt.approve(address(this), investAmount);
        vm.expectRevert(abi.encodeWithSelector(IInvestmentErrors.NotEligible.selector, uint8(1)));
        Invest(target).invest(PRODUCT_ID, unitCount);
        vm.stopPrank();

        assertEq(Storage.ProductsState().products[PRODUCT_ID].raisedAmount, 0);
        assertEq(nft.balanceOf(investor), 0);
    }

    function test_invest_revert_NotEligible_whenRequiredTier_noSbtBalance() public {
        MockTierSBT sbt = new MockTierSBT("Tier", "T");
        Storage.TierRegistryState().allowedByTierAddress[1].push(address(sbt));
        Storage.ProductsState().products[PRODUCT_ID].requiredTier = 1;

        uint256 unitCount = 1;
        uint256 investAmount = MIN_INVESTMENT * unitCount;

        vm.startPrank(investor);
        usdt.mint(investor, investAmount);
        usdt.approve(address(this), investAmount);
        vm.expectRevert(abi.encodeWithSelector(IInvestmentErrors.NotEligible.selector, uint8(1)));
        Invest(target).invest(PRODUCT_ID, unitCount);
        vm.stopPrank();

        assertEq(Storage.ProductsState().products[PRODUCT_ID].raisedAmount, 0);
        assertEq(nft.balanceOf(investor), 0);
    }

    function test_invest_revert_whenProductNotFound() public {
        uint256 invalidProductId = 99;
        uint256 unitCount = 1;
        uint256 investAmount = MIN_INVESTMENT * unitCount;

        vm.startPrank(investor);

        usdt.mint(investor, investAmount);
        usdt.approve(address(this), investAmount);

        vm.expectRevert(IInvestmentErrors.ProductNotFound.selector);
        Invest(target).invest(invalidProductId, unitCount);

        Schema.Product memory product = Storage.ProductsState().products[PRODUCT_ID];
        assertEq(product.raisedAmount, 0);
        assertEq(product.productPool, 0);
        assertEq(usdt.balanceOf(investor), investAmount);
        assertEq(nft.balanceOf(investor), 0);

        vm.stopPrank();
    }

    function test_invest_revert_whenZeroAmount() public {
        uint256 amount = 100_000_000;

        vm.startPrank(investor);

        usdt.mint(investor, amount);
        usdt.approve(address(this), amount);

        vm.expectRevert(IInvestmentErrors.ZeroAmount.selector);
        Invest(target).invest(PRODUCT_ID, 0);

        Schema.Product memory product = Storage.ProductsState().products[PRODUCT_ID];
        assertEq(product.raisedAmount, 0);
        assertEq(product.productPool, 0);
        assertEq(usdt.balanceOf(investor), amount);
        assertEq(nft.balanceOf(investor), 0);

        vm.stopPrank();
    }

    function test_invest_revert_whenMaturedProduct() public {
        Storage.ProductsState().products[PRODUCT_ID].isMaturity = true;
        uint256 unitCount = 1;
        uint256 investAmount = MIN_INVESTMENT * unitCount;

        vm.startPrank(investor);

        usdt.mint(investor, investAmount);
        usdt.approve(address(this), investAmount);

        vm.expectRevert(IInvestmentErrors.MaturedProduct.selector);
        Invest(target).invest(PRODUCT_ID, unitCount);

        Schema.Product memory product = Storage.ProductsState().products[PRODUCT_ID];
        assertEq(product.raisedAmount, 0);
        assertEq(product.productPool, 0);
        assertEq(usdt.balanceOf(investor), investAmount);
        assertEq(nft.balanceOf(investor), 0);

        vm.stopPrank();
    }

    function test_invest_revert_whenOfferingPeriodEnded() public {
        vm.warp(OFFERING_END_DATE + 1);

        uint256 unitCount = 1;
        uint256 investAmount = MIN_INVESTMENT * unitCount;

        vm.startPrank(investor);

        usdt.mint(investor, investAmount);
        usdt.approve(address(this), investAmount);

        vm.expectRevert(IInvestmentErrors.OfferingPeriodEnded.selector);
        Invest(target).invest(PRODUCT_ID, unitCount);

        Schema.Product memory product = Storage.ProductsState().products[PRODUCT_ID];
        assertEq(product.raisedAmount, 0);
        assertEq(product.productPool, 0);
        assertEq(usdt.balanceOf(investor), investAmount);
        assertEq(nft.balanceOf(investor), 0);

        vm.stopPrank();
    }

    function test_invest_revert_whenExceedOfferingAmount() public {
        // Case 1: Single investment overflow
        {
            uint256 unitCount = (OFFERING_AMOUNT / MIN_INVESTMENT) + 1;
            uint256 investAmount = MIN_INVESTMENT * unitCount;

            vm.startPrank(investor);
            usdt.mint(investor, investAmount);
            usdt.approve(address(this), investAmount);

            vm.expectRevert(IInvestmentErrors.ExceedOfferingAmount.selector);
            Invest(target).invest(PRODUCT_ID, unitCount);

            Schema.Product memory product = Storage.ProductsState().products[PRODUCT_ID];
            assertEq(product.raisedAmount, 0);
            assertEq(product.productPool, 0);
            assertEq(usdt.balanceOf(investor), investAmount);
            assertEq(nft.balanceOf(investor), 0);
            vm.stopPrank();
        }

        // Case 2: Cumulative investment overflow with existing balance
        {
            Storage.ProductsState().products[PRODUCT_ID].raisedAmount = OFFERING_AMOUNT - (MIN_INVESTMENT / 2);
            uint256 unitCount = 1;
            uint256 investAmount = MIN_INVESTMENT * unitCount;

            vm.startPrank(investor);

            // Reset the settings for case 1
            usdt.burn(investor, usdt.balanceOf(investor));
            usdt.mint(investor, investAmount);
            usdt.approve(address(this), 0);
            usdt.approve(address(this), investAmount);

            vm.expectRevert(IInvestmentErrors.ExceedOfferingAmount.selector);
            Invest(target).invest(PRODUCT_ID, unitCount);

            Schema.Product memory product = Storage.ProductsState().products[PRODUCT_ID];
            assertEq(product.raisedAmount, OFFERING_AMOUNT - (MIN_INVESTMENT / 2));
            assertEq(usdt.balanceOf(investor), investAmount);
            assertEq(nft.balanceOf(investor), 0);
            vm.stopPrank();
        }
    }

    function testFuzz_invest_revert_whenExceedOfferingAmount(uint256 existingRaisedAmount, uint256 unitCount) public {
        existingRaisedAmount = bound(existingRaisedAmount, 0, OFFERING_AMOUNT);
        unitCount = bound(unitCount, 1, type(uint64).max);

        uint256 investAmount = MIN_INVESTMENT * unitCount;
        // Test only cases where total investment exceeds offering amount
        vm.assume(existingRaisedAmount + investAmount > OFFERING_AMOUNT);

        Storage.ProductsState().products[PRODUCT_ID].raisedAmount = existingRaisedAmount;

        vm.startPrank(investor);
        usdt.mint(investor, investAmount);
        usdt.approve(address(this), investAmount);

        vm.expectRevert(IInvestmentErrors.ExceedOfferingAmount.selector);
        Invest(target).invest(PRODUCT_ID, unitCount);

        Schema.Product memory product = Storage.ProductsState().products[PRODUCT_ID];
        assertEq(product.raisedAmount, existingRaisedAmount);
        assertEq(usdt.balanceOf(investor), investAmount);
        assertEq(nft.balanceOf(investor), 0);

        vm.stopPrank();
    }

    function test_invest_revert_whenInsufficientBalance() public {
        uint256 unitCount = 1;

        vm.startPrank(investor);

        usdt.approve(address(this), MIN_INVESTMENT);

        vm.expectRevert(IInvestmentErrors.InsufficientFunds.selector);
        Invest(target).invest(PRODUCT_ID, unitCount);

        Schema.Product memory product = Storage.ProductsState().products[PRODUCT_ID];
        assertEq(product.raisedAmount, 0);
        assertEq(product.productPool, 0);
        assertEq(nft.balanceOf(investor), 0);

        vm.stopPrank();
    }

    function test_invest_revert_whenInsufficientAllowance() public {
        uint256 unitCount = 1;
        uint256 investAmount = MIN_INVESTMENT * unitCount;

        usdt.mint(investor, investAmount);

        vm.startPrank(investor);

        vm.expectRevert(IInvestmentErrors.InsufficientAllowance.selector);
        Invest(target).invest(PRODUCT_ID, unitCount);

        Schema.Product memory product = Storage.ProductsState().products[PRODUCT_ID];
        assertEq(product.raisedAmount, 0);
        assertEq(product.productPool, 0);
        assertEq(nft.balanceOf(investor), 0);
        assertEq(usdt.balanceOf(investor), investAmount);

        vm.stopPrank();
    }

    receive() external payable {}
}
