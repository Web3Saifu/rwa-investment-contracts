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

contract InvestmentScenario6Test is MCTest {
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
    uint256 constant OFFERING_END_DATE = 1737763200; // 2025-01-25 00:00:00 UTC
    uint256 constant MATURITY_DATE = 1767225600; // 2026-01-01 00:00:00 UTC
    uint256 constant EXPECTED_YIELD = 500; // 5%
    uint256 constant OPERATION_STARTDATE = 1738368000; // 2025-02-01 00:00:00 UTC
    uint256 constant DISTRIBUTION_START_DATE = 1748736000; // 2025-06-01 00:00:00 UTC
    uint256 constant TOTAL_DISTRIBUTION_COUNT = 3;
    uint256 constant DISTRIBUTION_INTERVAL = 3; // 3 months (approximately 90 days)

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
        uint256 simulatedUpperBound,
        uint256 productId,
        uint256 tokenId1,
        uint256 tokenId2,
        uint256 periodIndex
    ) internal returns (uint256 actualTotalYield, uint256 distributed1, uint256 distributed2) {
        uint256 b1 = usdt.balanceOf(investor1);
        uint256 b2 = usdt.balanceOf(investor2);

        uint256 sim1 = investment.simulateIndividualPeriodYield(productId, tokenId1)[periodIndex];
        uint256 sim2 = investment.simulateIndividualPeriodYield(productId, tokenId2)[periodIndex];

        vm.prank(forwarder);
        Automation(address(automation)).performUpkeep(performData);

        distributed1 = usdt.balanceOf(investor1) - b1;
        distributed2 = usdt.balanceOf(investor2) - b2;
        actualTotalYield = distributed1 + distributed2;

        // 投資家ごと：シミュレーション額と分配USDTの突合（同一ロジックの個人シェア）
        assertEq(distributed1, sim1, "per-investor actual vs simulateIndividual (investor1)");
        assertEq(distributed2, sim2, "per-investor actual vs simulateIndividual (investor2)");

        // 下限：少なくとも理論分配額以上（丸めで下回るならここは >= を緩める）
        assertGe(actualTotalYield, expectedPeriodYield, "actual < expectedPeriodYield");

        // 上限：シミュレーション（許容誤差込み）以下
        assertLe(actualTotalYield, simulatedUpperBound, "actual > simulatedUpperBound");
    }

    function test_scenarioX_SimulationAndDistributionMatch() public {
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
        vm.warp(1735689600); // 2025-01-01 00:00:00 UTC

        // ----------------------------------------------------------
        //  No1. ProductID1: 商品登録
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
        //  No2. ProductID1: 出資（USDT）募集額未達（例：募集額の1/2）投資家2人
        // ----------------------------------------------------------
        uint256 investAmount1;
        uint256 investAmount2;
        uint256 tokenIdInvestor1;
        uint256 tokenIdInvestor2;
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
            tokenIdInvestor1 = 1;
            tokenIdInvestor2 = 2;
        }

        // ----------------------------------------------------------
        //  No3. ProductID1: 利益分配前シミュレーション（総額・初回・tokenIdごと）
        // ----------------------------------------------------------
        Schema.Product memory productForNo3 = investment.getProduct(PRODUCT_ID);
        uint256 simulateTotalYield = investment.simulateTotalYield(PRODUCT_ID);
        uint256 simulateFirstPeriodYield = investment.simulatePeriodYield(PRODUCT_ID)[0];
        uint256[] memory simulateIndividual1 = investment.simulateIndividualPeriodYield(PRODUCT_ID, tokenIdInvestor1);
        uint256[] memory simulateIndividual2 = investment.simulateIndividualPeriodYield(PRODUCT_ID, tokenIdInvestor2);

        // Assert simulation values are greater than 0
        assertGt(simulateTotalYield, 0, "No3: simulateTotalYield is not greater than 0");
        assertGt(simulateFirstPeriodYield, 0, "No3: simulateFirstPeriodYield is not greater than 0");

        assertEq(
            simulateIndividual1.length,
            registerProductArgs.totalDistributionCount,
            "No3: simulateIndividual1 length mismatch"
        );
        assertEq(
            simulateIndividual2.length,
            registerProductArgs.totalDistributionCount,
            "No3: simulateIndividual2 length mismatch"
        );
        assertGt(simulateIndividual1[0], 0, "No3: simulateIndividual1[0] is not greater than 0");
        assertGt(simulateIndividual2[0], 0, "No3: simulateIndividual2[0] is not greater than 0");
        {
            uint256 sumInd1;
            uint256 sumInd2;
            for (uint256 i = 0; i < simulateIndividual1.length; i++) {
                sumInd1 += simulateIndividual1[i];
                sumInd2 += simulateIndividual2[i];
            }
            assertEq(
                investment.simulateIndividualTotalYield(PRODUCT_ID, tokenIdInvestor1),
                sumInd1,
                "No3: simulateIndividualTotalYield token1"
            );
            assertEq(
                investment.simulateIndividualTotalYield(PRODUCT_ID, tokenIdInvestor2),
                sumInd2,
                "No3: simulateIndividualTotalYield token2"
            );
        }

        // Deposit funds for distribution (required for distribution to work)
        // Total of repayment amount, profit distribution amount, and tolerance at distribution
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
            "No3: productPool after deposit is not equal"
        );

        // ----------------------------------------------------------
        //  No4. ProductID1の初回利益分配日まで時間を進める
        // ----------------------------------------------------------
        vm.warp(registerProductArgs.distributionStartDate);

        // ----------------------------------------------------------
        //  No5. 利益分配、満期処理判定（checkUpkeep）
        // ----------------------------------------------------------
        (bool upkeepNeededNo5, bytes memory performDataNo5) = Automation(address(automation)).checkUpkeep(abi.encode(0));
        (IAutomation.ActionType actionTypeNo5, uint256 productIdNo5) =
            abi.decode(performDataNo5, (IAutomation.ActionType, uint256));

        assertTrue(upkeepNeededNo5, "No5: upkeepNeeded is not True");
        assertEq(uint8(actionTypeNo5), uint8(IAutomation.ActionType.DistributeYield), "No5: actionType is not equal");
        assertEq(productIdNo5, PRODUCT_ID, "No5: productId is not equal");

        // ----------------------------------------------------------
        //  No6. 利益分配実行（performUpkeep）1回目
        //  No7. 1回目：実分配額と想定分配額の突合
        // ----------------------------------------------------------
        uint256 periodYield1 = _calcFirstPeriodYield(PRODUCT_ID);
        uint256 simulateFirstPeriodYieldBefore1 = investment.simulatePeriodYield(PRODUCT_ID)[0];
        (uint256 actualTotalYield1, uint256 dist1Inv1, uint256 dist1Inv2) = _performDistributeAndGetActualTotal(
            performDataNo5,
            investor1,
            investor2,
            periodYield1,
            simulateFirstPeriodYieldBefore1,
            PRODUCT_ID,
            tokenIdInvestor1,
            tokenIdInvestor2,
            0
        );

        // Assert Product
        Schema.Product memory afterProductForNo6 = investment.getProduct(PRODUCT_ID);
        assertEq(afterProductForNo6.distributedCount, 1, "No6: distributedCount is not equal");
        // Verify no distribution to other products (only one product exists)
        assertEq(afterProductForNo6.distributedCount, 1, "No6: distributedCount for other product check");

        // ----------------------------------------------------------
        //  No8. 2回目の分配前シミュレーション
        // ----------------------------------------------------------
        uint256 simulateSecondPeriodYield = investment.simulatePeriodYield(PRODUCT_ID)[1];
        assertGt(simulateSecondPeriodYield, 0, "No8: simulateSecondPeriodYield is not greater than 0");

        // ----------------------------------------------------------
        //  No9. ProductID1の2回目利益分配日まで時間を進める
        // ----------------------------------------------------------
        _warpToNextDistributionDate(PRODUCT_ID, 1); // distributedCount = 1 for 2nd distribution

        // ----------------------------------------------------------
        //  No10. 利益分配判定（checkUpkeep）
        // ----------------------------------------------------------
        (bool upkeepNeededNo10, bytes memory performDataNo10) =
            Automation(address(automation)).checkUpkeep(abi.encode(0));
        (IAutomation.ActionType actionTypeNo10, uint256 productIdNo10) =
            abi.decode(performDataNo10, (IAutomation.ActionType, uint256));

        assertTrue(upkeepNeededNo10, "No10: upkeepNeeded is not True");
        assertEq(uint8(actionTypeNo10), uint8(IAutomation.ActionType.DistributeYield), "No10: actionType is not equal");
        assertEq(productIdNo10, PRODUCT_ID, "No10: productId is not equal");

        // ----------------------------------------------------------
        //  No11. 利益分配実行（performUpkeep）2回目
        //  No12. 2回目：実分配額と想定分配額の突合
        // ----------------------------------------------------------
        uint256 periodYield2 = _calcNthPeriodYield(PRODUCT_ID, 1); // distributedCount = 1 for 2nd distribution
        uint256 simulateSecondPeriodYieldBefore2 = investment.simulatePeriodYield(PRODUCT_ID)[1];
        (uint256 actualTotalYield2, uint256 dist2Inv1, uint256 dist2Inv2) = _performDistributeAndGetActualTotal(
            performDataNo10,
            investor1,
            investor2,
            periodYield2,
            simulateSecondPeriodYieldBefore2,
            PRODUCT_ID,
            tokenIdInvestor1,
            tokenIdInvestor2,
            1
        );

        // Assert Product
        Schema.Product memory afterProductForNo11 = investment.getProduct(PRODUCT_ID);
        assertEq(afterProductForNo11.distributedCount, 2, "No11: distributedCount is not equal");
        // Verify no distribution to other products
        assertEq(afterProductForNo11.distributedCount, 2, "No11: distributedCount for other product check");

        // ----------------------------------------------------------
        //  No13. 3回目の分配前シミュレーション
        // ----------------------------------------------------------
        uint256 simulateThirdPeriodYield = investment.simulatePeriodYield(PRODUCT_ID)[2];
        assertGt(simulateThirdPeriodYield, 0, "No13: simulateThirdPeriodYield is not greater than 0");

        // ----------------------------------------------------------
        //  No14. ProductID1の3回目利益分配日まで時間を進める
        // ----------------------------------------------------------
        _warpToNextDistributionDate(PRODUCT_ID, 2); // distributedCount = 2 for 3rd distribution

        // ----------------------------------------------------------
        //  No15. 利益分配判定（checkUpkeep）
        // ----------------------------------------------------------
        (bool upkeepNeededNo15, bytes memory performDataNo15) =
            Automation(address(automation)).checkUpkeep(abi.encode(0));
        (IAutomation.ActionType actionTypeNo15, uint256 productIdNo15) =
            abi.decode(performDataNo15, (IAutomation.ActionType, uint256));

        assertTrue(upkeepNeededNo15, "No15: upkeepNeeded is not True");
        assertEq(uint8(actionTypeNo15), uint8(IAutomation.ActionType.DistributeYield), "No15: actionType is not equal");
        assertEq(productIdNo15, PRODUCT_ID, "No15: productId is not equal");

        // ----------------------------------------------------------
        //  No16. 利益分配実行（performUpkeep）3回目
        //  No17. 3回目：実分配額と想定分配額の突合
        // ----------------------------------------------------------
        uint256 periodYield3 = _calcNthPeriodYield(PRODUCT_ID, 2); // distributedCount = 2 for 3rd distribution
        uint256 simulateThirdPeriodYieldBefore3 = investment.simulatePeriodYield(PRODUCT_ID)[2];
        (uint256 actualTotalYield3, uint256 dist3Inv1, uint256 dist3Inv2) = _performDistributeAndGetActualTotal(
            performDataNo15,
            investor1,
            investor2,
            periodYield3,
            simulateThirdPeriodYieldBefore3,
            PRODUCT_ID,
            tokenIdInvestor1,
            tokenIdInvestor2,
            2
        );

        // Assert Product
        Schema.Product memory afterProductForNo16 = investment.getProduct(PRODUCT_ID);
        assertEq(afterProductForNo16.distributedCount, 3, "No16: distributedCount is not equal");
        // Verify no distribution to other products
        assertEq(afterProductForNo16.distributedCount, 3, "No16: distributedCount for other product check");

        // ----------------------------------------------------------
        //  No18. 最終：実分配合計と総分配シミュレーションの突合、投資家ごと累計と個人シミュレーション合計の突合
        // ----------------------------------------------------------
        uint256 totalActualYield = actualTotalYield1 + actualTotalYield2 + actualTotalYield3;
        uint256 simulateTotalYieldFinal = investment.simulateTotalYield(PRODUCT_ID);

        // Allow tolerance: simulateTotalYield includes tolerance
        assertGe(
            totalActualYield,
            periodYield1 + periodYield2 + periodYield3,
            "No18: totalActualYield is less than sum of period yields"
        );
        assertLe(totalActualYield, simulateTotalYieldFinal, "No18: totalActualYield exceeds total simulation");

        uint256 cumActualInv1 = dist1Inv1 + dist2Inv1 + dist3Inv1;
        uint256 cumActualInv2 = dist1Inv2 + dist2Inv2 + dist3Inv2;
        assertEq(
            cumActualInv1,
            investment.simulateIndividualTotalYield(PRODUCT_ID, tokenIdInvestor1),
            "No18: investor1 cumulative vs simulateIndividualTotalYield"
        );
        assertEq(
            cumActualInv2,
            investment.simulateIndividualTotalYield(PRODUCT_ID, tokenIdInvestor2),
            "No18: investor2 cumulative vs simulateIndividualTotalYield"
        );

        // ----------------------------------------------------------
        //  No19. 冪等性：再度 performUpkeep（分配）を呼ぶ
        // ----------------------------------------------------------
        vm.prank(forwarder);
        vm.expectRevert(IInvestmentErrors.DistributionCompleted.selector);
        Automation(address(automation)).performUpkeep(performDataNo15);

        // ----------------------------------------------------------
        //  No20. システム監視（情報取得）を行う
        // ----------------------------------------------------------
        Schema.Product memory productForNo20 = investment.getProduct(PRODUCT_ID);

        assertEq(productForNo20.productId, registerProductArgs.productId, "No20: productId is not equal");
        assertEq(
            IInvestmentNFT(productForNo20.nftContract).productId(),
            registerProductArgs.productId,
            "No20: nft productId is not equal"
        );
        assertEq(productForNo20.offeringAmount, registerProductArgs.offeringAmount, "No20: offeringAmount is not equal");
        assertEq(productForNo20.minInvestment, registerProductArgs.minInvestment, "No20: minInvestment is not equal");
        assertEq(
            productForNo20.offeringEndDate, registerProductArgs.offeringEndDate, "No20: offeringEndDate is not equal"
        );
        assertEq(productForNo20.raisedAmount, investAmount1 + investAmount2, "No20: raisedAmount is not equal");
        // Note: periodTolerance is the tolerance amount, productPool should be >= 0 and <= periodTolerance
        assertGe(productForNo20.productPool, 0, "No20: productPool should be >= 0");
        assertEq(productForNo20.maturityDate, registerProductArgs.maturityDate, "No20: maturityDate is not equal");
        assertEq(productForNo20.expectedYield, registerProductArgs.expectedYield, "No20: expectedYield is not equal");
        assertEq(
            productForNo20.operationStartDate,
            registerProductArgs.operationStartDate,
            "No20: operationStartDate is not equal"
        );
        assertEq(
            productForNo20.distributionStartDate,
            registerProductArgs.distributionStartDate,
            "No20: distributionStartDate is not equal"
        );
        assertEq(
            productForNo20.totalDistributionCount,
            registerProductArgs.totalDistributionCount,
            "No20: totalDistributionCount is not equal"
        );
        assertEq(
            productForNo20.distributionInterval,
            registerProductArgs.distributionInterval,
            "No20: distributionInterval is not equal"
        );
        assertEq(productForNo20.distributedCount, 3, "No20: distributedCount is not equal");
        assertEq(productForNo20.distributedYieldPerCount, 0, "No20: distributedYieldPerCount is not equal");
        assertEq(productForNo20.distributedTokenId, 0, "No20: distributedTokenId is not equal");
        assertEq(productForNo20.totalReturnedAmount, 0, "No20: totalReturnedAmount is not equal");
        assertEq(productForNo20.maturedTokenId, 0, "No20: maturedTokenId is not equal");
        assertFalse(productForNo20.isMaturity, "No20: isMaturity is not false");
        assertFalse(productForNo20.isInsufficientBalance, "No20: isInsufficientBalance is not false");
    }

    receive() external payable {}
}
