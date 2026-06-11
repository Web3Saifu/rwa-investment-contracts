// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Storage} from "bundle/investment/storage/Storage.sol";
import {Schema} from "bundle/investment/storage/Schema.sol";
import {IInvestmentErrors} from "bundle/investment/interfaces/IInvestmentErrors.sol";
import {IInvestmentEvents} from "bundle/investment/interfaces/IInvestmentEvents.sol";
import {OnlyWhiteListsBase} from "bundle/investment/functions/onlyWhiteLists/OnlyWhiteListsBase.sol";
import {CalculateYieldLib} from "bundle/investment/utils/CalculateYieldLib.sol";
import {DistributionDateLib} from "bundle/investment/utils/DistributionDateLib.sol";
import {UsdtTransferLib} from "bundle/investment/utils/UsdtTransferLib.sol";

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IInvestmentNFT} from "bundle/periphery/interfaces/IInvestmentNFT.sol";

/**
 * @title DistributeYield
 * @notice Contract for managing yield distribution of investment products
 * @dev Inherits from OnlyWhiteListsBase, only executable by whitelisted administrators
 */
contract DistributeYield is ReentrancyGuard, OnlyWhiteListsBase {
    /**
     * @notice Distributes yield for a specified product
     * @dev Calculates and distributes yield to NFT holders based on product status
     * @param productId ID of the product to distribute yield for
     * @custom:throws ProductNotFound When product does not exist
     * @custom:throws MaturedProduct When product has matured
     * @custom:throws BeforeDistributionStartDate When before distribution start date
     * @custom:throws DistributionCompleted When distribution is completed
     * @custom:throws InsufficientFunds When contract balance is insufficient
     * @custom:emits YieldReceived Emitted for each NFT holder receiving yield, includes:
     *    - productId: ID of the product
     *    - tokenId: ID of the NFT receiving yield
     *    - recipient: Address receiving the yield
     *    - amount: Amount of yield received
     * @custom:emits YieldDistributed Emitted after completing a distribution batch, includes:
     *    - productId: ID of the product
     *    - distributionCount: Current distribution count
     *    - startTokenId: First token ID in the batch
     *    - endTokenId: Last token ID in the batch
     *    - totalAmount: Total yield distributed in this batch
     */
    function distributeYield(uint256 productId) external nonReentrant onlyWhiteLists {
        Schema.Product storage product = Storage.ProductsState().products[productId];
        IERC20 usdt = IERC20(Storage.ConfigState().USDT_ADDRESS);
        IInvestmentNFT nft = IInvestmentNFT(product.nftContract);

        if (product.productId == 0) {
            revert IInvestmentErrors.ProductNotFound();
        }
        if (product.isMaturity) {
            revert IInvestmentErrors.MaturedProduct();
        }
        // Check if distribution count is completed
        if (product.distributedCount >= product.totalDistributionCount) {
            revert IInvestmentErrors.DistributionCompleted();
        }
        // Check if before distribution start date
        uint256 nextDistributionDate = DistributionDateLib.calculateNextDistributionDate(
            product.distributionStartDate, product.distributionInterval, product.distributedCount, product.isMonthEnd
        );
        if (nextDistributionDate > block.timestamp) {
            revert IInvestmentErrors.BeforeDistributionStartDate();
        }

        if (product.raisedAmount == 0) {
            product.distributedCount++;
            product.distributedYieldPerCount = 0;
            if (product.isInsufficientBalance) {
                product.isInsufficientBalance = false;
            }
            emit IInvestmentEvents.YieldDistributed(productId, product.distributedCount, 0, 0, 0);
            return;
        }

        // Calculate yield for distribution period
        uint256 periodYield;
        if (product.distributedCount == 0) {
            // For first distribution
            uint256 firstPeriod = DistributionDateLib.calculateFirstDistributionPeriod(
                product.distributionStartDate, product.operationStartDate
            );
            periodYield =
                CalculateYieldLib.calculatePeriodYield(product.raisedAmount, product.expectedYield, firstPeriod);
        } else {
            // For 2nd distribution onwards: calculate period in seconds using library
            uint256 period = DistributionDateLib.calculateDistributionPeriod(
                product.distributionStartDate,
                product.distributionInterval,
                product.distributedCount,
                product.isMonthEnd
            );
            periodYield = CalculateYieldLib.calculatePeriodYield(product.raisedAmount, product.expectedYield, period);
        }

        uint256 lastTokenId = nft.tokenIdCounter();
        uint256 periodTolerance = CalculateYieldLib.calculatePeriodTolerance(lastTokenId);
        uint256 periodToleranceRemainder =
            CalculateYieldLib.calculatePeriodToleranceRemainder(product.distributedTokenId, periodTolerance);

        // Check product pool balance
        if (periodYield + periodToleranceRemainder - product.distributedYieldPerCount > product.productPool) {
            product.isInsufficientBalance = true;
            emit IInvestmentEvents.InsufficientProductPoolForDistribution(productId);
            return;
        }

        // Check contract balance
        if (periodYield + periodToleranceRemainder - product.distributedYieldPerCount > usdt.balanceOf(address(this))) {
            revert IInvestmentErrors.InsufficientFunds();
        }

        uint256 startTokenId = product.distributedTokenId + 1;
        IInvestmentNFT.NFTInfo[] memory nftInfos = nft.getNFTInfos(startTokenId);
        uint256 _distributedYield = 0;
        uint256 distributionIndex = product.distributedCount + 1;
        Schema.$EscrowState storage escrow = Storage.EscrowState();
        // Distribution to each NFT holder
        for (uint256 i = 0; i < nftInfos.length; i++) {
            uint256 individualPeriodYield = CalculateYieldLib.calculateIndividualPeriodYield(
                periodYield, nftInfos[i].investmentAmount, product.raisedAmount
            );

            if (UsdtTransferLib.tryTransfer(usdt, nftInfos[i].owner, individualPeriodYield)) {
                _distributedYield += individualPeriodYield;
                emit IInvestmentEvents.YieldReceived(
                    productId, nftInfos[i].tokenId, nftInfos[i].owner, individualPeriodYield
                );
            } else {
                if (escrow.unclaimedYield[productId][nftInfos[i].tokenId][distributionIndex] != 0) {
                    revert IInvestmentErrors.EscrowAlreadySet();
                }
                escrow.unclaimedYield[productId][nftInfos[i].tokenId][distributionIndex] = individualPeriodYield;
                _distributedYield += individualPeriodYield;
                emit IInvestmentEvents.YieldTransferFailed(
                    productId, nftInfos[i].tokenId, nftInfos[i].owner, individualPeriodYield, distributionIndex
                );
            }

            // Processing when the last NFT is reached
            if (nftInfos[i].tokenId == lastTokenId) {
                product.distributedCount++;
                product.distributedTokenId = 0;
                product.distributedYieldPerCount = 0;
                emit IInvestmentEvents.YieldDistributed(
                    productId, product.distributedCount, startTokenId, lastTokenId, _distributedYield
                );
                // In the case of the last batch processing
            } else if (i == nftInfos.length - 1) {
                product.distributedTokenId = nftInfos[i].tokenId;
                product.distributedYieldPerCount += _distributedYield;
                emit IInvestmentEvents.YieldDistributed(
                    productId, product.distributedCount + 1, startTokenId, nftInfos[i].tokenId, _distributedYield
                );
            }
        }

        product.productPool -= _distributedYield;
        if (product.isInsufficientBalance) {
            product.isInsufficientBalance = false;
        }
    }
}

// Testing
import {MCTest} from "@mc-devkit/Flattened.sol";
import {MockInvestmentERC20} from "test/investment/mocks/MockInvestmentERC20.sol";
import {InvestmentNFT} from "bundle/periphery/InvestmentNFT.sol";
import {DistributionDateLib} from "bundle/investment/utils/DistributionDateLib.sol";
import {DateTime} from "lib/chainlink-evm/contracts/src/v0.8/vendor/DateTime.sol";

/**
 * @title DistributeYieldTest
 * @notice Test contract for the DistributeYield function contract
 */
contract DistributeYieldTest is MCTest {
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

        // Setup DistributeYield contract
        _use(DistributeYield.distributeYield.selector, address(new DistributeYield()));

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
            isInsufficientBalance: true,
            isMonthEnd: false
        });

        // Setup storage
        Storage.ProductsState().products[PRODUCT_ID] = product;
        Storage.ProductsState().productIdKeys.push(PRODUCT_ID);
        Storage.WhiteListsState().admins.push(admin);
        Storage.ConfigState().USDT_ADDRESS = address(usdt);
    }

    // Test the first of multiple profit distributions
    function test_distributeYield_success_distributedCount0() public {
        uint256 distributionCount = 1;
        uint256 startTokenId = 1;
        uint256 endTokenId = 2;
        uint256 investment1 = OFFERING_AMOUNT / 2;
        uint256 investment2 = OFFERING_AMOUNT / 2;
        uint256 resetTokenId = 0;
        uint256 resetDistributedYieldPerCount = 0;
        uint256 firstPeriod =
            DistributionDateLib.calculateFirstDistributionPeriod(DISTRIBUTION_START_DATE, OPERATION_STARTDATE);

        // Setup product
        Schema.Product storage product = Storage.ProductsState().products[PRODUCT_ID];
        product.raisedAmount = investment1 + investment2;

        nft.mint(investor1, investment1);
        nft.mint(investor2, investment2);

        // Calculate the first distribution
        uint256 periodYield =
            CalculateYieldLib.calculatePeriodYield(product.raisedAmount, product.expectedYield, firstPeriod);
        uint256 individualPeriodYield1 =
            CalculateYieldLib.calculateIndividualPeriodYield(periodYield, investment1, product.raisedAmount);
        uint256 individualPeriodYield2 =
            CalculateYieldLib.calculateIndividualPeriodYield(periodYield, investment2, product.raisedAmount);

        // Calculate the tolerance
        uint256 tolerance = CalculateYieldLib.calculatePeriodTolerance(endTokenId);

        product.productPool = periodYield + tolerance;
        usdt.mint(address(this), periodYield + tolerance);

        vm.startPrank(admin);
        vm.warp(DISTRIBUTION_START_DATE);

        vm.expectEmit(true, true, true, true);
        emit IInvestmentEvents.YieldReceived(PRODUCT_ID, startTokenId, investor1, individualPeriodYield1);

        vm.expectEmit(true, true, true, true);
        emit IInvestmentEvents.YieldReceived(PRODUCT_ID, startTokenId + 1, investor2, individualPeriodYield2);

        vm.expectEmit(true, false, false, true);
        emit IInvestmentEvents.YieldDistributed(
            PRODUCT_ID, distributionCount, startTokenId, endTokenId, individualPeriodYield1 + individualPeriodYield2
        );

        DistributeYield(target).distributeYield(PRODUCT_ID);

        assertEq(product.distributedCount, distributionCount);
        assertEq(product.distributedTokenId, resetTokenId);
        assertEq(product.distributedYieldPerCount, resetDistributedYieldPerCount);
        assertEq(usdt.balanceOf(investor1), individualPeriodYield1);
        assertEq(usdt.balanceOf(investor2), individualPeriodYield2);
        assertEq(product.productPool, usdt.balanceOf(address(this)));
        assertTrue(tolerance >= product.productPool && product.productPool >= 0);
        assertEq(product.isInsufficientBalance, false);

        vm.stopPrank();
    }

    // Test the second wnwards of multiple profit distributions
    function test_distributeYield_success_distributedCount1() public {
        uint256 distributionCount = 2;
        uint256 startTokenId = 1;
        uint256 endTokenId = 2;
        uint256 investment1 = OFFERING_AMOUNT / 2;
        uint256 investment2 = OFFERING_AMOUNT / 2;
        uint256 resetTokenId = 0;
        uint256 resetDistributedYieldPerCount = 0;

        // Setup product
        Schema.Product storage product = Storage.ProductsState().products[PRODUCT_ID];
        product.distributedCount = 1;
        product.raisedAmount = investment1 + investment2;

        nft.mint(investor1, investment1);
        nft.mint(investor2, investment2);

        // Calculate the second distribution period in seconds using library
        uint256 period = DistributionDateLib.calculateDistributionPeriod(
            product.distributionStartDate, product.distributionInterval, product.distributedCount, product.isMonthEnd
        );
        uint256 periodYield =
            CalculateYieldLib.calculatePeriodYield(product.raisedAmount, product.expectedYield, period);
        uint256 individualPeriodYield1 =
            CalculateYieldLib.calculateIndividualPeriodYield(periodYield, investment1, product.raisedAmount);
        uint256 individualPeriodYield2 =
            CalculateYieldLib.calculateIndividualPeriodYield(periodYield, investment2, product.raisedAmount);

        // Calculate the tolerance
        uint256 tolerance = CalculateYieldLib.calculatePeriodTolerance(endTokenId);

        product.productPool = periodYield + tolerance;
        usdt.mint(address(this), periodYield + tolerance);

        // Calculate next distribution date using DistributionDateLib
        uint256 nextDistributionDate = DistributionDateLib.calculateNextDistributionDate(
            DISTRIBUTION_START_DATE, DISTRIBUTION_INTERVAL, product.distributedCount, product.isMonthEnd
        );

        vm.startPrank(admin);
        vm.warp(nextDistributionDate);

        vm.expectEmit(true, true, true, true);
        emit IInvestmentEvents.YieldReceived(PRODUCT_ID, startTokenId, investor1, individualPeriodYield1);

        vm.expectEmit(true, true, true, true);
        emit IInvestmentEvents.YieldReceived(PRODUCT_ID, startTokenId + 1, investor2, individualPeriodYield2);

        vm.expectEmit(true, false, false, true);
        emit IInvestmentEvents.YieldDistributed(
            PRODUCT_ID, distributionCount, startTokenId, endTokenId, individualPeriodYield1 + individualPeriodYield2
        );

        DistributeYield(target).distributeYield(PRODUCT_ID);

        assertEq(product.distributedCount, distributionCount);
        assertEq(product.distributedTokenId, resetTokenId);
        assertEq(product.distributedYieldPerCount, resetDistributedYieldPerCount);
        assertEq(usdt.balanceOf(investor1), individualPeriodYield1);
        assertEq(usdt.balanceOf(investor2), individualPeriodYield2);
        assertEq(product.productPool, usdt.balanceOf(address(this)));
        assertTrue(tolerance >= product.productPool && product.productPool >= 0);
        assertEq(product.isInsufficientBalance, false);

        vm.stopPrank();
    }

    /// @notice Test distribution with month-end logic
    function test_distributeYield_success_withMonthEnd() public {
        uint256 distributionCount = 1;
        uint256 startTokenId = 1;
        uint256 endTokenId = 2;
        uint256 investment1 = OFFERING_AMOUNT / 2;
        uint256 investment2 = OFFERING_AMOUNT / 2;
        uint256 resetTokenId = 0;
        uint256 resetDistributedYieldPerCount = 0;

        // Set distributionStartDate to month end (2025-01-31 00:00:00 UTC)
        uint256 monthEndDate = DateTime.toTimestamp(2025, 1, 31, 0, 0, 0);
        uint256 operationStart = monthEndDate - 30 days;
        uint256 firstPeriod = DistributionDateLib.calculateFirstDistributionPeriod(monthEndDate, operationStart);

        // Setup product
        Schema.Product storage product = Storage.ProductsState().products[PRODUCT_ID];
        product.operationStartDate = operationStart;
        product.distributionStartDate = monthEndDate;
        product.distributionInterval = 1; // 1 month
        product.isMonthEnd = true; // Month end flag set
        product.raisedAmount = investment1 + investment2;

        nft.mint(investor1, investment1);
        nft.mint(investor2, investment2);

        // Calculate the first distribution
        uint256 periodYield =
            CalculateYieldLib.calculatePeriodYield(product.raisedAmount, product.expectedYield, firstPeriod);
        uint256 individualPeriodYield1 =
            CalculateYieldLib.calculateIndividualPeriodYield(periodYield, investment1, product.raisedAmount);
        uint256 individualPeriodYield2 =
            CalculateYieldLib.calculateIndividualPeriodYield(periodYield, investment2, product.raisedAmount);

        // Calculate the tolerance
        uint256 tolerance = CalculateYieldLib.calculatePeriodTolerance(endTokenId);

        product.productPool = periodYield + tolerance;
        usdt.mint(address(this), periodYield + tolerance);

        vm.startPrank(admin);
        vm.warp(monthEndDate);

        vm.expectEmit(true, true, true, true);
        emit IInvestmentEvents.YieldReceived(PRODUCT_ID, startTokenId, investor1, individualPeriodYield1);

        vm.expectEmit(true, true, true, true);
        emit IInvestmentEvents.YieldReceived(PRODUCT_ID, startTokenId + 1, investor2, individualPeriodYield2);

        vm.expectEmit(true, false, false, true);
        emit IInvestmentEvents.YieldDistributed(
            PRODUCT_ID, distributionCount, startTokenId, endTokenId, individualPeriodYield1 + individualPeriodYield2
        );

        DistributeYield(target).distributeYield(PRODUCT_ID);

        assertEq(product.distributedCount, distributionCount);
        assertEq(product.distributedTokenId, resetTokenId);
        assertEq(product.distributedYieldPerCount, resetDistributedYieldPerCount);
        assertEq(usdt.balanceOf(investor1), individualPeriodYield1);
        assertEq(usdt.balanceOf(investor2), individualPeriodYield2);
        assertEq(product.productPool, usdt.balanceOf(address(this)));
        assertTrue(tolerance >= product.productPool && product.productPool >= 0);
        assertEq(product.isInsufficientBalance, false);

        vm.stopPrank();
    }

    // Test the distribution of multiple batches when the number of investors is greater than 51
    function test_distributeYield_success_investorsMoreThan51() public {
        uint256 distributionCount1 = 1;
        uint256 distributionCount2 = 2;
        uint256 startTokenId = 1;
        uint256 endTokenId = 100;
        uint256 investmentPerUser = OFFERING_AMOUNT / endTokenId;
        uint256 resetTokenId = 0;
        uint256 resetDistributedYieldPerCount = 0;
        uint256 firstPeriod =
            DistributionDateLib.calculateFirstDistributionPeriod(DISTRIBUTION_START_DATE, OPERATION_STARTDATE);

        // Setup product
        Schema.Product storage product = Storage.ProductsState().products[PRODUCT_ID];
        product.raisedAmount = OFFERING_AMOUNT;

        // Mint NFTs for investors
        for (uint256 i = 0; i < endTokenId; i++) {
            nft.mint(address(uint160(uint160(investor1) + i)), investmentPerUser);
        }

        //-------------------------------------------
        // Count1: Execute first batch
        //-------------------------------------------
        emit log("Count1: Execute first batch");

        // Calculate the first distribution
        uint256 periodYieldPerCount1 =
            CalculateYieldLib.calculatePeriodYield(product.raisedAmount, product.expectedYield, firstPeriod);
        uint256 investmentPeriodYieldPerCount1 = CalculateYieldLib.calculateIndividualPeriodYield(
            periodYieldPerCount1, investmentPerUser, product.raisedAmount
        );
        uint256 distributedYieldPerBatchCount1 = investmentPeriodYieldPerCount1 * 50;

        // Calculate the tolerance
        uint256 tolerance = CalculateYieldLib.calculatePeriodTolerance(endTokenId);

        product.productPool = periodYieldPerCount1 + tolerance;
        usdt.mint(address(this), periodYieldPerCount1 + tolerance);

        vm.startPrank(admin);
        vm.warp(DISTRIBUTION_START_DATE);

        for (uint256 i = 0; i < 50; i++) {
            vm.expectEmit(true, true, true, true);
            emit IInvestmentEvents.YieldReceived(
                PRODUCT_ID, startTokenId + i, address(uint160(uint160(investor1) + i)), investmentPeriodYieldPerCount1
            );
        }

        vm.expectEmit(true, true, true, true);
        emit IInvestmentEvents.YieldDistributed(
            PRODUCT_ID, distributionCount1, startTokenId, 50, distributedYieldPerBatchCount1
        );

        DistributeYield(target).distributeYield(PRODUCT_ID);

        // Verify first batch state
        assertEq(product.distributedCount, 0, "missmatch distributedCount 0");
        assertEq(product.distributedTokenId, 50, "missmatch distributedTokenId 50");
        for (uint256 i = 0; i < 50; i++) {
            assertEq(
                usdt.balanceOf(address(uint160(uint160(investor1) + i))),
                investmentPeriodYieldPerCount1,
                "missmatch usdt balance investmentPeriodYieldPerCount1"
            );
        }
        assertEq(
            product.productPool, usdt.balanceOf(address(this)), "missmatch productPool usdt.balanceOf(address(this))"
        );
        assertEq(
            product.distributedYieldPerCount,
            distributedYieldPerBatchCount1,
            "missmatch distributedYieldPerCount distributedYieldPerBatchCount1"
        );

        //-------------------------------------------
        // Count1: Execute second batch
        //-------------------------------------------
        emit log("Count1: Execute second batch");

        for (uint256 i = 50; i < endTokenId; i++) {
            // address recipient = address(uint160(uint160(investor1) + i));
            vm.expectEmit(true, true, true, true);
            emit IInvestmentEvents.YieldReceived(
                PRODUCT_ID, startTokenId + i, address(uint160(uint160(investor1) + i)), investmentPeriodYieldPerCount1
            );
        }

        vm.expectEmit(true, true, true, true);
        emit IInvestmentEvents.YieldDistributed(
            PRODUCT_ID, distributionCount1, 51, endTokenId, distributedYieldPerBatchCount1
        );

        DistributeYield(target).distributeYield(PRODUCT_ID);

        // Verify second batch state
        assertEq(product.distributedCount, distributionCount1, "missmatch distributedCount distributionCount1");
        assertEq(product.distributedTokenId, resetTokenId, "missmatch distributedTokenId resetTokenId");
        assertEq(
            product.distributedYieldPerCount,
            resetDistributedYieldPerCount,
            "missmatch distributedYieldPerCount resetDistributedYieldPerCount"
        );
        for (uint256 i = 0; i < endTokenId; i++) {
            assertEq(
                usdt.balanceOf(address(uint160(uint160(investor1) + i))),
                investmentPeriodYieldPerCount1,
                "missmatch usdt balance investmentPeriodYieldPerCount1"
            );
        }
        assertEq(
            product.productPool, usdt.balanceOf(address(this)), "missmatch productPool usdt.balanceOf(address(this))"
        );
        assertTrue(tolerance >= product.productPool && product.productPool >= 0, "missmatch productPool tolerance");

        vm.stopPrank();

        //-------------------------------------------
        // Count2: Execute first batch
        //-------------------------------------------
        emit log("Count2: Execute first batch");

        // Calculate the second distribution period in seconds using library
        uint256 period2 = DistributionDateLib.calculateDistributionPeriod(
            product.distributionStartDate, product.distributionInterval, product.distributedCount, product.isMonthEnd
        );
        uint256 periodYieldPerCount2 =
            CalculateYieldLib.calculatePeriodYield(product.raisedAmount, product.expectedYield, period2);
        uint256 investmentPeriodYieldPerCount2 = CalculateYieldLib.calculateIndividualPeriodYield(
            periodYieldPerCount2, investmentPerUser, product.raisedAmount
        );
        uint256 distributedYieldPerBatchCount2 = investmentPeriodYieldPerCount2 * 50;

        product.productPool = product.productPool + periodYieldPerCount2 + tolerance;
        usdt.mint(address(this), periodYieldPerCount2 + tolerance);

        // Calculate next distribution date using DistributionDateLib
        uint256 nextDistributionDate2 = DistributionDateLib.calculateNextDistributionDate(
            DISTRIBUTION_START_DATE, DISTRIBUTION_INTERVAL, product.distributedCount, product.isMonthEnd
        );

        vm.startPrank(admin);
        vm.warp(nextDistributionDate2);

        for (uint256 i = 0; i < 50; i++) {
            vm.expectEmit(true, true, true, true);
            emit IInvestmentEvents.YieldReceived(
                PRODUCT_ID, startTokenId + i, address(uint160(uint160(investor1) + i)), investmentPeriodYieldPerCount2
            );
        }

        vm.expectEmit(true, true, true, true);
        emit IInvestmentEvents.YieldDistributed(
            PRODUCT_ID, distributionCount2, startTokenId, 50, distributedYieldPerBatchCount2
        );

        DistributeYield(target).distributeYield(PRODUCT_ID);

        // Verify first batch state
        assertEq(product.distributedCount, distributionCount1, "missmatch distributedCount distributionCount1");
        assertEq(product.distributedTokenId, 50, "missmatch distributedTokenId 50");
        for (uint256 i = 0; i < 50; i++) {
            assertEq(
                usdt.balanceOf(address(uint160(uint160(investor1) + i))),
                investmentPeriodYieldPerCount1 + investmentPeriodYieldPerCount2,
                "missmatch usdt balance investmentPeriodYieldPerCount1 + investmentPeriodYieldPerCount2"
            );
        }
        assertEq(
            product.productPool, usdt.balanceOf(address(this)), "missmatch productPool usdt.balanceOf(address(this))"
        );
        assertEq(
            product.distributedYieldPerCount,
            distributedYieldPerBatchCount2,
            "missmatch distributedYieldPerCount distributedYieldPerBatchCount2"
        );

        //-------------------------------------------
        // Count2: Execute second batch
        //-------------------------------------------
        emit log("Count2: Execute second batch");

        for (uint256 i = 50; i < endTokenId; i++) {
            vm.expectEmit(true, true, true, true);
            emit IInvestmentEvents.YieldReceived(
                PRODUCT_ID, startTokenId + i, address(uint160(uint160(investor1) + i)), investmentPeriodYieldPerCount2
            );
        }

        vm.expectEmit(true, true, true, true);
        emit IInvestmentEvents.YieldDistributed(
            PRODUCT_ID, distributionCount2, 51, endTokenId, distributedYieldPerBatchCount2
        );

        DistributeYield(target).distributeYield(PRODUCT_ID);

        // Verify second batch state
        assertEq(product.distributedCount, distributionCount2, "missmatch distributedCount distributionCount2");
        assertEq(product.distributedTokenId, resetTokenId, "missmatch distributedTokenId resetTokenId");
        assertEq(
            product.distributedYieldPerCount,
            resetDistributedYieldPerCount,
            "missmatch distributedYieldPerCount resetDistributedYieldPerCount"
        );
        for (uint256 i = 0; i < endTokenId; i++) {
            assertEq(
                usdt.balanceOf(address(uint160(uint160(investor1) + i))),
                investmentPeriodYieldPerCount1 + investmentPeriodYieldPerCount2,
                "missmatch usdt balance investmentPeriodYieldPerCount1 + investmentPeriodYieldPerCount2"
            );
        }
        assertEq(
            product.productPool, usdt.balanceOf(address(this)), "missmatch productPool usdt.balanceOf(address(this))"
        );
        assertTrue(
            tolerance * distributionCount2 >= product.productPool && product.productPool >= 0,
            "missmatch productPool tolerance"
        );
        assertEq(product.isInsufficientBalance, false);

        vm.stopPrank();
    }

    // Define a structure for calculations to avoid deep stacks
    struct DistributionVars {
        uint256 distributionCount;
        uint256 startTokenId;
        uint256 endTokenId;
        uint256 resetTokenId;
        uint256 resetDistributedYieldPerCount;
        uint256 tolerance;
        uint256 periodYield;
        uint256 individualPeriodYield1;
        uint256 individualPeriodYield2;
    }

    /// @dev Distributed testing is performed only for the count of the distributedCount value of fuzzing.
    function testFuzz_distributeYield_success(
        uint256 investment1,
        uint256 investment2,
        uint256 expectedYield,
        uint256 distributionStartDate,
        uint256 distributedCount
    ) public {
        investment1 = bound(investment1, MIN_INVESTMENT, OFFERING_AMOUNT);
        investment2 = bound(investment2, MIN_INVESTMENT, OFFERING_AMOUNT);
        vm.assume(investment1 + investment2 <= OFFERING_AMOUNT);
        expectedYield = bound(expectedYield, 10, 1000);
        distributionStartDate = bound(
            distributionStartDate,
            1739145600, // 2025-02-10 00:00:00 UTC
            1748736000 // 2025-06-01 00:00:00 UTC
        );

        distributedCount = bound(distributedCount, 0, 2);

        DistributionVars memory vars = DistributionVars({
            distributionCount: distributedCount + 1,
            startTokenId: 1,
            endTokenId: 2,
            resetTokenId: 0,
            resetDistributedYieldPerCount: 0,
            tolerance: 3,
            periodYield: 0,
            individualPeriodYield1: 0,
            individualPeriodYield2: 0
        });

        // Setup product
        Schema.Product storage product = Storage.ProductsState().products[PRODUCT_ID];
        product.expectedYield = expectedYield;
        product.distributionStartDate = distributionStartDate;
        product.distributedCount = distributedCount;
        product.raisedAmount = investment1 + investment2;

        nft.mint(investor1, investment1);
        nft.mint(investor2, investment2);

        if (distributedCount == 0) {
            uint256 firstPeriod = DistributionDateLib.calculateFirstDistributionPeriod(
                product.distributionStartDate, OPERATION_STARTDATE
            );
            vars.periodYield =
                CalculateYieldLib.calculatePeriodYield(product.raisedAmount, product.expectedYield, firstPeriod);
            vars.individualPeriodYield1 =
                CalculateYieldLib.calculateIndividualPeriodYield(vars.periodYield, investment1, product.raisedAmount);
            vars.individualPeriodYield2 =
                CalculateYieldLib.calculateIndividualPeriodYield(vars.periodYield, investment2, product.raisedAmount);
        } else {
            // For 2nd distribution onwards: calculate period in seconds using library
            uint256 period = DistributionDateLib.calculateDistributionPeriod(
                product.distributionStartDate,
                product.distributionInterval,
                product.distributedCount,
                product.isMonthEnd
            );
            vars.periodYield =
                CalculateYieldLib.calculatePeriodYield(product.raisedAmount, product.expectedYield, period);
            vars.individualPeriodYield1 =
                CalculateYieldLib.calculateIndividualPeriodYield(vars.periodYield, investment1, product.raisedAmount);
            vars.individualPeriodYield2 =
                CalculateYieldLib.calculateIndividualPeriodYield(vars.periodYield, investment2, product.raisedAmount);
        }

        product.productPool = vars.periodYield + vars.tolerance;
        usdt.mint(address(this), vars.periodYield + vars.tolerance);

        // Calculate next distribution date using DistributionDateLib
        uint256 nextDistributionDate = DistributionDateLib.calculateNextDistributionDate(
            distributionStartDate, DISTRIBUTION_INTERVAL, distributedCount, product.isMonthEnd
        );

        vm.startPrank(admin);
        vm.warp(nextDistributionDate);

        // log
        emit log_named_uint("test-distributedCount", distributedCount);
        emit log_named_uint("test-raisedAmount", product.raisedAmount);
        emit log_named_uint("test-expectedYield", product.expectedYield);
        emit log_named_uint("test-distributionStartDate", product.distributionStartDate);
        emit log_named_uint("test-operationStartDate", product.operationStartDate);
        emit log_named_uint("test-distributionInterval", product.distributionInterval);
        emit log_named_uint("test-periodYield", vars.periodYield);
        emit log_named_uint("test-individualPeriodYield1", vars.individualPeriodYield1);
        emit log_named_uint("test-individualPeriodYield2", vars.individualPeriodYield2);

        vm.expectEmit(true, true, true, true);
        emit IInvestmentEvents.YieldReceived(PRODUCT_ID, vars.startTokenId, investor1, vars.individualPeriodYield1);

        vm.expectEmit(true, true, true, true);
        emit IInvestmentEvents.YieldReceived(PRODUCT_ID, vars.startTokenId + 1, investor2, vars.individualPeriodYield2);

        vm.expectEmit(true, false, false, true);
        emit IInvestmentEvents.YieldDistributed(
            PRODUCT_ID,
            vars.distributionCount,
            vars.startTokenId,
            vars.endTokenId,
            vars.individualPeriodYield1 + vars.individualPeriodYield2
        );

        DistributeYield(target).distributeYield(PRODUCT_ID);

        assertEq(product.distributedCount, vars.distributionCount);
        assertEq(product.distributedTokenId, vars.resetTokenId);
        assertEq(product.distributedYieldPerCount, vars.resetDistributedYieldPerCount);
        assertEq(usdt.balanceOf(investor1), vars.individualPeriodYield1);
        assertEq(usdt.balanceOf(investor2), vars.individualPeriodYield2);
        assertEq(product.productPool, usdt.balanceOf(address(this)));
        assertTrue(vars.tolerance >= product.productPool && product.productPool >= 0);
        assertEq(product.isInsufficientBalance, false);

        vm.stopPrank();
    }

    function test_distributeYield_revert_whenNotAdmin() public {
        vm.startPrank(notAdmin);

        vm.expectRevert(IInvestmentErrors.NotAdmin.selector);
        DistributeYield(target).distributeYield(PRODUCT_ID);

        vm.stopPrank();
    }

    function test_distributeYield_revert_whenProductNotFound() public {
        uint256 productId = 99;

        vm.startPrank(admin);

        vm.expectRevert(IInvestmentErrors.ProductNotFound.selector);
        DistributeYield(target).distributeYield(productId);

        vm.stopPrank();
    }

    function test_distributeYield_revert_whenBeforeDistributionStartDate() public {
        vm.startPrank(admin);
        vm.warp(DISTRIBUTION_START_DATE - 1);

        vm.expectRevert(IInvestmentErrors.BeforeDistributionStartDate.selector);
        DistributeYield(target).distributeYield(PRODUCT_ID);

        vm.stopPrank();
    }

    function test_distributeYield_revert_whenMaturedProduct() public {
        Storage.ProductsState().products[PRODUCT_ID].isMaturity = true;

        vm.startPrank(admin);

        vm.expectRevert(IInvestmentErrors.MaturedProduct.selector);
        DistributeYield(target).distributeYield(PRODUCT_ID);

        vm.stopPrank();
    }

    function test_distributeYield_revert_whenDistributionCompleted() public {
        Storage.ProductsState().products[PRODUCT_ID].distributedCount = TOTAL_DISTRIBUTION_COUNT;

        vm.startPrank(admin);
        vm.warp(DISTRIBUTION_START_DATE);

        vm.expectRevert(IInvestmentErrors.DistributionCompleted.selector);
        DistributeYield(target).distributeYield(PRODUCT_ID);

        vm.stopPrank();
    }

    function test_distributeYield_revert_whenInsufficientProductPool() public {
        uint256 investAmount = MIN_INVESTMENT;
        uint256 firstPeriod =
            DistributionDateLib.calculateFirstDistributionPeriod(DISTRIBUTION_START_DATE, OPERATION_STARTDATE);

        // Setup product
        Schema.Product storage product = Storage.ProductsState().products[PRODUCT_ID];
        product.raisedAmount = investAmount;

        nft.mint(investor1, investAmount);

        uint256 expectedPeriodYield =
            CalculateYieldLib.calculatePeriodYield(product.raisedAmount, product.expectedYield, firstPeriod);

        // It's missing by the amount of the tolerance
        product.productPool = expectedPeriodYield;
        product.isInsufficientBalance = false;
        usdt.mint(address(this), expectedPeriodYield);

        vm.startPrank(admin);
        vm.warp(DISTRIBUTION_START_DATE);

        vm.expectEmit(true, false, false, true);
        emit IInvestmentEvents.InsufficientProductPoolForDistribution(PRODUCT_ID);
        DistributeYield(target).distributeYield(PRODUCT_ID);

        assertTrue(product.isInsufficientBalance);

        vm.stopPrank();
    }

    function test_distributeYield_revert_whenInsufficientContractBalance() public {
        uint256 endTokenId = 1;
        uint256 investAmount = MIN_INVESTMENT;
        uint256 firstPeriod =
            DistributionDateLib.calculateFirstDistributionPeriod(DISTRIBUTION_START_DATE, OPERATION_STARTDATE);
        // Setup product
        Schema.Product storage product = Storage.ProductsState().products[PRODUCT_ID];
        product.raisedAmount = investAmount;

        // Calculate the tolerance
        uint256 tolerance = CalculateYieldLib.calculatePeriodTolerance(endTokenId);

        nft.mint(investor1, investAmount);

        uint256 expectedPeriodYield =
            CalculateYieldLib.calculatePeriodYield(product.raisedAmount, product.expectedYield, firstPeriod);

        product.productPool = expectedPeriodYield + tolerance;
        // Note: Not calling usdt.mint() intentionally to create insufficient balance

        vm.startPrank(admin);
        vm.warp(DISTRIBUTION_START_DATE);

        vm.expectRevert(IInvestmentErrors.InsufficientFunds.selector);
        DistributeYield(target).distributeYield(PRODUCT_ID);

        vm.stopPrank();
    }

    function test_distributeYield_escrowOnTransferRevert() public {
        uint256 endTokenId = 2;
        uint256 investment1 = OFFERING_AMOUNT / 2;
        uint256 investment2 = OFFERING_AMOUNT / 2;
        uint256 firstPeriod =
            DistributionDateLib.calculateFirstDistributionPeriod(DISTRIBUTION_START_DATE, OPERATION_STARTDATE);

        Schema.Product storage product = Storage.ProductsState().products[PRODUCT_ID];
        product.raisedAmount = investment1 + investment2;

        nft.mint(investor1, investment1);
        nft.mint(investor2, investment2);

        uint256 periodYield =
            CalculateYieldLib.calculatePeriodYield(product.raisedAmount, product.expectedYield, firstPeriod);
        uint256 individualPeriodYield1 =
            CalculateYieldLib.calculateIndividualPeriodYield(periodYield, investment1, product.raisedAmount);
        uint256 individualPeriodYield2 =
            CalculateYieldLib.calculateIndividualPeriodYield(periodYield, investment2, product.raisedAmount);
        uint256 tolerance = CalculateYieldLib.calculatePeriodTolerance(endTokenId);

        product.productPool = periodYield + tolerance;
        usdt.mint(address(this), periodYield + tolerance);
        usdt.setBlocked(investor2, true);

        vm.startPrank(admin);
        vm.warp(DISTRIBUTION_START_DATE);

        vm.expectEmit(true, true, true, true);
        emit IInvestmentEvents.YieldReceived(PRODUCT_ID, 1, investor1, individualPeriodYield1);

        vm.expectEmit(true, true, true, true);
        emit IInvestmentEvents.YieldTransferFailed(PRODUCT_ID, 2, investor2, individualPeriodYield2, 1);

        DistributeYield(target).distributeYield(PRODUCT_ID);

        assertEq(product.distributedCount, 1);
        assertEq(usdt.balanceOf(investor1), individualPeriodYield1);
        assertEq(usdt.balanceOf(investor2), 0);
        assertEq(Storage.EscrowState().unclaimedYield[PRODUCT_ID][2][1], individualPeriodYield2);

        vm.stopPrank();
    }

    receive() external payable {}
}
