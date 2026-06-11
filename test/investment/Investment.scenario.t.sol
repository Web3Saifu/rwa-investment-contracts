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

// periphery
import {IAutomation} from "bundle/periphery/interfaces/IAutomation.sol";
import {Automation} from "bundle/periphery/Automation.sol";
import {IInvestmentNFT} from "bundle/periphery/interfaces/IInvestmentNFT.sol";
import {InvestmentNFT} from "bundle/periphery/InvestmentNFT.sol";

import {MockInvestmentERC20} from "test/investment/mocks/MockInvestmentERC20.sol";

contract InvestmentScenarioTest is MCTest {
    IInvestment public investment;
    MockInvestmentERC20 public usdt;
    Automation public automation;

    address safe;
    address admin1;
    address admin2;
    address admin3;
    address admin4;
    address nonAdmin;
    address[] admins;
    address forwarder;
    Schema.RegisterProductArgs registerProductArgs;

    uint256 constant PRODUCT_ID = 1;
    uint256 constant OFFERING_AMOUNT = 1_000_000_000_000; // 1_000_000USD(1USD = 150JPY: 150_000_000JPY)
    uint256 constant MIN_INVESTMENT = 250_000_000; // 250USD(1USD = 150JPY: 37_500JPY)
    uint256 constant OFFERING_END_DATE = 1737763200; // 2025-01-25 00:00:00 UTC
    uint256 constant MATURITY_DATE = 1767225600; // 2026-01-01 00:00:00 UTC
    uint256 constant EXPECTED_YIELD = 500; // 5%
    uint256 constant OPERATION_STARTDATE = 1738368000; // 2025-02-01 00:00:00 UTC
    uint256 constant TOTAL_DISTRIBUTION_COUNT = 1;
    uint256 constant DISTRIBUTION_INTERVAL = 0;

    function setUp() public {
        // make up address
        safe = makeAddr("safe");
        admin1 = makeAddr("admin1");
        admin2 = makeAddr("admin2");
        admin3 = makeAddr("admin3");
        admin4 = makeAddr("admin4");
        nonAdmin = makeAddr("nonAdmin");
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

    // To avoid stack too deep
    struct InvestorArgs {
        address investor1;
        address investor2;
        address investor3;
        address investor4;
    }

    struct InvestAmountArgs {
        uint256 investAmount1;
        uint256 investAmount2;
        uint256 investAmount3;
        uint256 investAmount4;
    }

    struct UnitCountArgs {
        uint256 unitCount1;
        uint256 unitCount2;
        uint256 unitCount3;
        uint256 unitCount4;
    }

    struct InvestmentBalanceArgs {
        uint256 investmentBalance;
        uint256 beforeInvestmentBalance;
    }

    struct InvestorBalanceArgs {
        uint256 investor1Balance;
        uint256 investor2Balance;
        uint256 investor3Balance;
        uint256 investor4Balance;
    }

    struct InvestorYieldArgs {
        uint256 investor1Yield;
        uint256 investor2Yield;
        uint256 investor3Yield;
        uint256 investor4Yield;
    }

    function test_scenario1_SingleDistribution() public {
        registerProductArgs = Schema.RegisterProductArgs({
            productId: PRODUCT_ID,
            offeringAmount: OFFERING_AMOUNT,
            minInvestment: MIN_INVESTMENT,
            offeringEndDate: OFFERING_END_DATE,
            maturityDate: MATURITY_DATE,
            expectedYield: EXPECTED_YIELD,
            operationStartDate: OPERATION_STARTDATE,
            distributionStartDate: MATURITY_DATE, // Same as maturity date
            baseTokenURI: "https://example.com/metadata/",
            totalDistributionCount: TOTAL_DISTRIBUTION_COUNT,
            distributionInterval: DISTRIBUTION_INTERVAL,
            requiredTier: 0
        });

        InvestorArgs memory investorArgs = InvestorArgs({
            investor1: makeAddr("investor1"),
            investor2: makeAddr("investor2"),
            investor3: makeAddr("investor3"),
            investor4: makeAddr("investor4")
        });

        InvestAmountArgs memory investAmountArgs;
        UnitCountArgs memory unitCountArgs;
        InvestmentBalanceArgs memory investmentBalanceArgs;
        InvestorBalanceArgs memory investorBalanceArgs;
        InvestorYieldArgs memory investorYieldArgs;

        // ----------------------------------------------------------
        //  No0. Set up time
        // ----------------------------------------------------------
        vm.warp(1735689600); // 2025-01-01 00:00:00 UTC

        // ----------------------------------------------------------
        //  No1. Add admin by Safe
        // ----------------------------------------------------------
        vm.prank(safe);
        investment.addAdmin(admin2);
        address[] memory adminList = investment.getAdminList();
        assertEq(adminList.length, 3, "No1: adminList.length is not equal");
        assertEq(adminList[2], admin2, "No1: adminList[2] is not equal");

        // ----------------------------------------------------------
        //  No2. RegisterProduct
        // ----------------------------------------------------------
        vm.prank(admin1);
        investment.registerProduct(registerProductArgs);

        // Assert product registration
        Schema.Product memory productForNo2 = investment.getProduct(registerProductArgs.productId);
        assertEq(productForNo2.productId, registerProductArgs.productId, "No2: productId is not equal");
        assertEq(productForNo2.offeringAmount, registerProductArgs.offeringAmount, "No2: offeringAmount is not equal");
        assertEq(productForNo2.minInvestment, registerProductArgs.minInvestment, "No2: minInvestment is not equal");
        assertEq(
            productForNo2.offeringEndDate, registerProductArgs.offeringEndDate, "No2: offeringEndDate is not equal"
        );
        assertEq(productForNo2.maturityDate, registerProductArgs.maturityDate, "No2: maturityDate is not equal");
        assertEq(productForNo2.expectedYield, registerProductArgs.expectedYield, "No2: expectedYield is not equal");
        assertEq(
            productForNo2.operationStartDate,
            registerProductArgs.operationStartDate,
            "No2: operationStartDate is not equal"
        );
        assertEq(
            productForNo2.distributionStartDate,
            registerProductArgs.distributionStartDate,
            "No2: distributionStartDate is not equal"
        ); // Same as maturity date in this scenario
        assertEq(
            productForNo2.totalDistributionCount,
            registerProductArgs.totalDistributionCount,
            "No2: totalDistributionCount is not equal"
        );
        assertEq(
            productForNo2.distributionInterval,
            registerProductArgs.distributionInterval,
            "No2: distributionInterval is not equal"
        );

        // Assert initial values
        assertEq(productForNo2.raisedAmount, 0, "No2: raisedAmount is not equal");
        assertEq(productForNo2.productPool, 0, "No2: productPool is not equal");
        assertEq(productForNo2.distributedCount, 0, "No2: distributedCount is not equal");
        assertEq(productForNo2.distributedYieldPerCount, 0, "No2: distributedYieldPerCount is not equal");
        assertEq(productForNo2.distributedTokenId, 0, "No2: distributedTokenId is not equal");
        assertEq(productForNo2.totalReturnedAmount, 0, "No2: totalReturnedAmount is not equal");
        assertEq(productForNo2.maturedTokenId, 0, "No2: maturedTokenId is not equal");
        assertFalse(productForNo2.isMaturity, "No2: isMaturity is not false");
        assertFalse(productForNo2.isInsufficientBalance, "No2: isInsufficientBalance is not false");

        // ----------------------------------------------------------
        //  No3. invest half of offering amount（JPY）
        // ----------------------------------------------------------
        uint256 halfOfferingAmount = registerProductArgs.offeringAmount / 2;
        uint256 amountPer4 = halfOfferingAmount / 4;
        investAmountArgs.investAmount1 = amountPer4 * 3;
        investAmountArgs.investAmount2 = amountPer4;
        unitCountArgs.unitCount1 = investAmountArgs.investAmount1 / registerProductArgs.minInvestment;
        unitCountArgs.unitCount2 = investAmountArgs.investAmount2 / registerProductArgs.minInvestment;

        vm.startPrank(admin1);
        investment.mintNFT(PRODUCT_ID, unitCountArgs.unitCount1, investorArgs.investor1);
        investment.mintNFT(PRODUCT_ID, unitCountArgs.unitCount2, investorArgs.investor2);
        vm.stopPrank();

        // Assert Product
        Schema.Product memory productForNo3 = investment.getProduct(PRODUCT_ID);
        assertEq(
            productForNo3.raisedAmount,
            investAmountArgs.investAmount1 + investAmountArgs.investAmount2,
            "No3: raisedAmount is not equal"
        );
        assertEq(productForNo3.productPool, 0, "No3: productPool is not equal");

        // Assert NFT
        assertEq(
            InvestmentNFT(productForNo3.nftContract).balanceOf(investorArgs.investor1),
            1,
            "No3: balanceOf(investor1) is not equal"
        );
        assertEq(
            InvestmentNFT(productForNo3.nftContract).balanceOf(investorArgs.investor2),
            1,
            "No3: balanceOf(investor2) is not equal"
        );
        assertEq(InvestmentNFT(productForNo3.nftContract).tokenIdCounter(), 2, "No3: tokenIdCounter is not equal");

        // ----------------------------------------------------------
        //  No4. invest half of offering amount（USDT）
        // ----------------------------------------------------------
        investAmountArgs.investAmount3 = amountPer4 * 3;
        investAmountArgs.investAmount4 = amountPer4;
        unitCountArgs.unitCount3 = investAmountArgs.investAmount3 / registerProductArgs.minInvestment;
        unitCountArgs.unitCount4 = investAmountArgs.investAmount4 / registerProductArgs.minInvestment;

        usdt.mint(investorArgs.investor3, investAmountArgs.investAmount3);
        usdt.mint(investorArgs.investor4, investAmountArgs.investAmount4);

        vm.startPrank(investorArgs.investor3);
        usdt.approve(address(investment), investAmountArgs.investAmount3);
        investment.invest(PRODUCT_ID, unitCountArgs.unitCount3);
        vm.stopPrank();

        vm.startPrank(investorArgs.investor4);
        usdt.approve(address(investment), investAmountArgs.investAmount4);
        investment.invest(PRODUCT_ID, unitCountArgs.unitCount4);
        vm.stopPrank();

        // Assert Product
        Schema.Product memory productForNo4 = investment.getProduct(PRODUCT_ID);
        assertEq(productForNo4.raisedAmount, registerProductArgs.offeringAmount, "No4: raisedAmount is not equal");
        assertEq(
            productForNo4.productPool,
            investAmountArgs.investAmount3 + investAmountArgs.investAmount4,
            "No4: productPool is not equal"
        );

        // Assert NFT
        assertEq(
            InvestmentNFT(productForNo4.nftContract).balanceOf(investorArgs.investor3),
            1,
            "No4: balanceOf(investor3) is not equal"
        );
        assertEq(
            InvestmentNFT(productForNo4.nftContract).balanceOf(investorArgs.investor4),
            1,
            "No4: balanceOf(investor4) is not equal"
        );
        assertEq(InvestmentNFT(productForNo4.nftContract).tokenIdCounter(), 4, "No4: tokenIdCounter is not equal");

        // ----------------------------------------------------------
        //  No5. Invest more than the amount being raised in JPY (Checking for errors)
        // ----------------------------------------------------------
        vm.expectRevert(IInvestmentErrors.ExceedOfferingAmount.selector);
        vm.prank(admin1);
        investment.mintNFT(PRODUCT_ID, 1, investorArgs.investor1);

        // ----------------------------------------------------------
        //  No6. Invest more than the amount being raised in USDT (Checking for errors)
        // ----------------------------------------------------------
        usdt.mint(investorArgs.investor3, registerProductArgs.minInvestment);

        vm.startPrank(investorArgs.investor3);
        usdt.approve(address(investment), registerProductArgs.minInvestment);
        vm.expectRevert(IInvestmentErrors.ExceedOfferingAmount.selector);
        investment.invest(PRODUCT_ID, 1);
        vm.stopPrank();

        // ----------------------------------------------------------
        //  No7. Automatic execution judgment processing (when there is no target)
        // ----------------------------------------------------------
        (bool upkeepNeededNo7, bytes memory performDataNo7) = Automation(address(automation)).checkUpkeep(abi.encode(0));

        assertFalse(upkeepNeededNo7, "No7: upkeepNeeded is not false");
        assertEq(performDataNo7.length, 0, "No7: performData is not equal");

        // ----------------------------------------------------------
        //  No8. Withdraw (full amount)
        // ----------------------------------------------------------
        investmentBalanceArgs.investmentBalance = usdt.balanceOf(address(investment));

        vm.prank(admin1);
        investment.withdraw(PRODUCT_ID, investmentBalanceArgs.investmentBalance);
        Schema.Product memory productForNo8 = investment.getProduct(PRODUCT_ID);
        assertEq(usdt.balanceOf(address(investment)), 0, "No8: balanceOf(investment) is not equal");
        assertEq(productForNo8.productPool, 0, "No8: productPool is not equal");

        // ----------------------------------------------------------
        //  No9. Deposit
        // ----------------------------------------------------------
        // Total of repayment amount, profit distribution amount, and tolerance at distribution
        uint256 depositAmount = productForNo8.raisedAmount + investment.simulatePeriodYield(PRODUCT_ID)[0];
        usdt.mint(admin1, depositAmount);

        vm.startPrank(admin1);
        usdt.approve(address(investment), depositAmount);
        investment.deposit(PRODUCT_ID, depositAmount);
        vm.stopPrank();

        // Assert Product
        assertEq(usdt.balanceOf(address(investment)), depositAmount, "No9: balanceOf(investment) is not equal");
        Schema.Product memory productForNo9 = investment.getProduct(PRODUCT_ID);
        assertEq(productForNo9.productPool, depositAmount, "No9: productPool is not equal");

        // ----------------------------------------------------------
        //  No10. Advance the time to the first distribution date
        // ----------------------------------------------------------
        // Same time as maturityDate
        vm.warp(registerProductArgs.distributionStartDate);

        // ----------------------------------------------------------
        //  No11. Automatic execution judgment processing (When there is Distribution)
        // ----------------------------------------------------------
        (bool upkeepNeededNo11, bytes memory performDataNo11) =
            Automation(address(automation)).checkUpkeep(abi.encode(0));
        (IAutomation.ActionType actionTypeNo11, uint256 productIdNo11) =
            abi.decode(performDataNo11, (IAutomation.ActionType, uint256));

        assertTrue(upkeepNeededNo11, "No11: upkeepNeeded is not True");
        assertEq(uint8(actionTypeNo11), uint8(IAutomation.ActionType.DistributeYield), "No11: actionType is not equal");
        assertEq(productIdNo11, PRODUCT_ID, "No11: productId is not equal");

        // ----------------------------------------------------------
        //  No12. Distribution automatic execution
        // ----------------------------------------------------------
        // Balance before distribution
        investorBalanceArgs.investor1Balance = usdt.balanceOf(investorArgs.investor1);
        investorBalanceArgs.investor2Balance = usdt.balanceOf(investorArgs.investor2);
        investorBalanceArgs.investor3Balance = usdt.balanceOf(investorArgs.investor3);
        investorBalanceArgs.investor4Balance = usdt.balanceOf(investorArgs.investor4);
        investmentBalanceArgs.beforeInvestmentBalance = usdt.balanceOf(address(investment));

        Schema.Product memory beforeProductForNo12 = investment.getProduct(PRODUCT_ID);

        uint256 periodYield = CalculateYieldLib.calculatePeriodYield(
            beforeProductForNo12.raisedAmount,
            beforeProductForNo12.expectedYield,
            beforeProductForNo12.distributionStartDate - beforeProductForNo12.operationStartDate
        );

        // Distribution amount to each investor
        investorYieldArgs.investor1Yield = CalculateYieldLib.calculateIndividualPeriodYield(
            periodYield,
            IInvestmentNFT(beforeProductForNo12.nftContract).getInvestmentAmount(1),
            beforeProductForNo12.raisedAmount
        );
        investorYieldArgs.investor2Yield = CalculateYieldLib.calculateIndividualPeriodYield(
            periodYield,
            IInvestmentNFT(beforeProductForNo12.nftContract).getInvestmentAmount(2),
            beforeProductForNo12.raisedAmount
        );
        investorYieldArgs.investor3Yield = CalculateYieldLib.calculateIndividualPeriodYield(
            periodYield,
            IInvestmentNFT(beforeProductForNo12.nftContract).getInvestmentAmount(3),
            beforeProductForNo12.raisedAmount
        );
        investorYieldArgs.investor4Yield = CalculateYieldLib.calculateIndividualPeriodYield(
            periodYield,
            IInvestmentNFT(beforeProductForNo12.nftContract).getInvestmentAmount(4),
            beforeProductForNo12.raisedAmount
        );

        vm.prank(forwarder);
        Automation(address(automation)).performUpkeep(performDataNo11);

        // Assert Product
        Schema.Product memory afterProductForNo12 = investment.getProduct(PRODUCT_ID);
        assertEq(afterProductForNo12.distributedCount, 1, "No12: distributedCount is not equal");
        assertEq(
            usdt.balanceOf(investorArgs.investor1) - investorBalanceArgs.investor1Balance,
            investorYieldArgs.investor1Yield,
            "No12: investor1Yield is not equal"
        );
        assertEq(
            usdt.balanceOf(investorArgs.investor2) - investorBalanceArgs.investor2Balance,
            investorYieldArgs.investor2Yield,
            "No12: investor2Yield is not equal"
        );
        assertEq(
            usdt.balanceOf(investorArgs.investor3) - investorBalanceArgs.investor3Balance,
            investorYieldArgs.investor3Yield,
            "No12: investor3Yield is not equal"
        );
        assertEq(
            usdt.balanceOf(investorArgs.investor4) - investorBalanceArgs.investor4Balance,
            investorYieldArgs.investor4Yield,
            "No12: investor4Yield is not equal"
        );
        assertEq(
            beforeProductForNo12.productPool - afterProductForNo12.productPool,
            investorYieldArgs.investor1Yield + investorYieldArgs.investor2Yield + investorYieldArgs.investor3Yield
                + investorYieldArgs.investor4Yield,
            "No12: productPool is not equal"
        );
        assertEq(
            investmentBalanceArgs.beforeInvestmentBalance - usdt.balanceOf(address(investment)),
            investorYieldArgs.investor1Yield + investorYieldArgs.investor2Yield + investorYieldArgs.investor3Yield
                + investorYieldArgs.investor4Yield,
            "No12: productPool is not equal"
        );

        // ----------------------------------------------------------
        //  No13. Automatic execution judgment processing (When there is Maturity)
        // ----------------------------------------------------------
        (bool upkeepNeededNo13, bytes memory performDataNo13) =
            Automation(address(automation)).checkUpkeep(abi.encode(0));
        (IAutomation.ActionType actionTypeNo13, uint256 productIdNo13) =
            abi.decode(performDataNo13, (IAutomation.ActionType, uint256));

        assertTrue(upkeepNeededNo13, "No13: upkeepNeeded is not True");
        assertEq(uint8(actionTypeNo13), uint8(IAutomation.ActionType.Maturity), "No13: actionType is not equal");
        assertEq(productIdNo13, PRODUCT_ID, "No13: productId is not equal");

        // ----------------------------------------------------------
        //  No14. Maturity automatic execution
        // ----------------------------------------------------------
        // Balance before Maturity
        investorBalanceArgs.investor1Balance = usdt.balanceOf(investorArgs.investor1);
        investorBalanceArgs.investor2Balance = usdt.balanceOf(investorArgs.investor2);
        investorBalanceArgs.investor3Balance = usdt.balanceOf(investorArgs.investor3);
        investorBalanceArgs.investor4Balance = usdt.balanceOf(investorArgs.investor4);
        investmentBalanceArgs.beforeInvestmentBalance = usdt.balanceOf(address(investment));

        Schema.Product memory beforeProductForNo14 = investment.getProduct(PRODUCT_ID);

        IInvestmentNFT.NFTInfo[] memory nftInfos = InvestmentNFT(beforeProductForNo14.nftContract).getNFTInfos(1);
        uint256 totalReturnedAmount = 0;
        for (uint256 i = 0; i < nftInfos.length; i++) {
            totalReturnedAmount += nftInfos[i].investmentAmount;
        }

        vm.prank(forwarder);
        Automation(address(automation)).performUpkeep(performDataNo13);

        // Assert Product
        Schema.Product memory afterProductForNo14 = investment.getProduct(PRODUCT_ID);
        assertTrue(afterProductForNo14.isMaturity, "No14: isMaturity is not true");
        assertEq(afterProductForNo14.maturedTokenId, 4, "No14: maturedTokenId is not equal");
        assertEq(afterProductForNo14.totalReturnedAmount, totalReturnedAmount, "No14: totalReturnedAmount is not equal");
        assertEq(
            usdt.balanceOf(investorArgs.investor1) - investorBalanceArgs.investor1Balance,
            nftInfos[0].investmentAmount,
            "No14: investor1Yield is not equal"
        );
        assertEq(
            usdt.balanceOf(investorArgs.investor2) - investorBalanceArgs.investor2Balance,
            nftInfos[1].investmentAmount,
            "No14: investor2Yield is not equal"
        );
        assertEq(
            usdt.balanceOf(investorArgs.investor3) - investorBalanceArgs.investor3Balance,
            nftInfos[2].investmentAmount,
            "No14: investor3Yield is not equal"
        );
        assertEq(
            usdt.balanceOf(investorArgs.investor4) - investorBalanceArgs.investor4Balance,
            nftInfos[3].investmentAmount,
            "No14: investor4Yield is not equal"
        );
        assertEq(
            beforeProductForNo14.productPool - afterProductForNo14.productPool,
            totalReturnedAmount,
            "No14: productPool is not equal"
        );

        // ----------------------------------------------------------
        //  No15. Automatic execution judgment processing (When there is no target)
        // ----------------------------------------------------------
        (bool upkeepNeededNo15, bytes memory performDataNo15) =
            Automation(address(automation)).checkUpkeep(abi.encode(0));

        assertFalse(upkeepNeededNo15, "No15: upkeepNeeded is not false");
        assertEq(performDataNo15.length, 0, "No15: performData is not equal");

        // ----------------------------------------------------------
        //  No16. System monitoring (information acquisition)
        // ----------------------------------------------------------
        Schema.Product memory productForNo16 = investment.getProduct(PRODUCT_ID);
        uint256 periodTolerance =
            CalculateYieldLib.calculatePeriodTolerance(InvestmentNFT(productForNo16.nftContract).tokenIdCounter());

        assertEq(productForNo16.productId, registerProductArgs.productId, "No16: productId is not equal");
        assertEq(
            IInvestmentNFT(productForNo16.nftContract).productId(),
            registerProductArgs.productId,
            "No16: productId is not equal"
        );
        assertEq(productForNo16.offeringAmount, registerProductArgs.offeringAmount, "No16: offeringAmount is not equal");
        assertEq(productForNo16.minInvestment, registerProductArgs.minInvestment, "No16: minInvestment is not equal");
        assertEq(
            productForNo16.offeringEndDate, registerProductArgs.offeringEndDate, "No16: offeringEndDate is not equal"
        );
        assertEq(productForNo16.raisedAmount, registerProductArgs.offeringAmount, "No16: raisedAmount is not equal");
        assertTrue(periodTolerance >= productForNo16.productPool, "No16: productPool is not true");
        assertEq(productForNo16.maturityDate, registerProductArgs.maturityDate, "No16: maturityDate is not equal");
        assertEq(productForNo16.expectedYield, registerProductArgs.expectedYield, "No16: expectedYield is not equal");
        assertEq(
            productForNo16.operationStartDate,
            registerProductArgs.operationStartDate,
            "No16: operationStartDate is not equal"
        );
        assertEq(
            productForNo16.distributionStartDate,
            registerProductArgs.distributionStartDate,
            "No16: distributionStartDate is not equal"
        );
        assertEq(
            productForNo16.totalDistributionCount,
            registerProductArgs.totalDistributionCount,
            "No16: totalDistributionCount is not equal"
        );
        assertEq(
            productForNo16.distributionInterval,
            registerProductArgs.distributionInterval,
            "No16: distributionInterval is not equal"
        );
        assertEq(productForNo16.distributedCount, 1, "No16: distributedCount is not equal");
        assertEq(productForNo16.distributedYieldPerCount, 0, "No16: distributedYieldPerCount is not equal");
        assertEq(productForNo16.distributedTokenId, 0, "No16: distributedTokenId is not equal");
        assertEq(
            productForNo16.totalReturnedAmount, productForNo16.raisedAmount, "No16: totalReturnedAmount is not equal"
        );
        assertEq(
            productForNo16.maturedTokenId,
            IInvestmentNFT(productForNo16.nftContract).tokenIdCounter(),
            "No16: maturedTokenId is not equal"
        );
        assertTrue(productForNo16.isMaturity, "No16: isMaturity is not true");
        assertFalse(productForNo16.isInsufficientBalance, "No16: isInsufficientBalance is not false");
    }

    receive() external payable {}
}
