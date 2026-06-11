// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {MCTest, MCDevKit} from "@mc-devkit/Flattened.sol";

import {Schema} from "bundle/investment/storage/Schema.sol";
import {IInvestment} from "bundle/investment/interfaces/IInvestment.sol";
import {IInvestmentEvents} from "bundle/investment/interfaces/IInvestmentEvents.sol";
import {InvestmentDeployer} from "script/deploy/InvestmentDeployer.sol";

import {IAutomation} from "bundle/periphery/interfaces/IAutomation.sol";
import {Automation} from "bundle/periphery/Automation.sol";
import {InvestmentNFT} from "bundle/periphery/InvestmentNFT.sol";

import {MockInvestmentERC20} from "test/investment/mocks/MockInvestmentERC20.sol";

/**
 * @title F-2026-16869 EmptyNFTBatchDoS regression tests
 * @notice Verifies that zero-raised products no longer cause Automation infinite loops or maturity deadlocks
 */
contract F202616869EmptyNFTBatchDoSTest is MCTest {
    IInvestment public investment;
    MockInvestmentERC20 public usdt;
    Automation public automation;

    address safe;
    address admin;
    address[] admins;
    address forwarder;
    address investor1;

    uint256 constant PRODUCT_1 = 1;
    uint256 constant PRODUCT_2 = 2;
    uint256 constant OFFERING_AMOUNT = 1_000_000_000_000;
    uint256 constant MIN_INVESTMENT = 250_000_000;
    uint256 constant OFFERING_END_DATE = 1737763200;
    uint256 constant MATURITY_DATE = 1767225600;
    uint256 constant EXPECTED_YIELD = 500;
    uint256 constant OPERATION_START_DATE = 1738368000;

    function setUp() public {
        safe = makeAddr("safe");
        admin = makeAddr("admin");
        forwarder = makeAddr("forwarder");
        investor1 = makeAddr("investor1");
        admins.push(admin);

        usdt = new MockInvestmentERC20();
        vm.prank(safe);
        investment = IInvestment(InvestmentDeployer.deployInvestment(mc, admins, admins, address(usdt), safe));
        automation = new Automation(address(investment), forwarder);

        vm.prank(safe);
        investment.addAdmin(address(automation));

        vm.warp(1735689600);
    }

    function test_distributeYield_zeroRaisedAmount_incrementsCount() public {
        vm.prank(admin);
        investment.registerProduct(
            Schema.RegisterProductArgs({
                productId: PRODUCT_1,
                offeringAmount: OFFERING_AMOUNT,
                minInvestment: MIN_INVESTMENT,
                offeringEndDate: OFFERING_END_DATE,
                maturityDate: MATURITY_DATE,
                expectedYield: EXPECTED_YIELD,
                operationStartDate: OPERATION_START_DATE,
                distributionStartDate: OPERATION_START_DATE,
                baseTokenURI: "",
                totalDistributionCount: 3,
                distributionInterval: 3,
                requiredTier: 0
            })
        );

        Schema.Product memory p = investment.getProduct(PRODUCT_1);
        assertEq(p.raisedAmount, 0);
        assertEq(p.distributedCount, 0);
        assertEq(InvestmentNFT(p.nftContract).tokenIdCounter(), 0);

        // Warp past all distribution dates
        vm.warp(MATURITY_DATE);

        vm.expectEmit(true, false, false, true);
        emit IInvestmentEvents.YieldDistributed(PRODUCT_1, 1, 0, 0, 0);
        vm.prank(admin);
        investment.distributeYield(PRODUCT_1);

        p = investment.getProduct(PRODUCT_1);
        assertEq(p.distributedCount, 1);

        vm.expectEmit(true, false, false, true);
        emit IInvestmentEvents.YieldDistributed(PRODUCT_1, 2, 0, 0, 0);
        vm.prank(admin);
        investment.distributeYield(PRODUCT_1);

        vm.expectEmit(true, false, false, true);
        emit IInvestmentEvents.YieldDistributed(PRODUCT_1, 3, 0, 0, 0);
        vm.prank(admin);
        investment.distributeYield(PRODUCT_1);

        p = investment.getProduct(PRODUCT_1);
        assertEq(p.distributedCount, 3);
    }

    function test_maturity_zeroRaisedAmount_setsIsMaturity() public {
        vm.prank(admin);
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
                baseTokenURI: "",
                totalDistributionCount: 1,
                distributionInterval: 0,
                requiredTier: 0
            })
        );

        vm.warp(MATURITY_DATE);

        vm.prank(admin);
        investment.distributeYield(PRODUCT_1);

        Schema.Product memory p = investment.getProduct(PRODUCT_1);
        assertEq(p.distributedCount, 1);
        assertFalse(p.isMaturity);

        vm.expectEmit(true, false, false, true);
        emit IInvestmentEvents.ProductMatured(PRODUCT_1, 0, 0, 0);
        vm.prank(admin);
        investment.maturity(PRODUCT_1);

        p = investment.getProduct(PRODUCT_1);
        assertTrue(p.isMaturity);
        assertEq(p.totalReturnedAmount, 0);
    }

    function test_automation_skipsZeroRaisedProduct() public {
        vm.prank(admin);
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
                baseTokenURI: "",
                totalDistributionCount: 1,
                distributionInterval: 0,
                requiredTier: 0
            })
        );

        vm.prank(admin);
        investment.registerProduct(
            Schema.RegisterProductArgs({
                productId: PRODUCT_2,
                offeringAmount: OFFERING_AMOUNT,
                minInvestment: MIN_INVESTMENT,
                offeringEndDate: OFFERING_END_DATE,
                maturityDate: MATURITY_DATE,
                expectedYield: EXPECTED_YIELD,
                operationStartDate: OPERATION_START_DATE,
                distributionStartDate: MATURITY_DATE,
                baseTokenURI: "",
                totalDistributionCount: 1,
                distributionInterval: 0,
                requiredTier: 0
            })
        );

        vm.prank(admin);
        investment.mintNFT(PRODUCT_2, 4, investor1);

        Schema.Product memory p2 = investment.getProduct(PRODUCT_2);
        uint256 depositAmount = p2.raisedAmount * 2;
        usdt.mint(admin, depositAmount);
        vm.startPrank(admin);
        usdt.approve(address(investment), depositAmount);
        investment.deposit(PRODUCT_2, depositAmount);
        vm.stopPrank();

        vm.warp(MATURITY_DATE);

        // 1st checkUpkeep: returns product 1 (distributeYield needed)
        (bool needed1, bytes memory data1) = automation.checkUpkeep(abi.encode(0));
        assertTrue(needed1);
        (, uint256 id1) = abi.decode(data1, (IAutomation.ActionType, uint256));
        assertEq(id1, PRODUCT_1);

        vm.prank(forwarder);
        automation.performUpkeep(data1);

        // After fix: product 1's distributedCount is now 1 (== totalDistributionCount)
        Schema.Product memory p1After = investment.getProduct(PRODUCT_1);
        assertEq(p1After.distributedCount, 1);

        // 2nd checkUpkeep: product 1 now needs maturity, which comes before product 2's distribution
        (bool needed2, bytes memory data2) = automation.checkUpkeep(abi.encode(0));
        assertTrue(needed2);
        (IAutomation.ActionType action2, uint256 id2) = abi.decode(data2, (IAutomation.ActionType, uint256));
        assertEq(id2, PRODUCT_1);
        assertEq(uint256(action2), uint256(IAutomation.ActionType.Maturity));

        vm.prank(forwarder);
        automation.performUpkeep(data2);

        p1After = investment.getProduct(PRODUCT_1);
        assertTrue(p1After.isMaturity);

        // 3rd checkUpkeep: product 1 is fully done, now product 2 is reached
        (bool needed3, bytes memory data3) = automation.checkUpkeep(abi.encode(0));
        assertTrue(needed3);
        (, uint256 id3) = abi.decode(data3, (IAutomation.ActionType, uint256));
        assertEq(id3, PRODUCT_2, "product 2 is now reachable");
    }

    receive() external payable {}
}
