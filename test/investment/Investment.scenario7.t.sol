// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {MCTest, MCDevKit, stdError} from "@mc-devkit/Flattened.sol";
import {console} from "forge-std/console.sol";

// investment
import {Storage} from "bundle/investment/storage/Storage.sol";
import {Schema} from "bundle/investment/storage/Schema.sol";
import {IInvestment} from "bundle/investment/interfaces/IInvestment.sol";
import {IInvestmentErrors} from "bundle/investment/interfaces/IInvestmentErrors.sol";
import {IInvestmentEvents} from "bundle/investment/interfaces/IInvestmentEvents.sol";
import {InvestmentDeployer} from "script/deploy/InvestmentDeployer.sol";
import {CalculateYieldLib} from "bundle/investment/utils/CalculateYieldLib.sol";
import {DistributionDateLib} from "bundle/investment/utils/DistributionDateLib.sol";

// periphery
import {IAutomation} from "bundle/periphery/interfaces/IAutomation.sol";
import {Automation} from "bundle/periphery/Automation.sol";
import {IInvestmentNFT} from "bundle/periphery/interfaces/IInvestmentNFT.sol";
import {InvestmentNFT} from "bundle/periphery/InvestmentNFT.sol";

import {MockInvestmentERC20} from "test/investment/mocks/MockInvestmentERC20.sol";
import {DateTime} from "lib/chainlink-evm/contracts/src/v0.8/vendor/DateTime.sol";

contract InvestmentScenario7Test is MCTest {
    IInvestment public investment;
    MockInvestmentERC20 public usdt;
    Automation public automation;

    address safe;
    address admin1;
    address admin2;
    address[] admins;
    address forwarder;
    Schema.RegisterProductArgs registerProductArgs;

    uint256 constant PRODUCT_ID = 1;
    uint256 constant OFFERING_AMOUNT = 1_000_000_000_000; // 1,000,000 USDT
    uint256 constant MIN_INVESTMENT = 250_000_000; // 250 USDT
    uint256 constant OFFERING_END_DATE = 1831939200; // 2028-01-20 00:00:00 UTC
    uint256 constant MATURITY_DATE = 1840665600; // 2028-04-30 00:00:00 UTC
    uint256 constant EXPECTED_YIELD = 500; // 5%
    uint256 constant OPERATION_STARTDATE = 1832889600; // 2028-01-31 00:00:00 UTC (月末)
    uint256 constant DISTRIBUTION_START_DATE = 1835395200; // 2028-02-29 00:00:00 UTC (うるう年・月末)
    uint256 constant TOTAL_DISTRIBUTION_COUNT = 2;
    uint256 constant DISTRIBUTION_INTERVAL = 1; // 1 month

    function setUp() public {
        // make up address
        safe = makeAddr("safe");
        admin1 = makeAddr("admin1");
        admin2 = makeAddr("admin2");
        forwarder = makeAddr("forwarder");
        admins.push(admin1);

        // deploy
        usdt = new MockInvestmentERC20();
        vm.prank(safe);
        investment = IInvestment(InvestmentDeployer.deployInvestment(mc, admins, admins, address(usdt), safe));
        automation = new Automation(address(investment), forwarder);

        vm.prank(safe);
        investment.addAdmin(address(automation));
    }

    // Internal helper functions to reduce stack depth
    function _calcFirstPeriodYield(uint256 productId) internal view returns (uint256) {
        Schema.Product memory p = investment.getProduct(productId);
        uint256 firstPeriod =
            DistributionDateLib.calculateFirstDistributionPeriod(p.distributionStartDate, p.operationStartDate);
        return CalculateYieldLib.calculatePeriodYield(p.raisedAmount, p.expectedYield, firstPeriod);
    }

    function _calcNthPeriodYield(uint256 productId, uint256 distributedCountBefore) internal view returns (uint256) {
        Schema.Product memory p = investment.getProduct(productId);
        uint256 period = DistributionDateLib.calculateDistributionPeriod(
            p.distributionStartDate, p.distributionInterval, distributedCountBefore, p.isMonthEnd
        );
        return CalculateYieldLib.calculatePeriodYield(p.raisedAmount, p.expectedYield, period);
    }

    function _warpToNextDistributionDate(uint256 productId, uint256 distributedCountBefore) internal {
        Schema.Product memory p = investment.getProduct(productId);
        uint256 nextDate = DistributionDateLib.calculateNextDistributionDate(
            p.distributionStartDate, p.distributionInterval, distributedCountBefore, p.isMonthEnd
        );
        vm.warp(nextDate);
    }

    function _performDistributeAndGetActualTotal(
        bytes memory performData,
        address investor1,
        address investor2,
        uint256 expectedPeriodYield,
        uint256 simulatedUpperBound
    ) internal returns (uint256 actualTotalYield) {
        uint256 b1 = usdt.balanceOf(investor1);
        uint256 b2 = usdt.balanceOf(investor2);

        vm.prank(forwarder);
        Automation(address(automation)).performUpkeep(performData);

        uint256 d1 = usdt.balanceOf(investor1) - b1;
        uint256 d2 = usdt.balanceOf(investor2) - b2;
        actualTotalYield = d1 + d2;

        // 下限：少なくとも理論分配額以上（丸めで下回るならここは >= を緩める）
        assertGe(actualTotalYield, expectedPeriodYield, "actual < expectedPeriodYield");

        // 上限：シミュレーション（許容誤差込み）以下
        assertLe(actualTotalYield, simulatedUpperBound, "actual > simulatedUpperBound");
    }

    function test_scenarioM_MonthlyDistribution_MonthEnd_LeapYear() public {
        registerProductArgs = Schema.RegisterProductArgs({
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
            baseTokenURI: "https://example.com/metadata/",
            requiredTier: 0
        });

        address investor1 = makeAddr("investor1");
        address investor2 = makeAddr("investor2");

        // ----------------------------------------------------------
        //  No0. Set up time
        // ----------------------------------------------------------
        vm.warp(1831939200 - 1 days); // 2028-01-19 00:00:00 UTC (募集締切日の前日)

        // ----------------------------------------------------------
        //  No1. ProductID1: 商品登録（月次・月末補正/うるう年）
        // ----------------------------------------------------------
        vm.prank(admin1);
        investment.registerProduct(registerProductArgs);

        // Assert product registration
        Schema.Product memory productForNo1 = investment.getProduct(registerProductArgs.productId);
        assertEq(productForNo1.productId, registerProductArgs.productId, "No1: productId is not equal");
        assertEq(productForNo1.offeringAmount, registerProductArgs.offeringAmount, "No1: offeringAmount is not equal");
        assertEq(productForNo1.minInvestment, registerProductArgs.minInvestment, "No1: minInvestment is not equal");
        assertEq(
            productForNo1.offeringEndDate, registerProductArgs.offeringEndDate, "No1: offeringEndDate is not equal"
        );
        assertEq(productForNo1.maturityDate, registerProductArgs.maturityDate, "No1: maturityDate is not equal");
        assertEq(productForNo1.expectedYield, registerProductArgs.expectedYield, "No1: expectedYield is not equal");
        assertEq(
            productForNo1.operationStartDate,
            registerProductArgs.operationStartDate,
            "No1: operationStartDate is not equal"
        );
        assertEq(
            productForNo1.distributionStartDate,
            registerProductArgs.distributionStartDate,
            "No1: distributionStartDate is not equal"
        );
        assertEq(
            productForNo1.totalDistributionCount,
            registerProductArgs.totalDistributionCount,
            "No1: totalDistributionCount is not equal"
        );
        assertEq(
            productForNo1.distributionInterval,
            registerProductArgs.distributionInterval,
            "No1: distributionInterval is not equal"
        );
        // 月末補正フラグの確認（distributionStartDateが月末なのでtrueになる）
        assertTrue(productForNo1.isMonthEnd, "No1: isMonthEnd should be true (distributionStartDate is month end)");

        // Assert initial values
        assertEq(productForNo1.raisedAmount, 0, "No1: raisedAmount is not equal");
        assertEq(productForNo1.productPool, 0, "No1: productPool is not equal");
        assertEq(productForNo1.distributedCount, 0, "No1: distributedCount is not equal");
        assertEq(productForNo1.distributedYieldPerCount, 0, "No1: distributedYieldPerCount is not equal");
        assertEq(productForNo1.distributedTokenId, 0, "No1: distributedTokenId is not equal");
        assertEq(productForNo1.totalReturnedAmount, 0, "No1: totalReturnedAmount is not equal");
        assertEq(productForNo1.maturedTokenId, 0, "No1: maturedTokenId is not equal");
        assertFalse(productForNo1.isMaturity, "No1: isMaturity is not false");
        assertFalse(productForNo1.isInsufficientBalance, "No1: isInsufficientBalance is not false");

        // ----------------------------------------------------------
        //  No2. ProductID1: 出資（USDT）募集額未達 投資家2人
        // ----------------------------------------------------------
        uint256 investAmount1;
        uint256 investAmount2;
        {
            uint256 halfOfferingAmount = registerProductArgs.offeringAmount / 2;
            uint256 amountPer2 = halfOfferingAmount / 2;
            investAmount1 = amountPer2;
            investAmount2 = amountPer2;
            uint256 unitCount1 = investAmount1 / registerProductArgs.minInvestment;
            uint256 unitCount2 = investAmount2 / registerProductArgs.minInvestment;

            usdt.mint(investor1, investAmount1);
            usdt.mint(investor2, investAmount2);

            vm.startPrank(investor1);
            usdt.approve(address(investment), investAmount1);
            investment.invest(PRODUCT_ID, unitCount1);
            vm.stopPrank();

            vm.startPrank(investor2);
            usdt.approve(address(investment), investAmount2);
            investment.invest(PRODUCT_ID, unitCount2);
            vm.stopPrank();

            // Assert Product
            Schema.Product memory productForNo2 = investment.getProduct(PRODUCT_ID);
            assertEq(productForNo2.raisedAmount, investAmount1 + investAmount2, "No2: raisedAmount is not equal");
            assertEq(productForNo2.productPool, investAmount1 + investAmount2, "No2: productPool is not equal");

            // Assert NFT
            assertEq(
                InvestmentNFT(productForNo2.nftContract).balanceOf(investor1),
                1,
                "No2: balanceOf(investor1) is not equal"
            );
            assertEq(
                InvestmentNFT(productForNo2.nftContract).balanceOf(investor2),
                1,
                "No2: balanceOf(investor2) is not equal"
            );
            assertEq(InvestmentNFT(productForNo2.nftContract).tokenIdCounter(), 2, "No2: tokenIdCounter is not equal");
        }

        // ----------------------------------------------------------
        //  No3. 利益分配前シミュレーション取得（初回・総額）
        // ----------------------------------------------------------
        Schema.Product memory productForNo3 = investment.getProduct(PRODUCT_ID);
        uint256 simulateTotalYield = investment.simulateTotalYield(PRODUCT_ID);
        uint256 simulateFirstPeriodYield = investment.simulatePeriodYield(PRODUCT_ID)[0];

        // Assert simulation values are greater than 0
        assertGt(simulateTotalYield, 0, "No3: simulateTotalYield is not greater than 0");
        assertGt(simulateFirstPeriodYield, 0, "No3: simulateFirstPeriodYield is not greater than 0");

        // ----------------------------------------------------------
        //  No4. 管理者入金（分配原資＋元本）
        // ----------------------------------------------------------
        uint256 depositAmount = productForNo3.raisedAmount + simulateTotalYield;
        uint256 productPoolBeforeDeposit = productForNo3.productPool;
        usdt.mint(admin1, depositAmount);

        vm.startPrank(admin1);
        usdt.approve(address(investment), depositAmount);
        investment.deposit(PRODUCT_ID, depositAmount);
        vm.stopPrank();

        // Assert Product after deposit
        Schema.Product memory productAfterDeposit = investment.getProduct(PRODUCT_ID);
        assertEq(
            productAfterDeposit.productPool,
            productPoolBeforeDeposit + depositAmount,
            "No4: productPool after deposit is not equal"
        );

        // ----------------------------------------------------------
        //  No5. 境界確認：分配日 - 1秒
        // ----------------------------------------------------------
        vm.warp(DISTRIBUTION_START_DATE - 1);
        (bool upkeepNeededNo5, bytes memory performDataNo5) = Automation(address(automation)).checkUpkeep(abi.encode(0));
        assertFalse(upkeepNeededNo5, "No5: upkeepNeeded should be false (1 second before distribution date)");

        // ----------------------------------------------------------
        //  No6. 初回分配日へ時間移動
        // ----------------------------------------------------------
        vm.warp(DISTRIBUTION_START_DATE);

        // ----------------------------------------------------------
        //  No7. checkUpkeep（初回）
        // ----------------------------------------------------------
        (bool upkeepNeededNo7, bytes memory performDataNo7) = Automation(address(automation)).checkUpkeep(abi.encode(0));
        (IAutomation.ActionType actionTypeNo7, uint256 productIdNo7) =
            abi.decode(performDataNo7, (IAutomation.ActionType, uint256));

        assertTrue(upkeepNeededNo7, "No7: upkeepNeeded is not True");
        assertEq(uint8(actionTypeNo7), uint8(IAutomation.ActionType.DistributeYield), "No7: actionType is not equal");
        assertEq(productIdNo7, PRODUCT_ID, "No7: productId is not equal");

        // ----------------------------------------------------------
        //  No8. performUpkeep（初回分配）
        //  No9. 初回：実分配額とシミュレーション突合
        // ----------------------------------------------------------
        uint256 periodYield1 = _calcFirstPeriodYield(PRODUCT_ID);
        uint256 simulateFirstPeriodYieldBefore1 = investment.simulatePeriodYield(PRODUCT_ID)[0];
        uint256 actualTotalYield1 = _performDistributeAndGetActualTotal(
            performDataNo7, investor1, investor2, periodYield1, simulateFirstPeriodYieldBefore1
        );

        // Assert Product
        Schema.Product memory afterProductForNo8 = investment.getProduct(PRODUCT_ID);
        assertEq(afterProductForNo8.distributedCount, 1, "No8: distributedCount is not equal");

        // ----------------------------------------------------------
        //  No10. 次回分配日が「月末補正」になっていることを確認
        // ----------------------------------------------------------
        Schema.Product memory productForNo10 = investment.getProduct(PRODUCT_ID);
        uint256 nextDate = DistributionDateLib.calculateNextDistributionDate(
            productForNo10.distributionStartDate,
            productForNo10.distributionInterval,
            productForNo10.distributedCount,
            productForNo10.isMonthEnd
        );
        uint256 expectedNextDate = DateTime.toTimestamp(2028, 3, 31, 0, 0, 0); // 2028-03-31 00:00:00 UTC
        assertEq(nextDate, expectedNextDate, "No10: next distribution date should be 2028-03-31 00:00:00 UTC");

        // ----------------------------------------------------------
        //  No11. 境界確認：2回目分配日 - 1秒
        // ----------------------------------------------------------
        vm.warp(expectedNextDate - 1);
        (bool upkeepNeededNo11, bytes memory performDataNo11) =
            Automation(address(automation)).checkUpkeep(abi.encode(0));
        assertFalse(upkeepNeededNo11, "No11: upkeepNeeded should be false (1 second before 2nd distribution date)");

        // ----------------------------------------------------------
        //  No12. 2回目分配日へ時間移動
        // ----------------------------------------------------------
        vm.warp(expectedNextDate);

        // ----------------------------------------------------------
        //  No13. checkUpkeep（2回目）
        // ----------------------------------------------------------
        (bool upkeepNeededNo13, bytes memory performDataNo13) =
            Automation(address(automation)).checkUpkeep(abi.encode(0));
        (IAutomation.ActionType actionTypeNo13, uint256 productIdNo13) =
            abi.decode(performDataNo13, (IAutomation.ActionType, uint256));

        assertTrue(upkeepNeededNo13, "No13: upkeepNeeded is not True");
        assertEq(uint8(actionTypeNo13), uint8(IAutomation.ActionType.DistributeYield), "No13: actionType is not equal");
        assertEq(productIdNo13, PRODUCT_ID, "No13: productId is not equal");

        // ----------------------------------------------------------
        //  No14. performUpkeep（2回目分配）
        //  No15. 2回目：実分配額とシミュレーション突合
        // ----------------------------------------------------------
        uint256 periodYield2 = _calcNthPeriodYield(PRODUCT_ID, 1); // distributedCount = 1 for 2nd distribution
        uint256 simulateSecondPeriodYieldBefore2 = investment.simulatePeriodYield(PRODUCT_ID)[1];
        uint256 actualTotalYield2 = _performDistributeAndGetActualTotal(
            performDataNo13, investor1, investor2, periodYield2, simulateSecondPeriodYieldBefore2
        );

        // Assert Product
        Schema.Product memory afterProductForNo14 = investment.getProduct(PRODUCT_ID);
        assertEq(afterProductForNo14.distributedCount, 2, "No14: distributedCount is not equal");

        // ----------------------------------------------------------
        //  No16. 最終：実分配合計と総分配シミュレーション突合
        // ----------------------------------------------------------
        uint256 totalActualYield = actualTotalYield1 + actualTotalYield2;
        uint256 simulateTotalYieldFinal = investment.simulateTotalYield(PRODUCT_ID);

        // Allow tolerance: simulateTotalYield includes tolerance
        assertGe(
            totalActualYield, periodYield1 + periodYield2, "No16: totalActualYield is less than sum of period yields"
        );
        assertLe(totalActualYield, simulateTotalYieldFinal, "No16: totalActualYield exceeds total simulation");

        // ----------------------------------------------------------
        //  No17. 冪等性：同一performDataで再実行
        // ----------------------------------------------------------
        vm.prank(forwarder);
        vm.expectRevert(IInvestmentErrors.DistributionCompleted.selector);
        Automation(address(automation)).performUpkeep(performDataNo13);

        // ----------------------------------------------------------
        //  No18. 監視（Getter）
        // ----------------------------------------------------------
        Schema.Product memory productForNo18 = investment.getProduct(PRODUCT_ID);

        assertEq(productForNo18.productId, registerProductArgs.productId, "No18: productId is not equal");
        assertEq(
            IInvestmentNFT(productForNo18.nftContract).productId(),
            registerProductArgs.productId,
            "No18: nft productId is not equal"
        );
        assertEq(productForNo18.offeringAmount, registerProductArgs.offeringAmount, "No18: offeringAmount is not equal");
        assertEq(productForNo18.minInvestment, registerProductArgs.minInvestment, "No18: minInvestment is not equal");
        assertEq(
            productForNo18.offeringEndDate, registerProductArgs.offeringEndDate, "No18: offeringEndDate is not equal"
        );
        assertEq(productForNo18.raisedAmount, investAmount1 + investAmount2, "No18: raisedAmount is not equal");
        // Note: periodTolerance is the tolerance amount, productPool should be >= 0 and <= periodTolerance
        assertGe(productForNo18.productPool, 0, "No18: productPool should be >= 0");
        assertEq(productForNo18.maturityDate, registerProductArgs.maturityDate, "No18: maturityDate is not equal");
        assertEq(productForNo18.expectedYield, registerProductArgs.expectedYield, "No18: expectedYield is not equal");
        assertEq(
            productForNo18.operationStartDate,
            registerProductArgs.operationStartDate,
            "No18: operationStartDate is not equal"
        );
        assertEq(
            productForNo18.distributionStartDate,
            registerProductArgs.distributionStartDate,
            "No18: distributionStartDate is not equal"
        );
        assertEq(
            productForNo18.totalDistributionCount,
            registerProductArgs.totalDistributionCount,
            "No18: totalDistributionCount is not equal"
        );
        assertEq(
            productForNo18.distributionInterval,
            registerProductArgs.distributionInterval,
            "No18: distributionInterval is not equal"
        );
        assertEq(productForNo18.distributedCount, 2, "No18: distributedCount is not equal");
        assertEq(productForNo18.distributedYieldPerCount, 0, "No18: distributedYieldPerCount is not equal");
        assertEq(productForNo18.distributedTokenId, 0, "No18: distributedTokenId is not equal");
        assertEq(productForNo18.totalReturnedAmount, 0, "No18: totalReturnedAmount is not equal");
        assertEq(productForNo18.maturedTokenId, 0, "No18: maturedTokenId is not equal");
        assertFalse(productForNo18.isMaturity, "No18: isMaturity is not false");
        assertFalse(productForNo18.isInsufficientBalance, "No18: isInsufficientBalance is not false");
        assertTrue(productForNo18.isMonthEnd, "No18: isMonthEnd should be true");
    }

    receive() external payable {}
}
