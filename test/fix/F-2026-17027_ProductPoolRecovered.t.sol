// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {MCTest, MCDevKit, VmSafe} from "@mc-devkit/Flattened.sol";

import {Schema} from "bundle/investment/storage/Schema.sol";
import {IInvestment} from "bundle/investment/interfaces/IInvestment.sol";
import {IInvestmentEvents} from "bundle/investment/interfaces/IInvestmentEvents.sol";
import {InvestmentDeployer} from "script/deploy/InvestmentDeployer.sol";

import {MockInvestmentERC20} from "test/investment/mocks/MockInvestmentERC20.sol";

/**
 * @title F-2026-17027 ProductPoolRecovered event verification
 * @notice ProductPoolRecovered is emitted only on deposit when clearing isInsufficientBalance.
 */
contract F2026_17027_ProductPoolRecoveredTest is MCTest {
    IInvestment public investment;
    MockInvestmentERC20 public usdt;

    address safe;
    address admin1;
    address[] admins;
    address investor1;

    uint256 constant PRODUCT_1 = 1;
    uint256 constant OFFERING_AMOUNT = 1_000_000_000_000;
    uint256 constant MIN_INVESTMENT = 250_000_000;
    uint256 constant OFFERING_END_DATE = 1737763200;
    uint256 constant MATURITY_DATE = 1767225600;
    uint256 constant EXPECTED_YIELD = 500;
    uint256 constant OPERATION_START_DATE = 1738368000;

    bytes32 constant PRODUCT_POOL_RECOVERED_TOPIC = keccak256("ProductPoolRecovered(uint256)");

    function setUp() public {
        safe = makeAddr("safe");
        admin1 = makeAddr("admin1");
        investor1 = makeAddr("investor1");
        admins.push(admin1);

        usdt = new MockInvestmentERC20();
        vm.prank(safe);
        investment = IInvestment(InvestmentDeployer.deployInvestment(mc, admins, admins, address(usdt), safe));

        vm.warp(1735689600);
    }

    function _registerAndStallProduct() internal returns (Schema.Product memory) {
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

        Schema.Product memory product = investment.getProduct(PRODUCT_1);
        assertTrue(product.isInsufficientBalance, "flag set after shortfall");
        return product;
    }

    function _assertNoProductPoolRecoveredLog() internal {
        VmSafe.Log[] memory logs = vm.getRecordedLogs();
        for (uint256 i = 0; i < logs.length; i++) {
            if (logs[i].topics.length > 0 && logs[i].topics[0] == PRODUCT_POOL_RECOVERED_TOPIC) {
                revert("ProductPoolRecovered should not be emitted");
            }
        }
    }

    function test_depositEmitsProductPoolRecovered_whenFlagWasSet() public {
        Schema.Product memory stalled = _registerAndStallProduct();

        uint256 depositAmount = stalled.raisedAmount * 2;
        usdt.mint(admin1, depositAmount);

        vm.startPrank(admin1);
        usdt.approve(address(investment), depositAmount);

        vm.expectEmit(true, false, false, true);
        emit IInvestmentEvents.ProductPoolRecovered(PRODUCT_1);

        investment.deposit(PRODUCT_1, depositAmount);
        vm.stopPrank();

        assertFalse(investment.getProduct(PRODUCT_1).isInsufficientBalance);
    }

    function test_depositDoesNotEmitProductPoolRecovered_whenFlagWasFalse() public {
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

        uint256 depositAmount = MIN_INVESTMENT;
        usdt.mint(admin1, depositAmount);

        vm.recordLogs();
        vm.startPrank(admin1);
        usdt.approve(address(investment), depositAmount);
        investment.deposit(PRODUCT_1, depositAmount);
        vm.stopPrank();

        _assertNoProductPoolRecoveredLog();
    }

    function test_distributeYieldDoesNotEmitProductPoolRecovered_afterDepositRecovery() public {
        Schema.Product memory stalled = _registerAndStallProduct();

        uint256 depositAmount = stalled.raisedAmount * 2;
        usdt.mint(admin1, depositAmount);
        vm.startPrank(admin1);
        usdt.approve(address(investment), depositAmount);
        investment.deposit(PRODUCT_1, depositAmount);
        vm.stopPrank();

        vm.recordLogs();
        vm.prank(admin1);
        investment.distributeYield(PRODUCT_1);

        _assertNoProductPoolRecoveredLog();
    }

    receive() external payable {}
}
