// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Storage} from "bundle/investment/storage/Storage.sol";
import {Schema} from "bundle/investment/storage/Schema.sol";
import {IInvestmentErrors} from "bundle/investment/interfaces/IInvestmentErrors.sol";
import {IInvestmentEvents} from "bundle/investment/interfaces/IInvestmentEvents.sol";
import {OnlyWhiteListsBase} from "bundle/investment/functions/onlyWhiteLists/OnlyWhiteListsBase.sol";
import {DistributionDateLib} from "bundle/investment/utils/DistributionDateLib.sol";

import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {InvestmentNFT} from "bundle/periphery/InvestmentNFT.sol";

/**
 * @title RegisterProduct
 * @notice Contract for registering new investment products
 * @dev Inherits from OnlyWhiteListsBase to ensure only admins can register products
 */
contract RegisterProduct is OnlyWhiteListsBase {
    using Create2 for *;
    using Strings for uint256;

    /// @notice Salt prefix used for NFT contract deployment
    bytes32 public constant SALT_PREFIX = keccak256("INVESTMENT_NFT");

    /**
     * @notice Registers a new investment product
     * @dev Only callable by whitelisted admins
     * @param args Structure containing all product registration parameters
     * @custom:emits ProductRegistered when product is successfully registered
     * @custom:throws ProductAlreadyExists if product ID already exists
     * @custom:throws InvalidOfferingAmount if offering amount is zero
     * @custom:throws InvalidMinInvestment if minimum investment is invalid
     * @custom:throws InvalidOfferingEndDate if offering end date is invalid
     * @custom:throws InvalidMaturityDate if maturity date is invalid
     * @custom:throws InvalidOperationStartDate if operation start date is invalid
     * @custom:throws InvalidDistributionStartDate if distribution start date is invalid
     * @custom:throws InvalidExpectedYield if expected yield is invalid (must be less than 100% or 10000 basis points)
     * @custom:throws InvalidTotalDistributionCount if distribution count is invalid (must be between 1 and 24 distributions)
     * @custom:throws InvalidDistributionInterval if distribution interval is invalid (must be between 1 day and 365 days)
     * @custom:throws TierNotConfigured if requiredTier is non-zero but has no SBT contracts configured in the registry
     */
    function registerProduct(Schema.RegisterProductArgs calldata args) external onlyWhiteLists {
        if (args.productId == 0) {
            revert IInvestmentErrors.InvalidProductId();
        }
        if (Storage.ProductsState().products[args.productId].productId != 0) {
            revert IInvestmentErrors.ProductAlreadyExists();
        }
        if (args.offeringAmount == 0) {
            revert IInvestmentErrors.InvalidOfferingAmount();
        }
        if (args.minInvestment == 0 || args.minInvestment > args.offeringAmount) {
            revert IInvestmentErrors.InvalidMinInvestment();
        }
        if (args.offeringAmount % args.minInvestment != 0) {
            revert IInvestmentErrors.OfferingAmountNotDivisibleByMinInvestment();
        }
        if (args.offeringEndDate < block.timestamp) {
            revert IInvestmentErrors.InvalidOfferingEndDate();
        }
        if (args.maturityDate < args.offeringEndDate) {
            revert IInvestmentErrors.InvalidMaturityDate();
        }
        if (args.operationStartDate < args.offeringEndDate) {
            revert IInvestmentErrors.InvalidOperationStartDate();
        }
        if (args.distributionStartDate < args.operationStartDate) {
            revert IInvestmentErrors.InvalidDistributionStartDate();
        }
        if (args.expectedYield >= 10000) {
            revert IInvestmentErrors.InvalidExpectedYield();
        }
        if (args.totalDistributionCount == 0 || args.totalDistributionCount > 24) {
            revert IInvestmentErrors.InvalidTotalDistributionCount();
        }
        if (args.totalDistributionCount != 1 && args.distributionInterval == 0 || args.distributionInterval > 999) {
            revert IInvestmentErrors.InvalidDistributionInterval();
        }

        bool isMonthEnd = DistributionDateLib.isMonthEndDate(args.distributionStartDate);
        uint256 lastDistributionDate = DistributionDateLib.calculateNextDistributionDate(
            args.distributionStartDate, args.distributionInterval, args.totalDistributionCount - 1, isMonthEnd
        );
        if (lastDistributionDate > args.maturityDate) {
            revert IInvestmentErrors.InvalidMaturityDate();
        }

        if (args.requiredTier != 0 && Storage.TierRegistryState().allowedByTierAddress[args.requiredTier].length == 0) {
            revert IInvestmentErrors.TierNotConfigured(args.requiredTier);
        }

        // Deploying an NFT Contract Using CREATE2
        bytes32 salt = keccak256(abi.encodePacked(SALT_PREFIX, args.productId));
        bytes memory bytecode = abi.encodePacked(
            type(InvestmentNFT).creationCode,
            abi.encode(
                "Investment NFT",
                string.concat("INV-", args.productId.toString()),
                args.productId,
                args.baseTokenURI,
                address(this)
            )
        );
        address nftContract = Create2.deploy(0, salt, bytecode);

        Schema.Product memory product = Schema.Product({
            productId: args.productId,
            nftContract: nftContract,
            offeringAmount: args.offeringAmount,
            minInvestment: args.minInvestment,
            offeringEndDate: args.offeringEndDate,
            raisedAmount: 0,
            productPool: 0,
            maturityDate: args.maturityDate,
            expectedYield: args.expectedYield,
            operationStartDate: args.operationStartDate,
            distributionStartDate: args.distributionStartDate,
            totalDistributionCount: args.totalDistributionCount,
            distributionInterval: args.distributionInterval,
            distributedCount: 0,
            distributedYieldPerCount: 0,
            distributedTokenId: 0,
            totalReturnedAmount: 0,
            maturedTokenId: 0,
            requiredTier: args.requiredTier,
            isMaturity: false,
            isInsufficientBalance: false,
            isMonthEnd: isMonthEnd
        });

        Storage.ProductsState().products[args.productId] = product;
        Storage.ProductsState().productIdKeys.push(args.productId);
        Storage.ProductsState().activeProductIdKeys.push(args.productId);
        Storage.ProductsState().activeIndex[args.productId] = Storage.ProductsState().activeProductIdKeys.length;

        emit IInvestmentEvents.ProductRegistered(
            args.productId,
            args.offeringAmount,
            args.minInvestment,
            args.offeringEndDate,
            args.maturityDate,
            args.expectedYield,
            args.operationStartDate,
            args.distributionStartDate,
            args.totalDistributionCount,
            args.distributionInterval,
            nftContract,
            args.requiredTier,
            isMonthEnd
        );
    }
}

// Testing
import {MCTest} from "@mc-devkit/Flattened.sol";
import {DateTime} from "lib/chainlink-evm/contracts/src/v0.8/vendor/DateTime.sol";

contract RegisterProductDummySbt {}

/**
 * @title RegisterProductTest
 * @notice Test contract for the RegisterProduct function contract
 */
contract RegisterProductTest is MCTest {
    using Create2 for *;
    using Strings for uint256;

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
    string constant BASE_TOKEN_URI = "https://example.com/metadata/";

    bytes32 constant SALT_PREFIX = keccak256("INVESTMENT_NFT");

    // Test accounts
    address admin = address(0x1);
    address notAdmin = address(0x2);

    Schema.RegisterProductArgs args = Schema.RegisterProductArgs({
        productId: PRODUCT_ID,
        offeringAmount: OFFERING_AMOUNT,
        minInvestment: MIN_INVESTMENT,
        offeringEndDate: OFFERING_END_DATE,
        maturityDate: MATURITY_DATE,
        expectedYield: EXPECTED_YIELD,
        operationStartDate: OPERATION_STARTDATE,
        distributionStartDate: DISTRIBUTION_START_DATE,
        totalDistributionCount: TOTAL_DISTRIBUTION_COUNT,
        distributionInterval: DISTRIBUTION_INTERVAL,
        baseTokenURI: BASE_TOKEN_URI,
        requiredTier: 0
    });

    function setUp() public {
        // Setup RegisterProduct contract
        _use(RegisterProduct.registerProduct.selector, address(new RegisterProduct()));

        // Setup storage
        Storage.WhiteListsState().admins.push(admin);
    }

    function test_registerProduct_success() public {
        uint256 initialLength = Storage.ProductsState().productIdKeys.length;

        // Calculate expected NFT contract address
        bytes32 salt = keccak256(abi.encodePacked(SALT_PREFIX, args.productId));
        bytes memory bytecode = abi.encodePacked(
            type(InvestmentNFT).creationCode,
            abi.encode(
                "Investment NFT",
                string.concat("INV-", args.productId.toString()),
                args.productId,
                args.baseTokenURI,
                target
            )
        );
        address expectedNFTAddress = Create2.computeAddress(salt, keccak256(bytecode), target);

        vm.startPrank(admin);

        vm.expectEmit(true, false, false, true);
        emit IInvestmentEvents.ProductRegistered(
            PRODUCT_ID,
            OFFERING_AMOUNT,
            MIN_INVESTMENT,
            OFFERING_END_DATE,
            MATURITY_DATE,
            EXPECTED_YIELD,
            OPERATION_STARTDATE,
            DISTRIBUTION_START_DATE,
            TOTAL_DISTRIBUTION_COUNT,
            DISTRIBUTION_INTERVAL,
            expectedNFTAddress,
            args.requiredTier,
            DistributionDateLib.isMonthEndDate(DISTRIBUTION_START_DATE)
        );

        RegisterProduct(target).registerProduct(args);

        Schema.Product memory product = Storage.ProductsState().products[PRODUCT_ID];
        assertEq(product.productId, PRODUCT_ID);
        assertEq(product.nftContract, expectedNFTAddress);
        assertEq(product.offeringAmount, OFFERING_AMOUNT);
        assertEq(product.minInvestment, MIN_INVESTMENT);
        assertEq(product.offeringEndDate, OFFERING_END_DATE);
        assertEq(product.maturityDate, MATURITY_DATE);
        assertEq(product.expectedYield, EXPECTED_YIELD);
        assertEq(product.operationStartDate, OPERATION_STARTDATE);
        assertEq(product.distributionStartDate, DISTRIBUTION_START_DATE);
        assertEq(product.totalDistributionCount, TOTAL_DISTRIBUTION_COUNT);
        assertEq(product.distributionInterval, DISTRIBUTION_INTERVAL);
        assertEq(product.raisedAmount, 0);
        assertEq(product.productPool, 0);
        assertEq(product.distributedCount, 0);
        assertEq(product.distributedYieldPerCount, 0);
        assertEq(product.distributedTokenId, 0);
        assertEq(product.totalReturnedAmount, 0);
        assertEq(product.maturedTokenId, 0);
        assertEq(product.requiredTier, 0);
        assertFalse(product.isMaturity);
        assertFalse(product.isInsufficientBalance);
        // DISTRIBUTION_START_DATE is not month-end, so this should be false
        assertFalse(product.isMonthEnd);

        uint256[] memory productIdKeys = Storage.ProductsState().productIdKeys;
        assertEq(productIdKeys.length, initialLength + 1);
        assertEq(productIdKeys[productIdKeys.length - 1], PRODUCT_ID);

        uint256[] memory activeKeys = Storage.ProductsState().activeProductIdKeys;
        assertEq(activeKeys.length, initialLength + 1, "activeProductIdKeys length mismatch");
        assertEq(activeKeys[activeKeys.length - 1], PRODUCT_ID, "activeProductIdKeys last element mismatch");
        assertEq(Storage.ProductsState().activeIndex[PRODUCT_ID], activeKeys.length, "activeIndex mismatch");

        vm.stopPrank();
    }

    function test_registerProduct_storesRequiredTier() public {
        uint256 tierProductId = 99_999;
        uint8 tier = 3;
        Schema.RegisterProductArgs memory tierArgs = Schema.RegisterProductArgs({
            productId: tierProductId,
            offeringAmount: OFFERING_AMOUNT,
            minInvestment: MIN_INVESTMENT,
            offeringEndDate: OFFERING_END_DATE,
            maturityDate: MATURITY_DATE,
            expectedYield: EXPECTED_YIELD,
            operationStartDate: OPERATION_STARTDATE,
            distributionStartDate: DISTRIBUTION_START_DATE,
            totalDistributionCount: TOTAL_DISTRIBUTION_COUNT,
            distributionInterval: DISTRIBUTION_INTERVAL,
            baseTokenURI: BASE_TOKEN_URI,
            requiredTier: tier
        });

        Storage.TierRegistryState().allowedByTierAddress[tier].push(address(new RegisterProductDummySbt()));

        vm.prank(admin);
        RegisterProduct(target).registerProduct(tierArgs);

        assertEq(Storage.ProductsState().products[tierProductId].requiredTier, tier);
    }

    function test_registerProduct_revert_whenRequiredTierNotConfigured() public {
        uint8 tier = 3;
        Schema.RegisterProductArgs memory tierArgs = args;
        tierArgs.productId = 99_998;
        tierArgs.requiredTier = tier;

        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(IInvestmentErrors.TierNotConfigured.selector, tier));
        RegisterProduct(target).registerProduct(tierArgs);
    }

    /// @notice Verifies that isMonthEnd becomes true when distributionStartDate is month-end
    function test_registerProduct_setsIsMonthEnd_whenDistributionStartDateIsMonthEnd() public {
        uint256 initialLength = Storage.ProductsState().productIdKeys.length;

        // Compute month-end date (2025-06-30 00:00:00 UTC)
        uint256 monthEnd = DateTime.toTimestamp(2025, 6, 30, 0, 0, 0);

        Schema.RegisterProductArgs memory monthEndArgs = args;
        monthEndArgs.distributionStartDate = monthEnd;

        vm.startPrank(admin);
        RegisterProduct(target).registerProduct(monthEndArgs);
        vm.stopPrank();

        Schema.Product memory product = Storage.ProductsState().products[PRODUCT_ID];
        assertEq(product.distributionStartDate, monthEnd);
        assertTrue(product.isMonthEnd);

        uint256[] memory productIdKeys = Storage.ProductsState().productIdKeys;
        assertEq(productIdKeys.length, initialLength + 1);
        assertEq(productIdKeys[productIdKeys.length - 1], PRODUCT_ID);
    }

    function testFuzz_registerProduct_success(
        uint256 productId,
        uint256 count,
        uint256 minInvestment,
        uint256 expectedYield,
        uint256 totalDistributionCount,
        uint256 distributionInterval
    ) public {
        // Use temporary variables to reduce stack depth
        Schema.Product memory params;
        vm.assume(productId > 0);
        params.minInvestment = bound(minInvestment, 1, type(uint64).max);
        uint256 unitCount = bound(count, 2, type(uint64).max);
        params.offeringAmount = params.minInvestment * unitCount;
        params.expectedYield = bound(expectedYield, 1, 99);
        params.totalDistributionCount = bound(totalDistributionCount, 1, 12);
        params.distributionInterval = bound(distributionInterval, 1, 999);

        uint256 currentTime = block.timestamp;
        params.offeringEndDate = currentTime + 30 days;
        params.operationStartDate = params.offeringEndDate + 7 days;
        params.distributionStartDate = params.operationStartDate + 30 days;
        {
            bool fuzzIsMonthEnd = DistributionDateLib.isMonthEndDate(params.distributionStartDate);
            uint256 fuzzLastDist = DistributionDateLib.calculateNextDistributionDate(
                params.distributionStartDate,
                params.distributionInterval,
                params.totalDistributionCount - 1,
                fuzzIsMonthEnd
            );
            params.maturityDate = fuzzLastDist + 30 days;
        }

        uint256 initialLength = Storage.ProductsState().productIdKeys.length;
        Schema.RegisterProductArgs memory fuzzArgs = Schema.RegisterProductArgs({
            productId: productId,
            offeringAmount: params.offeringAmount,
            minInvestment: params.minInvestment,
            offeringEndDate: params.offeringEndDate,
            maturityDate: params.maturityDate,
            expectedYield: params.expectedYield,
            operationStartDate: params.operationStartDate,
            distributionStartDate: params.distributionStartDate,
            totalDistributionCount: params.totalDistributionCount,
            distributionInterval: params.distributionInterval,
            baseTokenURI: BASE_TOKEN_URI,
            requiredTier: 0
        });

        // Calculate expected NFT contract address
        bytes32 salt = keccak256(abi.encodePacked(SALT_PREFIX, productId));
        bytes memory bytecode = abi.encodePacked(
            type(InvestmentNFT).creationCode,
            abi.encode("Investment NFT", string.concat("INV-", productId.toString()), productId, BASE_TOKEN_URI, target)
        );
        address expectedNFTAddress = Create2.computeAddress(salt, keccak256(bytecode), target);

        vm.startPrank(admin);

        vm.expectEmit(true, false, false, true);
        emit IInvestmentEvents.ProductRegistered(
            productId,
            params.offeringAmount,
            params.minInvestment,
            params.offeringEndDate,
            params.maturityDate,
            params.expectedYield,
            params.operationStartDate,
            params.distributionStartDate,
            params.totalDistributionCount,
            params.distributionInterval,
            expectedNFTAddress,
            fuzzArgs.requiredTier,
            DistributionDateLib.isMonthEndDate(params.distributionStartDate)
        );

        RegisterProduct(target).registerProduct(fuzzArgs);

        Schema.Product memory product = Storage.ProductsState().products[productId];
        assertEq(product.productId, productId);
        assertEq(product.nftContract, expectedNFTAddress);
        assertEq(product.offeringAmount, params.offeringAmount);
        assertEq(product.minInvestment, params.minInvestment);
        assertEq(product.offeringEndDate, params.offeringEndDate);
        assertEq(product.maturityDate, params.maturityDate);
        assertEq(product.expectedYield, params.expectedYield);
        assertEq(product.operationStartDate, params.operationStartDate);
        assertEq(product.distributionStartDate, params.distributionStartDate);
        assertEq(product.totalDistributionCount, params.totalDistributionCount);
        assertEq(product.distributionInterval, params.distributionInterval);
        assertEq(product.raisedAmount, 0);
        assertEq(product.productPool, 0);
        assertEq(product.distributedCount, 0);
        assertEq(product.distributedYieldPerCount, 0);
        assertEq(product.distributedTokenId, 0);
        assertEq(product.totalReturnedAmount, 0);
        assertEq(product.maturedTokenId, 0);
        assertEq(product.requiredTier, 0);
        assertFalse(product.isMaturity);
        assertFalse(product.isInsufficientBalance);
        // Ensure isMonthEnd is set according to whether distributionStartDate is month-end
        {
            uint8 day = DateTime.getDay(product.distributionStartDate);
            uint8 month = DateTime.getMonth(product.distributionStartDate);
            uint16 year = DateTime.getYear(product.distributionStartDate);
            uint8 maxDay = DateTime.getDaysInMonth(month, year);
            bool expectedIsMonthEnd = (day == maxDay);
            assertEq(product.isMonthEnd, expectedIsMonthEnd);
        }

        uint256[] memory productIdKeys = Storage.ProductsState().productIdKeys;
        assertEq(productIdKeys.length, initialLength + 1);
        assertEq(productIdKeys[productIdKeys.length - 1], product.productId);

        uint256[] memory activeKeys = Storage.ProductsState().activeProductIdKeys;
        assertEq(activeKeys.length, initialLength + 1, "activeProductIdKeys length mismatch (fuzz)");
        assertEq(
            activeKeys[activeKeys.length - 1], product.productId, "activeProductIdKeys last element mismatch (fuzz)"
        );
        assertEq(
            Storage.ProductsState().activeIndex[product.productId], activeKeys.length, "activeIndex mismatch (fuzz)"
        );

        vm.stopPrank();
    }

    function test_registerProduct_revert_whenNotAdmin() public {
        vm.startPrank(notAdmin);

        vm.expectRevert(IInvestmentErrors.NotAdmin.selector);
        RegisterProduct(target).registerProduct(args);

        vm.stopPrank();
    }

    function test_registerProduct_revert_whenProductExists() public {
        vm.startPrank(admin);

        // First registration
        RegisterProduct(target).registerProduct(args);

        // Attempt duplicate registration
        vm.expectRevert(IInvestmentErrors.ProductAlreadyExists.selector);
        RegisterProduct(target).registerProduct(args);

        vm.stopPrank();
    }

    function test_registerProduct_revert_whenInvalidProductId() public {
        Schema.RegisterProductArgs memory invalidProductIdArgs = Schema.RegisterProductArgs({
            productId: 0,
            offeringAmount: OFFERING_AMOUNT,
            minInvestment: MIN_INVESTMENT,
            offeringEndDate: OFFERING_END_DATE,
            maturityDate: MATURITY_DATE,
            expectedYield: EXPECTED_YIELD,
            operationStartDate: OPERATION_STARTDATE,
            distributionStartDate: DISTRIBUTION_START_DATE,
            totalDistributionCount: TOTAL_DISTRIBUTION_COUNT,
            distributionInterval: DISTRIBUTION_INTERVAL,
            baseTokenURI: BASE_TOKEN_URI,
            requiredTier: 0
        });

        vm.startPrank(admin);

        vm.expectRevert(IInvestmentErrors.InvalidProductId.selector);
        RegisterProduct(target).registerProduct(invalidProductIdArgs);

        vm.stopPrank();
    }

    function test_registerProduct_revert_whenInvalidOfferingAmount() public {
        Schema.RegisterProductArgs memory invalidOfferingAmountArgs = Schema.RegisterProductArgs({
            productId: PRODUCT_ID,
            offeringAmount: 0,
            minInvestment: MIN_INVESTMENT,
            offeringEndDate: OFFERING_END_DATE,
            maturityDate: MATURITY_DATE,
            expectedYield: EXPECTED_YIELD,
            operationStartDate: OPERATION_STARTDATE,
            distributionStartDate: DISTRIBUTION_START_DATE,
            totalDistributionCount: TOTAL_DISTRIBUTION_COUNT,
            distributionInterval: DISTRIBUTION_INTERVAL,
            baseTokenURI: BASE_TOKEN_URI,
            requiredTier: 0
        });

        vm.startPrank(admin);

        vm.expectRevert(IInvestmentErrors.InvalidOfferingAmount.selector);
        RegisterProduct(target).registerProduct(invalidOfferingAmountArgs);

        vm.stopPrank();
    }

    function test_registerProduct_revert_whenInvalidMinInvestment() public {
        Schema.RegisterProductArgs memory invalidMinInvestmentArgs = Schema.RegisterProductArgs({
            productId: PRODUCT_ID,
            offeringAmount: OFFERING_AMOUNT,
            minInvestment: 0,
            offeringEndDate: OFFERING_END_DATE,
            maturityDate: MATURITY_DATE,
            expectedYield: EXPECTED_YIELD,
            operationStartDate: OPERATION_STARTDATE,
            distributionStartDate: DISTRIBUTION_START_DATE,
            totalDistributionCount: TOTAL_DISTRIBUTION_COUNT,
            distributionInterval: DISTRIBUTION_INTERVAL,
            baseTokenURI: BASE_TOKEN_URI,
            requiredTier: 0
        });
        Schema.RegisterProductArgs memory invalidMinInvestmentArgs2 = Schema.RegisterProductArgs({
            productId: PRODUCT_ID,
            offeringAmount: OFFERING_AMOUNT,
            minInvestment: OFFERING_AMOUNT + 1,
            offeringEndDate: OFFERING_END_DATE,
            maturityDate: MATURITY_DATE,
            expectedYield: EXPECTED_YIELD,
            operationStartDate: OPERATION_STARTDATE,
            distributionStartDate: DISTRIBUTION_START_DATE,
            totalDistributionCount: TOTAL_DISTRIBUTION_COUNT,
            distributionInterval: DISTRIBUTION_INTERVAL,
            baseTokenURI: BASE_TOKEN_URI,
            requiredTier: 0
        });

        vm.startPrank(admin);

        // Case: minInvestment is 0
        vm.expectRevert(IInvestmentErrors.InvalidMinInvestment.selector);
        RegisterProduct(target).registerProduct(invalidMinInvestmentArgs);

        // Case: minInvestment > offeringAmount
        vm.expectRevert(IInvestmentErrors.InvalidMinInvestment.selector);
        RegisterProduct(target).registerProduct(invalidMinInvestmentArgs2);

        vm.stopPrank();
    }

    function test_registerProduct_revert_whenOfferingAmountNotDivisibleByMinInvestment() public {
        Schema.RegisterProductArgs memory invalidArgs = Schema.RegisterProductArgs({
            productId: PRODUCT_ID,
            offeringAmount: OFFERING_AMOUNT + 1,
            minInvestment: MIN_INVESTMENT,
            offeringEndDate: OFFERING_END_DATE,
            maturityDate: MATURITY_DATE,
            expectedYield: EXPECTED_YIELD,
            operationStartDate: OPERATION_STARTDATE,
            distributionStartDate: DISTRIBUTION_START_DATE,
            totalDistributionCount: TOTAL_DISTRIBUTION_COUNT,
            distributionInterval: DISTRIBUTION_INTERVAL,
            baseTokenURI: BASE_TOKEN_URI,
            requiredTier: 0
        });

        vm.prank(admin);
        vm.expectRevert(IInvestmentErrors.OfferingAmountNotDivisibleByMinInvestment.selector);
        RegisterProduct(target).registerProduct(invalidArgs);
    }

    function test_registerProduct_revert_whenInvalidDates() public {
        Schema.RegisterProductArgs memory invalidOfferingEndDateArgs = Schema.RegisterProductArgs({
            productId: PRODUCT_ID,
            offeringAmount: OFFERING_AMOUNT,
            minInvestment: MIN_INVESTMENT,
            offeringEndDate: block.timestamp - 1,
            maturityDate: MATURITY_DATE,
            expectedYield: EXPECTED_YIELD,
            operationStartDate: OPERATION_STARTDATE,
            distributionStartDate: DISTRIBUTION_START_DATE,
            totalDistributionCount: TOTAL_DISTRIBUTION_COUNT,
            distributionInterval: DISTRIBUTION_INTERVAL,
            baseTokenURI: BASE_TOKEN_URI,
            requiredTier: 0
        });
        Schema.RegisterProductArgs memory invalidMaturityDateArgs = Schema.RegisterProductArgs({
            productId: PRODUCT_ID,
            offeringAmount: OFFERING_AMOUNT,
            minInvestment: MIN_INVESTMENT,
            offeringEndDate: OFFERING_END_DATE,
            maturityDate: OFFERING_END_DATE - 1,
            expectedYield: EXPECTED_YIELD,
            operationStartDate: OPERATION_STARTDATE,
            distributionStartDate: DISTRIBUTION_START_DATE,
            totalDistributionCount: TOTAL_DISTRIBUTION_COUNT,
            distributionInterval: DISTRIBUTION_INTERVAL,
            baseTokenURI: BASE_TOKEN_URI,
            requiredTier: 0
        });
        Schema.RegisterProductArgs memory invalidOperationStartDateArgs = Schema.RegisterProductArgs({
            productId: PRODUCT_ID,
            offeringAmount: OFFERING_AMOUNT,
            minInvestment: MIN_INVESTMENT,
            offeringEndDate: OFFERING_END_DATE,
            maturityDate: MATURITY_DATE,
            expectedYield: EXPECTED_YIELD,
            operationStartDate: OFFERING_END_DATE - 1,
            distributionStartDate: DISTRIBUTION_START_DATE,
            totalDistributionCount: TOTAL_DISTRIBUTION_COUNT,
            distributionInterval: DISTRIBUTION_INTERVAL,
            baseTokenURI: BASE_TOKEN_URI,
            requiredTier: 0
        });
        Schema.RegisterProductArgs memory invalidDistributionStartDateArgs = Schema.RegisterProductArgs({
            productId: PRODUCT_ID,
            offeringAmount: OFFERING_AMOUNT,
            minInvestment: MIN_INVESTMENT,
            offeringEndDate: OFFERING_END_DATE,
            maturityDate: MATURITY_DATE,
            expectedYield: EXPECTED_YIELD,
            operationStartDate: OPERATION_STARTDATE,
            distributionStartDate: OPERATION_STARTDATE - 1,
            totalDistributionCount: TOTAL_DISTRIBUTION_COUNT,
            distributionInterval: DISTRIBUTION_INTERVAL,
            baseTokenURI: BASE_TOKEN_URI,
            requiredTier: 0
        });

        vm.startPrank(admin);

        // Case: offeringEndDate in past
        vm.expectRevert(IInvestmentErrors.InvalidOfferingEndDate.selector);
        RegisterProduct(target).registerProduct(invalidOfferingEndDateArgs);

        // Case: maturityDate before offeringEndDate
        vm.expectRevert(IInvestmentErrors.InvalidMaturityDate.selector);
        RegisterProduct(target).registerProduct(invalidMaturityDateArgs);

        // Case: operationStartDate before offeringEndDate
        vm.expectRevert(IInvestmentErrors.InvalidOperationStartDate.selector);
        RegisterProduct(target).registerProduct(invalidOperationStartDateArgs);

        // Case: distributionStartDate before operationStartDate
        vm.expectRevert(IInvestmentErrors.InvalidDistributionStartDate.selector);
        RegisterProduct(target).registerProduct(invalidDistributionStartDateArgs);

        vm.stopPrank();
    }

    function test_registerProduct_revert_whenInvalidDistributionParams() public {
        Schema.RegisterProductArgs memory invalidExpectedYieldArgs = Schema.RegisterProductArgs({
            productId: PRODUCT_ID,
            offeringAmount: OFFERING_AMOUNT,
            minInvestment: MIN_INVESTMENT,
            offeringEndDate: OFFERING_END_DATE,
            maturityDate: MATURITY_DATE,
            expectedYield: 10000,
            operationStartDate: OPERATION_STARTDATE,
            distributionStartDate: DISTRIBUTION_START_DATE,
            totalDistributionCount: TOTAL_DISTRIBUTION_COUNT,
            distributionInterval: DISTRIBUTION_INTERVAL,
            baseTokenURI: BASE_TOKEN_URI,
            requiredTier: 0
        });
        Schema.RegisterProductArgs memory invalidTotalDistributionCountArgs = Schema.RegisterProductArgs({
            productId: PRODUCT_ID,
            offeringAmount: OFFERING_AMOUNT,
            minInvestment: MIN_INVESTMENT,
            offeringEndDate: OFFERING_END_DATE,
            maturityDate: MATURITY_DATE,
            expectedYield: EXPECTED_YIELD,
            operationStartDate: OPERATION_STARTDATE,
            distributionStartDate: DISTRIBUTION_START_DATE,
            totalDistributionCount: 0,
            distributionInterval: DISTRIBUTION_INTERVAL,
            baseTokenURI: BASE_TOKEN_URI,
            requiredTier: 0
        });
        Schema.RegisterProductArgs memory invalidTotalDistributionCountArgs2 = Schema.RegisterProductArgs({
            productId: PRODUCT_ID,
            offeringAmount: OFFERING_AMOUNT,
            minInvestment: MIN_INVESTMENT,
            offeringEndDate: OFFERING_END_DATE,
            maturityDate: MATURITY_DATE,
            expectedYield: EXPECTED_YIELD,
            operationStartDate: OPERATION_STARTDATE,
            distributionStartDate: DISTRIBUTION_START_DATE,
            totalDistributionCount: 25,
            distributionInterval: DISTRIBUTION_INTERVAL,
            baseTokenURI: BASE_TOKEN_URI,
            requiredTier: 0
        });
        Schema.RegisterProductArgs memory invalidDistributionIntervalArgs = Schema.RegisterProductArgs({
            productId: PRODUCT_ID,
            offeringAmount: OFFERING_AMOUNT,
            minInvestment: MIN_INVESTMENT,
            offeringEndDate: OFFERING_END_DATE,
            maturityDate: MATURITY_DATE,
            expectedYield: EXPECTED_YIELD,
            operationStartDate: OPERATION_STARTDATE,
            distributionStartDate: DISTRIBUTION_START_DATE,
            totalDistributionCount: TOTAL_DISTRIBUTION_COUNT,
            distributionInterval: 0,
            baseTokenURI: BASE_TOKEN_URI,
            requiredTier: 0
        });
        Schema.RegisterProductArgs memory invalidDistributionIntervalArgs2 = Schema.RegisterProductArgs({
            productId: PRODUCT_ID,
            offeringAmount: OFFERING_AMOUNT,
            minInvestment: MIN_INVESTMENT,
            offeringEndDate: OFFERING_END_DATE,
            maturityDate: MATURITY_DATE,
            expectedYield: EXPECTED_YIELD,
            operationStartDate: OPERATION_STARTDATE,
            distributionStartDate: DISTRIBUTION_START_DATE,
            totalDistributionCount: TOTAL_DISTRIBUTION_COUNT,
            distributionInterval: 366 days,
            baseTokenURI: BASE_TOKEN_URI,
            requiredTier: 0
        });

        vm.startPrank(admin);

        // Case: expectedYield >= 100%
        vm.expectRevert(IInvestmentErrors.InvalidExpectedYield.selector);
        RegisterProduct(target).registerProduct(invalidExpectedYieldArgs);

        // Case: totalDistributionCount is 0
        vm.expectRevert(IInvestmentErrors.InvalidTotalDistributionCount.selector);
        RegisterProduct(target).registerProduct(invalidTotalDistributionCountArgs);

        // Case: totalDistributionCount is too large
        vm.expectRevert(IInvestmentErrors.InvalidTotalDistributionCount.selector);
        RegisterProduct(target).registerProduct(invalidTotalDistributionCountArgs2);

        // Case: distributionInterval is 0
        vm.expectRevert(IInvestmentErrors.InvalidDistributionInterval.selector);
        RegisterProduct(target).registerProduct(invalidDistributionIntervalArgs);

        // Case: distributionInterval is too large
        vm.expectRevert(IInvestmentErrors.InvalidDistributionInterval.selector);
        RegisterProduct(target).registerProduct(invalidDistributionIntervalArgs2);

        vm.stopPrank();
    }

    function test_registerProduct_revert_whenLastDistributionDateExceedsMaturityDate() public {
        // distributionStartDate=2025-06-01, interval=3, count=5
        // lastDistributionDate = 2025-06-01 + 3*4 months = 2026-06-01
        // maturityDate = 2025-12-01 → lastDistributionDate > maturityDate → revert
        uint256 earlyMaturity = DateTime.toTimestamp(2025, 12, 1, 0, 0, 0);

        Schema.RegisterProductArgs memory invalidArgs = Schema.RegisterProductArgs({
            productId: PRODUCT_ID,
            offeringAmount: OFFERING_AMOUNT,
            minInvestment: MIN_INVESTMENT,
            offeringEndDate: OFFERING_END_DATE,
            maturityDate: earlyMaturity,
            expectedYield: EXPECTED_YIELD,
            operationStartDate: OPERATION_STARTDATE,
            distributionStartDate: DISTRIBUTION_START_DATE,
            totalDistributionCount: 5,
            distributionInterval: DISTRIBUTION_INTERVAL,
            baseTokenURI: BASE_TOKEN_URI,
            requiredTier: 0
        });

        vm.prank(admin);
        vm.expectRevert(IInvestmentErrors.InvalidMaturityDate.selector);
        RegisterProduct(target).registerProduct(invalidArgs);
    }

    function test_registerProduct_success_whenLastDistributionDateEqualsMaturityDate() public {
        // distributionStartDate=2025-06-01, interval=3, count=3
        // lastDistributionDate = 2025-06-01 + 3*2 months = 2025-12-01
        // maturityDate = 2025-12-01 → lastDistributionDate == maturityDate → success
        uint256 exactMaturity = DateTime.toTimestamp(2025, 12, 1, 0, 0, 0);

        Schema.RegisterProductArgs memory exactArgs = Schema.RegisterProductArgs({
            productId: PRODUCT_ID,
            offeringAmount: OFFERING_AMOUNT,
            minInvestment: MIN_INVESTMENT,
            offeringEndDate: OFFERING_END_DATE,
            maturityDate: exactMaturity,
            expectedYield: EXPECTED_YIELD,
            operationStartDate: OPERATION_STARTDATE,
            distributionStartDate: DISTRIBUTION_START_DATE,
            totalDistributionCount: TOTAL_DISTRIBUTION_COUNT,
            distributionInterval: DISTRIBUTION_INTERVAL,
            baseTokenURI: BASE_TOKEN_URI,
            requiredTier: 0
        });

        vm.prank(admin);
        RegisterProduct(target).registerProduct(exactArgs);

        Schema.Product memory product = Storage.ProductsState().products[PRODUCT_ID];
        assertEq(product.productId, PRODUCT_ID);
        assertEq(product.maturityDate, exactMaturity);
    }

    function test_registerProduct_revert_whenLastDistributionDateExceedsMaturityDate_monthEnd() public {
        // distributionStartDate=2025-02-28 (month-end, >= operationStartDate 2025-02-01)
        // interval=3, count=4
        // lastDistributionDate = 2025-02-28 + 3*3 months = 2025-11-28 → month-end adjusted → 2025-11-30
        // maturityDate = 2025-11-29 → lastDistributionDate(11/30) > maturityDate(11/29) → revert
        uint256 monthEndStart = DateTime.toTimestamp(2025, 2, 28, 0, 0, 0);
        uint256 earlyMaturity = DateTime.toTimestamp(2025, 11, 29, 0, 0, 0);

        Schema.RegisterProductArgs memory invalidArgs = Schema.RegisterProductArgs({
            productId: PRODUCT_ID,
            offeringAmount: OFFERING_AMOUNT,
            minInvestment: MIN_INVESTMENT,
            offeringEndDate: OFFERING_END_DATE,
            maturityDate: earlyMaturity,
            expectedYield: EXPECTED_YIELD,
            operationStartDate: OPERATION_STARTDATE,
            distributionStartDate: monthEndStart,
            totalDistributionCount: 4,
            distributionInterval: DISTRIBUTION_INTERVAL,
            baseTokenURI: BASE_TOKEN_URI,
            requiredTier: 0
        });

        vm.prank(admin);
        vm.expectRevert(IInvestmentErrors.InvalidMaturityDate.selector);
        RegisterProduct(target).registerProduct(invalidArgs);
    }

    receive() external payable {}
}
