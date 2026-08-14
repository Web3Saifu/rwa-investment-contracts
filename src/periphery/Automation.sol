// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "bundle/periphery/interfaces/IAutomation.sol";
import {IInvestment} from "bundle/investment/interfaces/IInvestment.sol";
import {Schema} from "bundle/investment/storage/Schema.sol";
import {DistributionDateLib} from "bundle/investment/utils/DistributionDateLib.sol";

import "@chainlink/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";


/**
 * @title Automation
 * @dev Chainlink Automation-compatible upkeep management contract
 *
 * Main Features:
 * - Maturity processing check for investment products (when maturityDate is reached)
 * - Profit distribution check (regular distribution based on distributionInterval)
 * - Integration with Chainlink Automation
 *
 * State Transition Logic:
 * 1. checkUpkeep: Scans blockchain state to detect required actions
 * 2. performUpkeep: Executes detected actions
 *
 * Security Requirements:
 * - performUpkeep execution restricted to Chainlink Forwarder only
 * - Investment product contract accessed via proxy
 */
contract Automation is IAutomation, AutomationCompatibleInterface {
    // investmentContract: Proxy address of the investment contract
    address private investmentContract;

    // forwarderAddress: Address of the chainLink forwarder
    address private forwarderAddress;

    constructor(address _investmentContract, address _forwarderAddress) {
        investmentContract = _investmentContract;
        forwarderAddress = _forwarderAddress;
    }

    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory performData) {
        // Retrieve active (non-matured) products from the InvestmentContract
        Schema.Product[] memory products = IInvestment(investmentContract).getActiveProducts();

        // Iterate through each product to check if any actions are needed
        for (uint256 i = 0; i < products.length; i++) {
            Schema.Product memory product = products[i];

            // 1. Skip products that have already matured or have insufficient balance
            if (product.isMaturity || product.isInsufficientBalance) {
                continue;
            }

            // 2. Conditions for maturity handling
            // Note: maturity may proceed while escrowed yield/principal remains (failed push transfers).
            if (product.distributedCount >= product.totalDistributionCount && block.timestamp >= product.maturityDate) {
                // Maturity handling is required
                upkeepNeeded = true;
                performData = abi.encode(ActionType.Maturity, product.productId);
                return (upkeepNeeded, performData);
            }

            // 3. Conditions for profit distribution
            //    If the total distribution count is not yet reached,
            //    Calculate distribution date using DistributionDateLib (month-based calculation)
            if (product.distributedCount < product.totalDistributionCount) {
                uint256 nextDistributionDate = DistributionDateLib.calculateNextDistributionDate(
                    product.distributionStartDate,
                    product.distributionInterval,
                    product.distributedCount,
                    product.isMonthEnd
                );

                if (block.timestamp >= nextDistributionDate) {
                    // Profit distribution is required
                    upkeepNeeded = true;
                    performData = abi.encode(ActionType.DistributeYield, product.productId);
                    return (upkeepNeeded, performData);
                }
            }
        }

        // If no actions are needed for any product, return false
        return (false, "");
    }

    /**
     * @notice performUpkeep
     *         Called by the forwarder when `upkeepNeeded = true` is returned from checkUpkeep.
     *         Decodes performData and executes the required action (maturity or profit distribution).
     * @param performData Data received from checkUpkeep (actionType, productId)
     */
    function performUpkeep(bytes calldata performData) external override {
        // Ensure the caller is an admin
        if (msg.sender != forwarderAddress) {
            revert NotForwarder(msg.sender);
        }

        // Decode to obtain the action type and productId
        (ActionType actionType, uint256 productId) = abi.decode(performData, (ActionType, uint256));

        if (actionType == ActionType.DistributeYield) {
            // Sequence diagram: For DistributeYield
            //  - First, getProduct(productId) retrieves the product details
            //  - Then call distributeYield(productId)
            IInvestment(investmentContract).distributeYield(productId);
        } else if (actionType == ActionType.Maturity) {
            // Sequence diagram: For Maturity
            //  - Call getProduct(productId) to retrieve the product details
            //  - Then call maturity(productId)
            IInvestment(investmentContract).maturity(productId);
        }
    }
}

// Testing
import "forge-std/Test.sol";
import {Storage} from "bundle/investment/storage/Storage.sol";
import {DistributionDateLib} from "bundle/investment/utils/DistributionDateLib.sol";
import {DateTime} from "lib/chainlink-evm/contracts/src/v0.8/vendor/DateTime.sol";

contract AutomationTest is Test, IAutomation {
    Automation automation;
    address investmentContract; // Address of InvestmentContract as a mock
    address owner;
    address chainlinkNode;
    address chainlinkAutomation;
    address forwarder;
    address nonForwarder;

    function setUp() public {
        // Create test addresses
        owner = makeAddr("owner");
        chainlinkNode = makeAddr("chainlinkNode");
        chainlinkAutomation = makeAddr("chainlinkAutomation");
        forwarder = makeAddr("forwarder");
        nonForwarder = makeAddr("nonForwarder");

        // Set InvestmentContract's address as a mock
        investmentContract = makeAddr("investmentContract");

        // Deploy the Automation contract
        vm.prank(owner);
        automation = new Automation(investmentContract, forwarder);

        // Update WhiteListsState to register
        Storage.WhiteListsState().admins.push(owner);

        // Setup data
        vm.warp(1733995552);
    }

    /// @notice Test checkUpkeep success case (Maturity action)
    function testCheckUpkeep_Success_Maturity() public {
        uint256 targetProductId = 2;

        // getActiveProducts returns only non-matured products
        Schema.Product[] memory products = new Schema.Product[](1);
        products[0] = makeBaseProduct();
        products[0].productId = targetProductId;
        products[0].offeringEndDate = block.timestamp - 10000;
        products[0].maturityDate = block.timestamp - 1;
        products[0].operationStartDate = block.timestamp - 10000;
        products[0].distributionStartDate = block.timestamp - 5000;
        products[0].totalDistributionCount = 5;
        products[0].distributedCount = 5;
        products[0].isMaturity = false;

        // Mock the getActiveProducts() call
        vm.mockCall(
            investmentContract, abi.encodeWithSelector(bytes4(keccak256("getActiveProducts()"))), abi.encode(products)
        );

        // Call checkUpkeep
        (bool upkeepNeeded, bytes memory performData) = automation.checkUpkeep("");

        // Confirm upkeepNeeded is true
        assertTrue(upkeepNeeded, "Upkeep should be needed");

        // Verify the content of performData
        (ActionType action, uint256 returnedProductId) = abi.decode(performData, (ActionType, uint256));
        assertEq(uint8(action), uint8(ActionType.Maturity), "Action should be Maturity");
        assertEq(returnedProductId, targetProductId, "Product ID mismatch");
    }

    /// @notice Test checkUpkeep when product is already matured (not in active list)
    function testCheckUpkeep_Success_AlreadyMaturity() public {
        // Already matured products are excluded from getActiveProducts, so empty array
        Schema.Product[] memory products = new Schema.Product[](0);

        // Mock the getActiveProducts() call
        vm.mockCall(
            investmentContract, abi.encodeWithSelector(bytes4(keccak256("getActiveProducts()"))), abi.encode(products)
        );

        // Call checkUpkeep
        (bool upkeepNeeded,) = automation.checkUpkeep("");

        // Confirm upkeepNeeded is false (no active products)
        assertFalse(upkeepNeeded, "Upkeep should not be needed");
    }

    /// @notice Test checkUpkeep success case (Distribute action)
    function testCheckUpkeep_Success_Distribute() public {
        uint256 productId = 2;

        // Set data for the investment product
        Schema.Product[] memory products = new Schema.Product[](1);
        products[0] = makeBaseProduct();
        products[0].productId = productId;
        products[0].offeringEndDate = block.timestamp - 15000;
        products[0].maturityDate = block.timestamp + 10000;
        products[0].operationStartDate = block.timestamp - 15000;
        products[0].distributionStartDate = block.timestamp - 1;
        products[0].totalDistributionCount = 5;
        products[0].distributionInterval = 1; // 1 month
        products[0].distributedCount = 0;
        products[0].isMaturity = false;
        products[0].isInsufficientBalance = false;
        products[0].isMonthEnd = false;

        // Mock the getActiveProducts() call
        vm.mockCall(
            investmentContract, abi.encodeWithSelector(bytes4(keccak256("getActiveProducts()"))), abi.encode(products)
        );

        // Call checkUpkeep
        (bool upkeepNeeded, bytes memory performData) = automation.checkUpkeep("");

        // Confirm upkeepNeeded is true
        assertTrue(upkeepNeeded, "Upkeep should be needed");

        // Verify the content of performData
        (ActionType action, uint256 returnedProductId) = abi.decode(performData, (ActionType, uint256));
        assertEq(uint8(action), uint8(ActionType.DistributeYield), "Action should be DistributeYield");
        assertEq(returnedProductId, productId, "Product ID mismatch");
    }

    /// @notice Test checkUpkeep success case (target product has insufficient balance)
    function testCheckUpkeep_Success_SkipIsInsufficientBalance() public {
        uint256 errorProductId = 1;
        uint256 targetProductId = 2;

        // Set data for the investment product
        Schema.Product[] memory products = new Schema.Product[](2);
        products[0] = makeBaseProduct();
        products[0].productId = errorProductId;
        products[0].offeringEndDate = block.timestamp - 15000;
        products[0].maturityDate = block.timestamp + 10000;
        products[0].operationStartDate = block.timestamp - 15000;
        products[0].distributionStartDate = block.timestamp - 1;
        products[0].totalDistributionCount = 5;
        products[0].distributionInterval = 1; // 1 month
        products[0].distributedCount = 0;
        products[0].isMaturity = false;
        products[0].isInsufficientBalance = true;
        products[0].isMonthEnd = false;
        products[1] = makeBaseProduct();
        products[1].productId = targetProductId;
        products[1].offeringEndDate = block.timestamp - 15000;
        products[1].maturityDate = block.timestamp + 10000;
        products[1].operationStartDate = block.timestamp - 15000;
        products[1].distributionStartDate = block.timestamp - 1;
        products[1].totalDistributionCount = 5;
        products[1].distributionInterval = 1; // 1 month
        products[1].distributedCount = 0;
        products[1].isMaturity = false;
        products[1].isInsufficientBalance = false;
        products[1].isMonthEnd = false;

        // Mock the getActiveProducts() call
        vm.mockCall(
            investmentContract, abi.encodeWithSelector(bytes4(keccak256("getActiveProducts()"))), abi.encode(products)
        );

        // Call checkUpkeep
        (bool upkeepNeeded, bytes memory performData) = automation.checkUpkeep("");

        // Confirm upkeepNeeded is true
        assertTrue(upkeepNeeded, "Upkeep should be needed");

        // Verify the content of performData
        (ActionType action, uint256 returnedProductId) = abi.decode(performData, (ActionType, uint256));
        assertEq(uint8(action), uint8(ActionType.DistributeYield), "Action should be DistributeYield");
        assertEq(returnedProductId, targetProductId, "Product ID mismatch");
    }

    /// @notice Test checkUpkeep success case (No projects needing upkeep — all matured, so active list is empty)
    function testCheckUpkeep_NoUpkeepNeeded() public {
        // getActiveProducts returns empty when all products are matured
        Schema.Product[] memory products = new Schema.Product[](0);

        // Mock the getActiveProducts() call
        vm.mockCall(
            investmentContract, abi.encodeWithSelector(bytes4(keccak256("getActiveProducts()"))), abi.encode(products)
        );

        // Call checkUpkeep
        (bool upkeepNeeded,) = automation.checkUpkeep("");

        // Confirm upkeepNeeded is false
        assertFalse(upkeepNeeded, "Upkeep should not be needed");
    }

    // Additional functions remain the same but follow the same translation pattern for comments.

    /// @notice Test performUpkeep success case (Maturity action)
    function testPerformUpkeep_Success_Maturity() public {
        uint256 productId = 1;

        // Create performData
        bytes memory performData = abi.encode(ActionType.Maturity, productId);

        // Set data for the investment product
        Schema.Product memory product = makeBaseProduct();
        product.productId = productId;
        product.offeringEndDate = block.timestamp - 1000;
        product.maturityDate = block.timestamp - 1;
        product.operationStartDate = block.timestamp - 10000;
        product.distributionStartDate = block.timestamp - 5000;
        product.totalDistributionCount = 5;
        product.distributionInterval = 1; // 1 month
        product.distributedCount = 5;
        product.isMaturity = false;
        product.isMonthEnd = false;

        // Mock getProduct(productId) call
        vm.mockCall(
            investmentContract,
            abi.encodeWithSelector(bytes4(keccak256("getProduct(uint256)")), productId),
            abi.encode(product)
        );

        // Mock maturity(productId, startTokenId) call
        vm.mockCall(
            investmentContract, abi.encodeWithSelector(bytes4(keccak256("maturity(uint256,uint256)")), productId), ""
        );

        // Call performUpkeep as the forwarder
        vm.prank(forwarder);
        automation.performUpkeep(performData);

        // Confirm the function completes without errors (additional assertions omitted)
    }

    /// @notice Test performUpkeep success case (DistributeYield action)
    function testPerformUpkeep_Success_DistributeYield() public {
        uint256 productId = 2;

        // Create performData
        bytes memory performData = abi.encode(ActionType.DistributeYield, productId);

        // Set data for the investment product
        Schema.Product memory product = makeBaseProduct();
        product.productId = productId;
        product.offeringEndDate = block.timestamp + 5000;
        product.maturityDate = block.timestamp + 10000;
        product.operationStartDate = block.timestamp - 3000;
        product.distributionStartDate = block.timestamp - 2000;
        product.totalDistributionCount = 5;
        product.distributionInterval = 1; // 1 month
        product.distributedCount = 0;
        product.isMonthEnd = false;

        // Mock getProduct(productId) call
        vm.mockCall(
            investmentContract,
            abi.encodeWithSelector(bytes4(keccak256("getProduct(uint256)")), productId),
            abi.encode(product)
        );

        // Mock distributeYield(productId, startTokenId) call
        vm.mockCall(
            investmentContract,
            abi.encodeWithSelector(bytes4(keccak256("distributeYield(uint256,uint256)")), productId),
            ""
        );

        // Call performUpkeep as the forwarder
        vm.prank(forwarder);
        automation.performUpkeep(performData);

        // Confirm the function completes without errors (additional assertions omitted)
    }

    /// @notice Test performUpkeep failure case (Invalid action)
    function testPerformUpkeep_Fail_InvalidAction() public {
        // Specify an invalid action type
        bytes memory performData = abi.encode(
            // ActionType(uint8(2)),
            uint8(2),
            uint256(1)
        );

        // Set data for the investment product
        Schema.Product memory product = makeBaseProduct();
        product.productId = 1;
        product.offeringEndDate = block.timestamp + 5000;
        product.maturityDate = block.timestamp + 10000;
        product.operationStartDate = block.timestamp - 3000;
        product.distributionStartDate = block.timestamp - 2000;
        product.distributionInterval = 1; // 1 month
        product.totalDistributionCount = 5;
        product.distributedCount = 0;
        product.isMonthEnd = false;

        // Mock getProduct(productId) call
        vm.mockCall(
            investmentContract,
            abi.encodeWithSelector(bytes4(keccak256("getProduct(uint256)")), uint256(1)),
            abi.encode(product)
        );

        // Call performUpkeep as the forwarder and expect an error
        vm.prank(forwarder);
        vm.expectRevert();
        automation.performUpkeep(performData);
    }

    /// @notice Test performUpkeep failure case (Non-forwarder caller)
    function testPerformUpkeep_Fail_NotForwarder() public {
        uint256 productId = 1;

        // Create performData
        bytes memory performData = abi.encode(ActionType.Maturity, productId);

        // Call performUpkeep as a non-forwarder and expect an error
        vm.prank(nonForwarder);
        vm.expectRevert(abi.encodeWithSelector(IAutomation.NotForwarder.selector, nonForwarder));
        automation.performUpkeep(performData);
    }

    // Fuzz testing area

    /// @notice Fuzz test for checkUpkeep
    function testFuzz_CheckUpkeep(uint256 productId, uint8 actionType) public {
        // Ensure productId is within a valid range
        vm.assume(productId > 0 && productId < 1000);
        // Ensure actionType is within the defined enum range
        vm.assume(actionType <= uint8(ActionType.Maturity));

        // Set data for the investment product
        Schema.Product[] memory products = new Schema.Product[](1);
        products[0] = makeBaseProduct();
        products[0].productId = productId;
        products[0].offeringEndDate =
            actionType == uint8(ActionType.Maturity) ? block.timestamp - 1000 : block.timestamp + 20000;
        products[0].maturityDate =
            actionType == uint8(ActionType.Maturity) ? block.timestamp - 1 : block.timestamp + 10000;
        products[0].expectedYield = actionType == uint8(ActionType.DistributeYield) ? 500 : 0;
        products[0].operationStartDate =
            actionType == uint8(ActionType.Maturity) ? block.timestamp - 5000 : block.timestamp - 2000;
        products[0].distributionStartDate = block.timestamp - 2000;
        products[0].totalDistributionCount = 5;
        products[0].distributionInterval = 1; // 1 month
        products[0].distributedCount = actionType == uint8(ActionType.DistributeYield) ? 0 : 5;
        products[0].isMonthEnd = false;

        // Mock the getActiveProducts() call to return the products array
        vm.mockCall(
            investmentContract, abi.encodeWithSelector(bytes4(keccak256("getActiveProducts()"))), abi.encode(products)
        );

        // Call the checkUpkeep function
        (bool upkeepNeeded, bytes memory performData) = automation.checkUpkeep("");

        // Verify if upkeep is needed based on the actionType
        if (actionType == uint8(ActionType.Maturity) || actionType == uint8(ActionType.DistributeYield)) {
            // Assert that upkeep is needed
            assertTrue(upkeepNeeded, "Upkeep should be needed");

            // Decode performData
            (ActionType action, uint256 returnedProductId) = abi.decode(performData, (ActionType, uint256));

            // Assert action type and productId
            assertEq(uint8(action), actionType, "Action type mismatch");
            assertEq(returnedProductId, productId, "Product ID mismatch");
        } else {
            // Assert upkeep is not needed
            assertFalse(upkeepNeeded, "Upkeep should not be needed");
        }
    }

    /// @notice Fuzz test for performUpkeep
    function testFuzz_PerformUpkeep(uint8 actionType, uint256 productId) public {
        // Ensure productId is within a valid range
        vm.assume(productId > 0 && productId < 1000);
        // Ensure actionType is within the defined enum range
        vm.assume(actionType <= uint8(ActionType.Maturity));

        // Create performData
        bytes memory performData = abi.encode(ActionType(actionType), productId);

        // Set data for the investment product
        Schema.Product memory product = makeBaseProduct();
        product.productId = productId;
        product.offeringEndDate = block.timestamp + 15000;
        product.maturityDate = actionType == uint8(ActionType.Maturity) ? block.timestamp - 1 : block.timestamp + 10000;
        product.expectedYield = 0;
        product.operationStartDate = block.timestamp - 3000;
        product.distributionStartDate = block.timestamp - 2000;
        product.totalDistributionCount = 5;
        product.distributionInterval = 1; // 1 month
        product.distributedCount = actionType == uint8(ActionType.DistributeYield) ? 0 : 5;
        product.isMaturity = actionType == uint8(ActionType.Maturity);
        product.isMonthEnd = false;

        // Mock getProduct(productId) call
        vm.mockCall(
            investmentContract,
            abi.encodeWithSelector(bytes4(keccak256("getProduct(uint256)")), productId),
            abi.encode(product)
        );

        // Depending on actionType, mock distributeYield or maturity functions
        if (actionType == uint8(ActionType.DistributeYield)) {
            vm.mockCall(
                investmentContract,
                abi.encodeWithSelector(bytes4(keccak256("distributeYield(uint256,uint256)")), productId),
                ""
            );
        } else if (actionType == uint8(ActionType.Maturity)) {
            vm.mockCall(
                investmentContract,
                abi.encodeWithSelector(bytes4(keccak256("maturity(uint256,uint256)")), productId),
                ""
            );
        } else {
            // Expect a revert for invalid action types
            vm.expectRevert("Invalid action type");
        }

        // Call performUpkeep as the forwarder
        vm.prank(forwarder);
        automation.performUpkeep(performData);
    }

    /// @notice Test checkUpkeep with month-end logic
    function testCheckUpkeep_Success_DistributeWithMonthEnd() public {
        uint256 productId = 1;

        // Set distributionStartDate to month end (2025-01-31 00:00:00 UTC)
        uint256 monthEndDate = DateTime.toTimestamp(2025, 1, 31, 0, 0, 0);
        vm.warp(monthEndDate + 1 days); // Move to next day

        Schema.Product[] memory products = new Schema.Product[](1);
        products[0] = makeBaseProduct();
        products[0].productId = productId;
        products[0].offeringEndDate = monthEndDate - 30 days;
        products[0].maturityDate = monthEndDate + 365 days;
        products[0].operationStartDate = monthEndDate - 10 days;
        products[0].distributionStartDate = monthEndDate;
        products[0].totalDistributionCount = 3;
        products[0].distributionInterval = 1; // 1 month
        products[0].distributedCount = 0;
        products[0].isMaturity = false;
        products[0].isInsufficientBalance = false;
        products[0].isMonthEnd = true; // Month end flag set

        // Mock the getActiveProducts() call
        vm.mockCall(
            investmentContract, abi.encodeWithSelector(bytes4(keccak256("getActiveProducts()"))), abi.encode(products)
        );

        // Call checkUpkeep
        (bool upkeepNeeded, bytes memory performData) = automation.checkUpkeep("");

        // Confirm upkeepNeeded is true (distribution date should be calculated as month end)
        assertTrue(upkeepNeeded, "Upkeep should be needed");

        // Verify the content of performData
        (ActionType action, uint256 returnedProductId) = abi.decode(performData, (ActionType, uint256));
        assertEq(uint8(action), uint8(ActionType.DistributeYield), "Action should be DistributeYield");
        assertEq(returnedProductId, productId, "Product ID mismatch");
    }

    /// @notice Test checkUpkeep with month-based interval calculation
    function testCheckUpkeep_Success_MonthBasedInterval() public {
        uint256 productId = 1;

        // Set distributionStartDate (2025-01-15 00:00:00 UTC)
        uint256 startDate = DateTime.toTimestamp(2025, 1, 15, 0, 0, 0);
        // Calculate next distribution date: startDate + 2 months = 2025-03-15
        uint256 nextDistDate = DistributionDateLib.calculateNextDistributionDate(startDate, 2, 1, false);
        vm.warp(nextDistDate + 1 days); // Move to after next distribution date

        Schema.Product[] memory products = new Schema.Product[](1);
        products[0] = makeBaseProduct();
        products[0].productId = productId;
        products[0].offeringEndDate = startDate - 30 days;
        products[0].maturityDate = startDate + 365 days;
        products[0].operationStartDate = startDate - 10 days;
        products[0].distributionStartDate = startDate;
        products[0].totalDistributionCount = 3;
        products[0].distributionInterval = 2; // 2 months
        products[0].distributedCount = 1; // Already distributed once
        products[0].isMaturity = false;
        products[0].isInsufficientBalance = false;
        products[0].isMonthEnd = false;

        // Mock the getActiveProducts() call
        vm.mockCall(
            investmentContract, abi.encodeWithSelector(bytes4(keccak256("getActiveProducts()"))), abi.encode(products)
        );

        // Call checkUpkeep
        (bool upkeepNeeded, bytes memory performData) = automation.checkUpkeep("");

        // Confirm upkeepNeeded is true
        assertTrue(upkeepNeeded, "Upkeep should be needed");

        // Verify the content of performData
        (ActionType action, uint256 returnedProductId) = abi.decode(performData, (ActionType, uint256));
        assertEq(uint8(action), uint8(ActionType.DistributeYield), "Action should be DistributeYield");
        assertEq(returnedProductId, productId, "Product ID mismatch");
    }

    // Helper function to create base product data
    function makeBaseProduct() private view returns (Schema.Product memory) {
        Schema.Product memory product = Schema.Product({
            productId: 0, // The ID of the product
            nftContract: address(0), // Initialize with a default or specific address
            offeringAmount: 0, // Initialize with default or desired value
            minInvestment: 0, // Initialize with default or desired value
            offeringEndDate: block.timestamp - 10000, // New field: Future offering end date
            raisedAmount: 0, // Initialize with default or desired value
            productPool: 0, // New field: Initialize with default or desired value
            maturityDate: block.timestamp - 1, // Past maturity date
            expectedYield: 0, // New field: Initialize with default or desired value
            operationStartDate: block.timestamp - 10000, // New field: Operation start date
            distributionStartDate: block.timestamp - 5000, // Start date of distribution
            totalDistributionCount: 0, // Total number of distributions
            distributionInterval: 1, // Interval between distributions (months)
            distributedCount: 0, // All distributions completed
            distributedYieldPerCount: 0, // New field: Initialize with default or desired value
            distributedTokenId: 0, // Initialize with default or desired value
            totalReturnedAmount: 0, // Initialize with default or desired value
            maturedTokenId: 0, // Initialize with default or desired value
            requiredTier: 0,
            isMaturity: false, // Indicates if the product has matured
            isInsufficientBalance: false,
            isMonthEnd: false
        });

        return product;
    }
}
