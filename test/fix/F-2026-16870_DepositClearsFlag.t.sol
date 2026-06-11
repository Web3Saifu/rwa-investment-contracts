// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {MCTest, MCDevKit} from "@mc-devkit/Flattened.sol";

import {Schema} from "bundle/investment/storage/Schema.sol";
import {IInvestment} from "bundle/investment/interfaces/IInvestment.sol";
import {IInvestmentEvents} from "bundle/investment/interfaces/IInvestmentEvents.sol";
import {InvestmentDeployer} from "script/deploy/InvestmentDeployer.sol";

import {IAutomation} from "bundle/periphery/interfaces/IAutomation.sol";
import {Automation} from "bundle/periphery/Automation.sol";

import {MockInvestmentERC20} from "test/investment/mocks/MockInvestmentERC20.sol";

/**
 * @title F-2026-16870 PoC Verification (post-fix)
 * @notice Verifies that deposit() clears isInsufficientBalance so Automation resumes.
 *         Based on the audit PoC (PoC_InsufficientBalanceFlagStale) with assertions
 *         flipped to confirm the fix.
 */
contract F2026_16870_DepositClearsFlagTest is MCTest {
    IInvestment public investment;
    MockInvestmentERC20 public usdt;
    Automation public automation;

    address safe;
    address admin1;
    address[] admins;
    address forwarder;
    address investor1;

    uint256 constant PRODUCT_1 = 1;
    uint256 constant OFFERING_AMOUNT = 1_000_000_000_000;
    uint256 constant MIN_INVESTMENT = 250_000_000;
    uint256 constant OFFERING_END_DATE = 1737763200;
    uint256 constant MATURITY_DATE = 1767225600;
    uint256 constant EXPECTED_YIELD = 500;
    uint256 constant OPERATION_START_DATE = 1738368000;

    function setUp() public {
        safe = makeAddr("safe");
        admin1 = makeAddr("admin1");
        forwarder = makeAddr("forwarder");
        investor1 = makeAddr("investor1");
        admins.push(admin1);

        usdt = new MockInvestmentERC20();
        vm.prank(safe);
        investment = IInvestment(InvestmentDeployer.deployInvestment(mc, admins, admins, address(usdt), safe));
        automation = new Automation(address(investment), forwarder);

        vm.prank(safe);
        investment.addAdmin(address(automation));

        vm.warp(1735689600);
    }

    /// @notice After deposit, isInsufficientBalance must be false (audit PoC assertion flipped)
    function test_depositClearsInsufficientBalanceFlag() public {
        vm.prank(admin1);
        investment.registerProduct(
            Schema.RegisterProductArgs({
                productId: PRODUCT_1,
                offeringAmount: OFFERING_AMOUNT,
                minInvestment: MIN_INVESTMENT,
                offeringEndDate: OFFERING_END_DATE,
                maturityDate: MATURITY_DATE,
                expectedYield: EXPECTED_YIELD,
                operationStartDate: OPERATION_START_DATE,
                distributionStartDate: MATURITY_DATE,
                baseTokenURI: "https://example.com/1/",
                totalDistributionCount: 1,
                distributionInterval: 0,
                requiredTier: 0
            })
        );

        vm.prank(admin1);
        investment.mintNFT(PRODUCT_1, 4, investor1);

        Schema.Product memory p1 = investment.getProduct(PRODUCT_1);
        assertGt(p1.raisedAmount, 0);
        assertEq(p1.productPool, 0, "pool empty after fiat mint");

        vm.warp(MATURITY_DATE);

        vm.prank(admin1);
        investment.distributeYield(PRODUCT_1);

        p1 = investment.getProduct(PRODUCT_1);
        assertTrue(p1.isInsufficientBalance, "flag set after shortfall");
        assertEq(p1.distributedCount, 0, "distribution did not advance");

        uint256 bigDeposit = p1.raisedAmount * 2;
        usdt.mint(admin1, bigDeposit);
        vm.startPrank(admin1);
        usdt.approve(address(investment), bigDeposit);
        investment.deposit(PRODUCT_1, bigDeposit);
        vm.stopPrank();

        p1 = investment.getProduct(PRODUCT_1);
        assertGt(p1.productPool, 0, "pool is now funded");
        assertFalse(p1.isInsufficientBalance, "FIX: flag cleared by deposit");
    }

    /// @notice After deposit clears the flag, checkUpkeep returns true and Automation resumes
    function test_depositClearsFlag_automationResumes() public {
        vm.prank(admin1);
        investment.registerProduct(
            Schema.RegisterProductArgs({
                productId: PRODUCT_1,
                offeringAmount: OFFERING_AMOUNT,
                minInvestment: MIN_INVESTMENT,
                offeringEndDate: OFFERING_END_DATE,
                maturityDate: MATURITY_DATE,
                expectedYield: EXPECTED_YIELD,
                operationStartDate: OPERATION_START_DATE,
                distributionStartDate: MATURITY_DATE,
                baseTokenURI: "https://example.com/1/",
                totalDistributionCount: 1,
                distributionInterval: 0,
                requiredTier: 0
            })
        );

        vm.prank(admin1);
        investment.mintNFT(PRODUCT_1, 4, investor1);

        vm.warp(MATURITY_DATE);

        vm.prank(admin1);
        investment.distributeYield(PRODUCT_1);

        Schema.Product memory p1 = investment.getProduct(PRODUCT_1);
        assertTrue(p1.isInsufficientBalance, "flag set after shortfall");

        (bool neededBefore,) = automation.checkUpkeep(abi.encode(0));
        assertFalse(neededBefore, "checkUpkeep false while flag is set");

        uint256 bigDeposit = p1.raisedAmount * 2;
        usdt.mint(admin1, bigDeposit);
        vm.startPrank(admin1);
        usdt.approve(address(investment), bigDeposit);
        investment.deposit(PRODUCT_1, bigDeposit);
        vm.stopPrank();

        (bool neededAfter,) = automation.checkUpkeep(abi.encode(0));
        assertTrue(neededAfter, "FIX: checkUpkeep true after deposit clears flag");
    }

    /// @notice If deposit amount is still insufficient, next distributeYield re-sets the flag (idempotency)
    function test_depositClearsFlag_butResetOnNextShortfall() public {
        vm.prank(admin1);
        investment.registerProduct(
            Schema.RegisterProductArgs({
                productId: PRODUCT_1,
                offeringAmount: OFFERING_AMOUNT,
                minInvestment: MIN_INVESTMENT,
                offeringEndDate: OFFERING_END_DATE,
                maturityDate: MATURITY_DATE,
                expectedYield: EXPECTED_YIELD,
                operationStartDate: OPERATION_START_DATE,
                distributionStartDate: MATURITY_DATE,
                baseTokenURI: "https://example.com/1/",
                totalDistributionCount: 1,
                distributionInterval: 0,
                requiredTier: 0
            })
        );

        vm.prank(admin1);
        investment.mintNFT(PRODUCT_1, 4, investor1);

        vm.warp(MATURITY_DATE);

        vm.prank(admin1);
        investment.distributeYield(PRODUCT_1);

        Schema.Product memory p1 = investment.getProduct(PRODUCT_1);
        assertTrue(p1.isInsufficientBalance, "flag set after shortfall");

        uint256 tinyDeposit = 1;
        usdt.mint(admin1, tinyDeposit);
        vm.startPrank(admin1);
        usdt.approve(address(investment), tinyDeposit);
        investment.deposit(PRODUCT_1, tinyDeposit);
        vm.stopPrank();

        p1 = investment.getProduct(PRODUCT_1);
        assertFalse(p1.isInsufficientBalance, "flag cleared by deposit (even tiny amount)");

        vm.prank(admin1);
        investment.distributeYield(PRODUCT_1);

        p1 = investment.getProduct(PRODUCT_1);
        assertTrue(p1.isInsufficientBalance, "flag re-set: pool still insufficient for distribution");
        assertEq(p1.distributedCount, 0, "distribution still did not advance");
    }

    receive() external payable {}
}
