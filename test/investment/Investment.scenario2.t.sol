// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {MCTest, MCDevKit, stdError} from "@mc-devkit/Flattened.sol";

// investment
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

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// To avoid stack too deep
struct AdminArgs {
    address nonAdmin;
    address admin1;
    address admin2;
}

struct InvestorArgs {
    address investor1;
    address investor2;
    address investor3;
}

struct InvestAmountArgs {
    uint256 investAmount1;
    uint256 investAmount2;
    uint256 investAmount3;
}

struct UnitCountArgs {
    uint256 unitCount1;
    uint256 unitCount2;
}

contract InvestmentScenario2Test is MCTest {
    uint256 constant PRODUCT_ID = 1;
    uint256 constant OFFERING_AMOUNT = 1_000_000_000_000; // 1_000_000USD(1USD = 150JPY: 150_000_000JPY)
    uint256 constant MIN_INVESTMENT = 250_000_000; // 250USD(1USD = 150JPY: 37_500JPY)
    uint256 constant OFFERING_END_DATE = 1737763200; // 2025-01-25 00:00:00 UTC
    uint256 constant MATURITY_DATE = 1767225600; // 2026-01-01 00:00:00 UTC
    uint256 constant EXPECTED_YIELD = 500; // 5%
    uint256 constant OPERATION_STARTDATE = 1738368000; // 2025-02-01 00:00:00 UTC
    uint256 constant DISTRIBUTION_START_DATE = 1748736000; // 2025-06-01 00:00:00 UTC
    uint256 constant TOTAL_DISTRIBUTION_COUNT = 3;
    uint256 constant DISTRIBUTION_INTERVAL = 3;

    uint256 constant PRODUCT_ID2 = 2;
    uint256 constant OFFERING_AMOUNT2 = OFFERING_AMOUNT * 2;
    uint256 constant MIN_INVESTMENT2 = MIN_INVESTMENT;
    uint256 constant OFFERING_END_DATE2 = OFFERING_END_DATE + 30 days;
    uint256 constant MATURITY_DATE2 = 1764547200; // 2025-12-01 00:00:00 UTC (PRODUCT1 3times distribution)
    uint256 constant EXPECTED_YIELD2 = 800;
    uint256 constant OPERATION_STARTDATE2 = OPERATION_STARTDATE + 30 days;
    uint256 constant DISTRIBUTION_START_DATE2 = DISTRIBUTION_START_DATE + 30 days;
    uint256 constant TOTAL_DISTRIBUTION_COUNT2 = 2;
    uint256 constant DISTRIBUTION_INTERVAL2 = DISTRIBUTION_INTERVAL;

    IInvestment public investment;
    MockInvestmentERC20 public usdt;
    Automation public automation;

    address safe;
    address forwarder;
    address[] admins;
    Schema.RegisterProductArgs registerProductArgs1;
    Schema.RegisterProductArgs registerProductArgs2;
    AdminArgs adminArgs;
    InvestorArgs investorArgs1;
    InvestorArgs investorArgs2;
    InvestAmountArgs investAmountArgs1;
    InvestAmountArgs investAmountArgs2;
    UnitCountArgs unitCountArgs1;
    UnitCountArgs unitCountArgs2;

    function setUp() public {
        // make up address
        safe = makeAddr("safe");
        forwarder = makeAddr("forwarder");
        registerProductArgs1 = Schema.RegisterProductArgs({
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
        registerProductArgs2 = Schema.RegisterProductArgs({
            productId: PRODUCT_ID2,
            offeringAmount: OFFERING_AMOUNT2,
            minInvestment: MIN_INVESTMENT2,
            offeringEndDate: OFFERING_END_DATE2,
            maturityDate: MATURITY_DATE2,
            expectedYield: EXPECTED_YIELD2,
            operationStartDate: OPERATION_STARTDATE2,
            distributionStartDate: DISTRIBUTION_START_DATE2,
            totalDistributionCount: TOTAL_DISTRIBUTION_COUNT2,
            distributionInterval: DISTRIBUTION_INTERVAL2,
            baseTokenURI: "https://example.com/metadata/",
            requiredTier: 0
        });
        adminArgs = AdminArgs({nonAdmin: makeAddr("nonAdmin"), admin1: makeAddr("admin1"), admin2: makeAddr("admin2")});
        investorArgs1 = InvestorArgs({
            investor1: makeAddr("investor1"), investor2: makeAddr("investor2"), investor3: makeAddr("investor3")
        });
        investorArgs2 = InvestorArgs({
            investor1: makeAddr("investor4"), investor2: makeAddr("investor5"), investor3: makeAddr("investor6")
        });

        admins.push(adminArgs.admin1);

        // deploy
        usdt = new MockInvestmentERC20();
        vm.prank(safe);
        investment = IInvestment(InvestmentDeployer.deployInvestment(mc, admins, admins, address(usdt), safe));
        automation = new Automation(address(investment), forwarder);

        vm.prank(safe);
        investment.addAdmin(address(automation));
    }

    function test_scenario2_MultipleDistribution() public {
        // ----------------------------------------------------------
        //  No0. Set up time
        // ----------------------------------------------------------
        vm.warp(1735689600); // 2025-01-01 00:00:00 UTC

        // ----------------------------------------------------------
        //  No1. ProductID1: RegisterProduct
        // ----------------------------------------------------------
        _fromNo1_productID1_registerProduct();

        // ----------------------------------------------------------
        //  No2. ProductID2: RegisterProduct
        // ----------------------------------------------------------
        _fromNo2_productID2_registerProduct();

        // ----------------------------------------------------------
        //  No3. ProductID1: invest 1/4 of offering amount (JPY)
        // ----------------------------------------------------------
        _fromNo3_productID1_investJPY();

        // ----------------------------------------------------------
        //  No4. ProductID1: invest 1/4 of offering amount (USDT)
        // ----------------------------------------------------------
        _fromNo4_productID1_investUSDT();

        // ----------------------------------------------------------
        //  No5. ProductID2: invest half of offering amount (JPY)
        // ----------------------------------------------------------
        _fromNo5_productID2_investJPY();

        // ----------------------------------------------------------
        //  No6. Advance the time to the offeringEndDate for ProductID1
        // ----------------------------------------------------------
        vm.warp(registerProductArgs1.offeringEndDate);

        // ----------------------------------------------------------
        //  No7. ProductID1: Investment applications after the offeringEndDate has passed (USDT)
        // ----------------------------------------------------------
        _fromNo7_productID1_overOfferingEndDateInvestUSDT();

        // ----------------------------------------------------------
        //  No8. Advance the time to the operationStartDate for ProductID1
        // ----------------------------------------------------------
        vm.warp(registerProductArgs1.operationStartDate);

        // ----------------------------------------------------------
        //  No9. ProductID1: Investment applications after the operationStartDate has passed (JPY)
        // ----------------------------------------------------------
        _fromNo9_productID1_overOperationStartDateInvestJPT();

        // ----------------------------------------------------------
        //  No10. Automatic execution judgment processing (when there is no target)
        // ----------------------------------------------------------
        _checkUpkeep_noTarget();

        // ----------------------------------------------------------
        //  No11. ProductID1: Withdraw (full amount)
        // ----------------------------------------------------------
        _fromNo11_productID1_withdraw();

        // ----------------------------------------------------------
        //  No12. ProductID1: Deposit
        // ----------------------------------------------------------
        uint256 depositAmount = _fromNo12_productID1_deposit();

        // ----------------------------------------------------------
        //  No13. ProductID2: Deposit
        // ----------------------------------------------------------
        uint256 depositAmount2 = _fromNo13_productID2_deposit(depositAmount);

        // ----------------------------------------------------------
        //  No14. Advance the time to the first distribution date for ProductID1
        // ----------------------------------------------------------
        vm.warp(registerProductArgs1.distributionStartDate);

        // ----------------------------------------------------------
        //  No15. Automatic execution judgment processing (When there is first distribution for ProductId1)
        // ----------------------------------------------------------
        bytes memory performDataNo15 = _checkUpkeep_distributeYield(registerProductArgs1.productId);

        // ----------------------------------------------------------
        //  No16. Distribution automatic execution (ProductID1-first)
        // ----------------------------------------------------------
        _fromNo16_productID1_performUpkeep_firstDistribution(performDataNo15);

        // ----------------------------------------------------------
        //  No17. Distribution automatic reexecution (ProductID1-first)
        // ----------------------------------------------------------
        _fromNo17_productID1_rePerformUpkeep_firstDistribution(performDataNo15);

        // ----------------------------------------------------------
        //  No18. Automatic execution judgment processing (when there is no target)
        // ----------------------------------------------------------
        _checkUpkeep_noTarget();

        // ----------------------------------------------------------
        //  No19. Advance the time to the first distribution date for ProductID2
        // ----------------------------------------------------------
        vm.warp(registerProductArgs2.distributionStartDate);

        // ----------------------------------------------------------
        //  No20. Automatic execution judgment processing (When there is first distribution for ProductId2)
        // ----------------------------------------------------------
        bytes memory performDataNo20 = _checkUpkeep_distributeYield(registerProductArgs2.productId);

        // ----------------------------------------------------------
        //  No21. Distribution automatic execution (ProductID2-first)
        // ----------------------------------------------------------
        _fromNo21_productID2_performUpkeep_firstDistribution(performDataNo20);

        // ----------------------------------------------------------
        //  No22. Automatic execution judgment processing (when there is no target)
        // ----------------------------------------------------------
        _checkUpkeep_noTarget();

        // ----------------------------------------------------------
        //  No23. ProductID2: transfer ownership of NFT
        // ----------------------------------------------------------
        _fromNo23_productID1_transferNFT();

        // ----------------------------------------------------------
        //  No24. Advance the time to the second distribution date for ProductID1
        // ----------------------------------------------------------
        Schema.Product memory productForNo24 = investment.getProduct(registerProductArgs1.productId);
        uint256 secondDistributionDate = DistributionDateLib.calculateNextDistributionDate(
            productForNo24.distributionStartDate,
            productForNo24.distributionInterval,
            productForNo24.distributedCount, // current distributedCount for next distribution
            productForNo24.isMonthEnd
        );
        vm.warp(secondDistributionDate);

        // ----------------------------------------------------------
        //  No25. Automatic execution judgment processing (When there is first distribution for ProductId1)
        // ----------------------------------------------------------
        bytes memory performDataNo25 = _checkUpkeep_distributeYield(registerProductArgs1.productId);

        // ----------------------------------------------------------
        //  No26. Distribution automatic execution (ProductID1-second)
        // ----------------------------------------------------------
        _fromNo26_productID1_performUpkeep_secondDistribution(performDataNo25);

        // ----------------------------------------------------------
        //  No27. Distribution automatic reexecution (ProductID1-second)
        // ----------------------------------------------------------
        _fromNo27_productID1_rePerformUpkeep_secondDistribution(performDataNo25);

        // ----------------------------------------------------------
        //  No28. Automatic execution judgment processing (when there is no target)
        // ----------------------------------------------------------
        _checkUpkeep_noTarget();

        // ----------------------------------------------------------
        //  No29. Advance the time to the second distribution date for ProductID2
        // ----------------------------------------------------------
        Schema.Product memory productForNo29 = investment.getProduct(registerProductArgs2.productId);
        uint256 secondDistributionDate2 = DistributionDateLib.calculateNextDistributionDate(
            productForNo29.distributionStartDate,
            productForNo29.distributionInterval,
            productForNo29.distributedCount, // current distributedCount for next distribution
            productForNo29.isMonthEnd
        );
        vm.warp(secondDistributionDate2);

        // ----------------------------------------------------------
        //  No30. Automatic execution judgment processing (When there is second distribution for ProductId2)
        // ----------------------------------------------------------
        bytes memory performDataNo30 = _checkUpkeep_distributeYield(registerProductArgs2.productId);

        // ----------------------------------------------------------
        //  No31. Distribution automatic execution (ProductID2-second)
        // ----------------------------------------------------------
        _fromNo31_productID2_performUpkeep_secondDistribution(performDataNo30);

        // ----------------------------------------------------------
        //  No32. Automatic execution judgment processing (when there is no target)
        // ----------------------------------------------------------
        _checkUpkeep_noTarget();

        // ----------------------------------------------------------
        //  No33. Advance the time to the third distribution date for ProductID1
        //        (Maturity day for ProductID2)
        // ----------------------------------------------------------
        Schema.Product memory productForNo33 = investment.getProduct(registerProductArgs1.productId);
        uint256 thirdDistributionDate = DistributionDateLib.calculateNextDistributionDate(
            productForNo33.distributionStartDate,
            productForNo33.distributionInterval,
            productForNo33.distributedCount, // current distributedCount for next distribution
            productForNo33.isMonthEnd
        );
        assertEq(thirdDistributionDate, registerProductArgs2.maturityDate, "No33: thirdDistributionDate is not equal");
        vm.warp(registerProductArgs2.maturityDate);

        // ----------------------------------------------------------
        //  No34. Automatic execution judgment processing (When there is third distribution for ProductId1)
        // ----------------------------------------------------------
        bytes memory performDataNo34 = _checkUpkeep_distributeYield(registerProductArgs1.productId);

        // ----------------------------------------------------------
        //  No35. Distribution automatic execution (ProductID1-third)
        // ----------------------------------------------------------
        _fromNo35_productID1_performUpkeep_thirdDistribution(performDataNo34);

        // ----------------------------------------------------------
        //  No36. Distribution automatic reexecution (ProductID1-third)
        // ----------------------------------------------------------
        _fromNo36_productID1_rePerformUpkeep_thirdDistribution(performDataNo34);

        // ----------------------------------------------------------
        //  No37. Automatic execution judgment processing (When there is maturity for ProductId2)
        // ----------------------------------------------------------
        bytes memory performDataNo37 = _checkUpkeep_maturity(registerProductArgs2.productId);

        // ----------------------------------------------------------
        //  No38. Maturity automatic execution (ProductID2-maturity)
        // ----------------------------------------------------------
        _fromNo38_productID2_performUpkeep_maturity(performDataNo37);

        // ----------------------------------------------------------
        //  No39. Automatic execution judgment processing (when there is no target)
        // ----------------------------------------------------------
        _checkUpkeep_noTarget();

        // ----------------------------------------------------------
        //  No40. Advance the time to the maturity day for ProductID1
        // ----------------------------------------------------------
        vm.warp(registerProductArgs1.maturityDate);

        // ----------------------------------------------------------
        //  No41. Automatic execution judgment processing (When there is maturity for ProductId1)
        // ----------------------------------------------------------
        bytes memory performDataNo41 = _checkUpkeep_maturity(registerProductArgs1.productId);

        // ----------------------------------------------------------
        //  No42. Maturity automatic execution (ProductID1-maturity)
        // ----------------------------------------------------------
        _fromNo42_productID1_performUpkeep_maturity(performDataNo41);

        // ----------------------------------------------------------
        //  No43. Automatic execution judgment processing (when there is no target)
        // ----------------------------------------------------------
        _checkUpkeep_noTarget();

        // ----------------------------------------------------------
        //  No44. System monitoring (information acquisition)
        // ----------------------------------------------------------
        _fromNo44_systemMonitoring();
    }

    function _checkUpkeep_noTarget() public {
        // ----------------------------------------------------------
        //  Automatic execution judgment processing (when there is no target)
        // ----------------------------------------------------------
        (bool upkeepNeeded, bytes memory performData) = Automation(address(automation)).checkUpkeep(abi.encode(0));

        assertFalse(upkeepNeeded, "checkUpKeep: upkeepNeeded is not false");
        assertEq(performData.length, 0, "checkUpKeep: performData is not equal");
    }

    function _checkUpkeep_distributeYield(uint256 _productId) public returns (bytes memory) {
        // ----------------------------------------------------------
        //  Automatic execution judgment processing (when there is target)
        // ----------------------------------------------------------
        (bool upkeepNeeded, bytes memory performData) =
            Automation(address(automation)).checkUpkeep(abi.encode(_productId));
        (IAutomation.ActionType actionType, uint256 productId) =
            abi.decode(performData, (IAutomation.ActionType, uint256));

        assertTrue(upkeepNeeded, "checkUpKeep: upkeepNeeded is not True");
        assertEq(
            uint8(actionType), uint8(IAutomation.ActionType.DistributeYield), "checkUpKeep: actionType is not equal"
        );
        assertEq(productId, _productId, "checkUpKeep: productId is not equal");

        return performData;
    }

    function _checkUpkeep_maturity(uint256 _productId) public returns (bytes memory) {
        // ----------------------------------------------------------
        //  Automatic execution judgment processing (when there is target)
        // ----------------------------------------------------------
        (bool upkeepNeeded, bytes memory performData) =
            Automation(address(automation)).checkUpkeep(abi.encode(_productId));
        (IAutomation.ActionType actionType, uint256 productId) =
            abi.decode(performData, (IAutomation.ActionType, uint256));

        assertTrue(upkeepNeeded, "checkUpKeep: upkeepNeeded is not True");
        assertEq(uint8(actionType), uint8(IAutomation.ActionType.Maturity), "checkUpKeep: actionType is not equal");
        assertEq(productId, _productId, "checkUpKeep: productId is not equal");

        return performData;
    }

    function _fromNo1_productID1_registerProduct() public {
        // ----------------------------------------------------------
        //  No1. ProductID1: RegisterProduct
        // ----------------------------------------------------------
        vm.prank(adminArgs.admin1);
        investment.registerProduct(registerProductArgs1);

        // Assert product registration
        Schema.Product memory productForNo1 = investment.getProduct(registerProductArgs1.productId);
        assertEq(productForNo1.productId, registerProductArgs1.productId, "No1: productId is not equal");
        assertEq(productForNo1.offeringAmount, registerProductArgs1.offeringAmount, "No1: offeringAmount is not equal");
        assertEq(productForNo1.minInvestment, registerProductArgs1.minInvestment, "No1: minInvestment is not equal");
        assertEq(
            productForNo1.offeringEndDate, registerProductArgs1.offeringEndDate, "No1: offeringEndDate is not equal"
        );
        assertEq(productForNo1.maturityDate, registerProductArgs1.maturityDate, "No1: maturityDate is not equal");
        assertEq(productForNo1.expectedYield, registerProductArgs1.expectedYield, "No1: expectedYield is not equal");
        assertEq(
            productForNo1.operationStartDate,
            registerProductArgs1.operationStartDate,
            "No1: operationStartDate is not equal"
        );
        assertEq(
            productForNo1.distributionStartDate,
            registerProductArgs1.distributionStartDate,
            "No1: distributionStartDate is not equal"
        );
        assertEq(
            productForNo1.totalDistributionCount,
            registerProductArgs1.totalDistributionCount,
            "No1: totalDistributionCount is not equal"
        );
        assertEq(
            productForNo1.distributionInterval,
            registerProductArgs1.distributionInterval,
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
    }

    function _fromNo2_productID2_registerProduct() public {
        // ----------------------------------------------------------
        //  No2. ProductID2: RegisterProduct
        // ----------------------------------------------------------
        vm.prank(adminArgs.admin1);
        investment.registerProduct(registerProductArgs2);

        // Assert product registration
        Schema.Product memory productForNo2 = investment.getProduct(registerProductArgs2.productId);
        assertEq(productForNo2.productId, registerProductArgs2.productId, "No2: productId is not equal");
        assertEq(productForNo2.offeringAmount, registerProductArgs2.offeringAmount, "No2: offeringAmount is not equal");
        assertEq(productForNo2.minInvestment, registerProductArgs2.minInvestment, "No2: minInvestment is not equal");
        assertEq(
            productForNo2.offeringEndDate, registerProductArgs2.offeringEndDate, "No2: offeringEndDate is not equal"
        );
        assertEq(productForNo2.maturityDate, registerProductArgs2.maturityDate, "No2: maturityDate is not equal");
        assertEq(productForNo2.expectedYield, registerProductArgs2.expectedYield, "No2: expectedYield is not equal");
        assertEq(
            productForNo2.operationStartDate,
            registerProductArgs2.operationStartDate,
            "No2: operationStartDate is not equal"
        );
        assertEq(
            productForNo2.distributionStartDate,
            registerProductArgs2.distributionStartDate,
            "No2: distributionStartDate is not equal"
        );
        assertEq(
            productForNo2.totalDistributionCount,
            registerProductArgs2.totalDistributionCount,
            "No2: totalDistributionCount is not equal"
        );
        assertEq(
            productForNo2.distributionInterval,
            registerProductArgs2.distributionInterval,
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
    }

    function _fromNo3_productID1_investJPY() public {
        // ----------------------------------------------------------
        //  No3. ProductID1: invest 1/4 of offering amount (JPY)
        // ----------------------------------------------------------
        uint256 halfOfferingAmount = registerProductArgs1.offeringAmount / 2;
        uint256 amountPer4 = halfOfferingAmount / 4;
        investAmountArgs1.investAmount1 = amountPer4;
        unitCountArgs1.unitCount1 = investAmountArgs1.investAmount1 / registerProductArgs1.minInvestment;

        vm.prank(adminArgs.admin1);
        investment.mintNFT(registerProductArgs1.productId, unitCountArgs1.unitCount1, investorArgs1.investor1);

        // Assert Product
        Schema.Product memory productForNo3 = investment.getProduct(registerProductArgs1.productId);
        assertEq(productForNo3.raisedAmount, investAmountArgs1.investAmount1, "No3: raisedAmount is not equal");
        assertEq(productForNo3.productPool, 0, "No3: productPool is not equal");
        assertEq(usdt.balanceOf(address(investment)), 0, "No3: balanceOf(investment) is not equal");

        // Assert NFT
        assertEq(
            InvestmentNFT(productForNo3.nftContract).balanceOf(investorArgs1.investor1),
            1,
            "No3: balanceOf(investor1) is not equal"
        );
        assertEq(InvestmentNFT(productForNo3.nftContract).tokenIdCounter(), 1, "No3: tokenIdCounter is not equal");
    }

    function _fromNo4_productID1_investUSDT() public {
        // ----------------------------------------------------------
        //  No4. ProductID1: invest 1/4 of offering amount (USDT)
        // ----------------------------------------------------------
        uint256 halfOfferingAmount = registerProductArgs1.offeringAmount / 2;
        uint256 amountPer4 = halfOfferingAmount / 4;
        investAmountArgs1.investAmount2 = amountPer4;
        unitCountArgs1.unitCount2 = investAmountArgs1.investAmount2 / registerProductArgs1.minInvestment;

        usdt.mint(investorArgs1.investor2, investAmountArgs1.investAmount2);

        vm.startPrank(investorArgs1.investor2);
        usdt.approve(address(investment), investAmountArgs1.investAmount2);
        investment.invest(registerProductArgs1.productId, unitCountArgs1.unitCount2);
        vm.stopPrank();

        // Assert Product
        Schema.Product memory productForNo4 = investment.getProduct(registerProductArgs1.productId);
        assertEq(
            productForNo4.raisedAmount,
            investAmountArgs1.investAmount1 + investAmountArgs1.investAmount2,
            "No4: raisedAmount is not equal"
        );
        assertEq(productForNo4.productPool, investAmountArgs1.investAmount2, "No4: productPool is not equal");
        assertEq(
            usdt.balanceOf(address(investment)),
            investAmountArgs1.investAmount2,
            "No4: balanceOf(investment) is not equal"
        );

        // Assert NFT
        assertEq(
            InvestmentNFT(productForNo4.nftContract).balanceOf(investorArgs1.investor2),
            1,
            "No4: balanceOf(investor2) is not equal"
        );
        assertEq(InvestmentNFT(productForNo4.nftContract).tokenIdCounter(), 2, "No4: tokenIdCounter is not equal");
    }

    function _fromNo5_productID2_investJPY() public {
        // ----------------------------------------------------------
        //  No5. ProductID2: invest half of offering amount (JPY)
        // ----------------------------------------------------------
        uint256 halfOfferingAmount = registerProductArgs2.offeringAmount / 2;
        uint256 amountPer4 = halfOfferingAmount / 4;
        investAmountArgs2.investAmount1 = amountPer4;
        investAmountArgs2.investAmount2 = amountPer4;
        unitCountArgs2.unitCount1 = investAmountArgs2.investAmount1 / registerProductArgs2.minInvestment;
        unitCountArgs2.unitCount2 = investAmountArgs2.investAmount2 / registerProductArgs2.minInvestment;

        vm.startPrank(adminArgs.admin1);
        investment.mintNFT(registerProductArgs2.productId, unitCountArgs2.unitCount1, investorArgs2.investor1);
        investment.mintNFT(registerProductArgs2.productId, unitCountArgs2.unitCount2, investorArgs2.investor2);
        vm.stopPrank();

        // Assert Product
        Schema.Product memory productForNo5 = investment.getProduct(registerProductArgs2.productId);
        assertEq(
            productForNo5.raisedAmount,
            investAmountArgs2.investAmount1 + investAmountArgs2.investAmount2,
            "No5: raisedAmount is not equal"
        );
        assertEq(productForNo5.productPool, 0, "No5: productPool is not equal");
        assertEq(
            usdt.balanceOf(address(investment)),
            investAmountArgs1.investAmount2,
            "No5: balanceOf(investment) is not equal"
        );

        // Assert NFT
        assertEq(
            InvestmentNFT(productForNo5.nftContract).balanceOf(investorArgs2.investor1),
            1,
            "No5: balanceOf(investor1) is not equal"
        );
        assertEq(
            InvestmentNFT(productForNo5.nftContract).balanceOf(investorArgs2.investor2),
            1,
            "No5: balanceOf(investor2) is not equal"
        );
        assertEq(InvestmentNFT(productForNo5.nftContract).tokenIdCounter(), 2, "No5: tokenIdCounter is not equal");
    }

    function _fromNo7_productID1_overOfferingEndDateInvestUSDT() public {
        // ----------------------------------------------------------
        //  No7. ProductID1: Investment applications after the offeringEndDate has passed (USDT)
        // ----------------------------------------------------------
        vm.prank(investorArgs1.investor3);
        vm.expectRevert(IInvestmentErrors.OfferingPeriodEnded.selector);
        investment.invest(registerProductArgs1.productId, unitCountArgs1.unitCount1);
    }

    function _fromNo9_productID1_overOperationStartDateInvestJPT() public {
        // ----------------------------------------------------------
        //  No9. ProductID1: Investment applications after the operationStartDate has passed (JPY)
        // ----------------------------------------------------------
        vm.prank(adminArgs.admin1);
        vm.expectRevert(IInvestmentErrors.OperationStartDatePassed.selector);
        investment.mintNFT(registerProductArgs1.productId, unitCountArgs1.unitCount1, investorArgs1.investor3);
    }

    function _fromNo11_productID1_withdraw() public {
        // ----------------------------------------------------------
        //  No11. ProductID1: Withdraw (full amount)
        // ----------------------------------------------------------
        uint256 investmentBalance = usdt.balanceOf(address(investment));

        vm.prank(adminArgs.admin1);
        investment.withdraw(registerProductArgs1.productId, investmentBalance);
        Schema.Product memory productForNo11 = investment.getProduct(registerProductArgs1.productId);
        assertEq(usdt.balanceOf(address(investment)), 0, "No11: balanceOf(investment) is not equal");
        assertEq(productForNo11.productPool, 0, "No11: productPool is not equal");
    }

    function _fromNo12_productID1_deposit() public returns (uint256) {
        // ----------------------------------------------------------
        //  No12. ProductID1: Deposit
        // ----------------------------------------------------------
        Schema.Product memory beforeProductForNo12 = investment.getProduct(registerProductArgs1.productId);
        // Total of repayment amount, profit distribution amount, and tolerance at distribution
        uint256 depositAmount =
            beforeProductForNo12.raisedAmount + investment.simulateTotalYield(registerProductArgs1.productId);
        usdt.mint(adminArgs.admin1, depositAmount);

        vm.startPrank(adminArgs.admin1);
        usdt.approve(address(investment), depositAmount);
        investment.deposit(registerProductArgs1.productId, depositAmount);
        vm.stopPrank();

        // Assert Product
        assertEq(usdt.balanceOf(address(investment)), depositAmount, "No12: balanceOf(investment) is not equal");
        Schema.Product memory afterProductForNo12 = investment.getProduct(registerProductArgs1.productId);
        assertEq(afterProductForNo12.productPool, depositAmount, "No12: productPool is not equal");

        return depositAmount;
    }

    function _fromNo13_productID2_deposit(uint256 _depositAmount) public returns (uint256) {
        // ----------------------------------------------------------
        //  No13. ProductID2: Deposit
        // ----------------------------------------------------------
        Schema.Product memory beforeProductForNo13 = investment.getProduct(registerProductArgs2.productId);
        // Total of repayment amount, profit distribution amount, and tolerance at distribution
        uint256 depositAmount2 =
            beforeProductForNo13.raisedAmount + investment.simulateTotalYield(registerProductArgs2.productId);
        usdt.mint(adminArgs.admin1, depositAmount2);

        vm.startPrank(adminArgs.admin1);
        usdt.approve(address(investment), depositAmount2);
        investment.deposit(registerProductArgs2.productId, depositAmount2);
        vm.stopPrank();

        // Assert Product
        assertEq(
            usdt.balanceOf(address(investment)),
            _depositAmount + depositAmount2,
            "No13: balanceOf(investment) is not equal"
        );
        Schema.Product memory afterProductForNo13 = investment.getProduct(registerProductArgs2.productId);
        assertEq(afterProductForNo13.productPool, depositAmount2, "No13: productPool is not equal");
    }

    function _fromNo16_productID1_performUpkeep_firstDistribution(bytes memory _performDataNo15) public {
        // ----------------------------------------------------------
        //  No16. Distribution automatic execution (ProductID1-first)
        // ----------------------------------------------------------
        // Balance before distribution
        uint256 investor1Balance = usdt.balanceOf(investorArgs1.investor1);
        uint256 investor2Balance = usdt.balanceOf(investorArgs1.investor2);
        uint256 investmentBalance = usdt.balanceOf(address(investment));

        Schema.Product memory beforeProductForNo16 = investment.getProduct(registerProductArgs1.productId);

        uint256 periodYield = CalculateYieldLib.calculatePeriodYield(
            beforeProductForNo16.raisedAmount,
            beforeProductForNo16.expectedYield,
            beforeProductForNo16.distributionStartDate - beforeProductForNo16.operationStartDate
        );

        // Distribution amount to each investor
        uint256 investor1Yield = CalculateYieldLib.calculateIndividualPeriodYield(
            periodYield,
            IInvestmentNFT(beforeProductForNo16.nftContract).getInvestmentAmount(1),
            beforeProductForNo16.raisedAmount
        );
        uint256 investor2Yield = CalculateYieldLib.calculateIndividualPeriodYield(
            periodYield,
            IInvestmentNFT(beforeProductForNo16.nftContract).getInvestmentAmount(2),
            beforeProductForNo16.raisedAmount
        );

        vm.prank(forwarder);
        Automation(address(automation)).performUpkeep(_performDataNo15);

        // Assert Product
        Schema.Product memory afterProductForNo16 = investment.getProduct(registerProductArgs1.productId);
        assertEq(afterProductForNo16.distributedCount, 1, "No16: distributedCount is not equal");
        assertEq(
            usdt.balanceOf(investorArgs1.investor1) - investor1Balance,
            investor1Yield,
            "No16: investor1Yield is not equal"
        );
        assertEq(
            usdt.balanceOf(investorArgs1.investor2) - investor2Balance,
            investor2Yield,
            "No16: investor2Yield is not equal"
        );
        assertEq(
            beforeProductForNo16.productPool - afterProductForNo16.productPool,
            investor1Yield + investor2Yield,
            "No16: productPool is not equal"
        );
        assertEq(
            investmentBalance - usdt.balanceOf(address(investment)),
            investor1Yield + investor2Yield,
            "No12: productPool is not equal"
        );
    }

    function _fromNo17_productID1_rePerformUpkeep_firstDistribution(bytes memory _performDataNo15) public {
        // ----------------------------------------------------------
        //  No17. Distribution automatic reexecution (ProductID1-first)
        // ----------------------------------------------------------
        vm.prank(forwarder);
        vm.expectRevert(IInvestmentErrors.BeforeDistributionStartDate.selector);
        Automation(address(automation)).performUpkeep(_performDataNo15);
    }

    function _fromNo21_productID2_performUpkeep_firstDistribution(bytes memory _performDataNo20) public {
        // ----------------------------------------------------------
        //  No21. Distribution automatic execution (ProductID2-first)
        // ----------------------------------------------------------
        // Balance before distribution
        uint256 investor1Balance = usdt.balanceOf(investorArgs2.investor1);
        uint256 investor2Balance = usdt.balanceOf(investorArgs2.investor2);
        uint256 investmentBalance = usdt.balanceOf(address(investment));

        Schema.Product memory beforeProductForNo21 = investment.getProduct(registerProductArgs2.productId);

        uint256 periodYield = CalculateYieldLib.calculatePeriodYield(
            beforeProductForNo21.raisedAmount,
            beforeProductForNo21.expectedYield,
            beforeProductForNo21.distributionStartDate - beforeProductForNo21.operationStartDate
        );

        // Distribution amount to each investor
        uint256 investor1Yield = CalculateYieldLib.calculateIndividualPeriodYield(
            periodYield,
            IInvestmentNFT(beforeProductForNo21.nftContract).getInvestmentAmount(1),
            beforeProductForNo21.raisedAmount
        );
        uint256 investor2Yield = CalculateYieldLib.calculateIndividualPeriodYield(
            periodYield,
            IInvestmentNFT(beforeProductForNo21.nftContract).getInvestmentAmount(2),
            beforeProductForNo21.raisedAmount
        );

        vm.prank(forwarder);
        Automation(address(automation)).performUpkeep(_performDataNo20);

        // Assert Product
        Schema.Product memory afterProductForNo21 = investment.getProduct(registerProductArgs2.productId);
        assertEq(afterProductForNo21.distributedCount, 1, "No21: distributedCount is not equal");
        assertEq(
            usdt.balanceOf(investorArgs2.investor1) - investor1Balance,
            investor1Yield,
            "No21: investor1Yield is not equal"
        );
        assertEq(
            usdt.balanceOf(investorArgs2.investor2) - investor2Balance,
            investor2Yield,
            "No21: investor2Yield is not equal"
        );
        assertEq(
            beforeProductForNo21.productPool - afterProductForNo21.productPool,
            investor1Yield + investor2Yield,
            "No21: productPool is not equal"
        );
        assertEq(
            investmentBalance - usdt.balanceOf(address(investment)),
            investor1Yield + investor2Yield,
            "No21: productPool is not equal"
        );
    }

    function _fromNo23_productID1_transferNFT() public {
        // ----------------------------------------------------------
        //  No23. ProductID2: transfer ownership of NFT
        // ----------------------------------------------------------
        Schema.Product memory productForNo23 = investment.getProduct(registerProductArgs1.productId);
        vm.prank(investorArgs1.investor1);
        IInvestmentNFT(productForNo23.nftContract).safeTransferFrom(investorArgs1.investor1, investorArgs1.investor3, 1);

        // Assert NFT
        assertEq(
            InvestmentNFT(productForNo23.nftContract).ownerOf(1),
            investorArgs1.investor3,
            "No23: ownerOf(1) is not equal"
        );
    }

    function _fromNo26_productID1_performUpkeep_secondDistribution(bytes memory _performDataNo25) public {
        // ----------------------------------------------------------
        //  No26. Distribution automatic execution (ProductID1-second)
        // ----------------------------------------------------------
        // Balance before distribution
        uint256 investor1Balance = usdt.balanceOf(investorArgs1.investor1);
        uint256 investor2Balance = usdt.balanceOf(investorArgs1.investor2);
        uint256 investor3Balance = usdt.balanceOf(investorArgs1.investor3);
        uint256 investmentBalance = usdt.balanceOf(address(investment));

        Schema.Product memory beforeProductForNo26 = investment.getProduct(registerProductArgs1.productId);

        // Calculate period in seconds for 2nd distribution using library
        uint256 period = DistributionDateLib.calculateDistributionPeriod(
            beforeProductForNo26.distributionStartDate,
            beforeProductForNo26.distributionInterval,
            beforeProductForNo26.distributedCount, // current distributedCount for next distribution
            beforeProductForNo26.isMonthEnd
        );
        uint256 periodYield = CalculateYieldLib.calculatePeriodYield(
            beforeProductForNo26.raisedAmount, beforeProductForNo26.expectedYield, period
        );

        // Distribution amount to each investor
        uint256 investor1Yield = CalculateYieldLib.calculateIndividualPeriodYield(
            periodYield,
            IInvestmentNFT(beforeProductForNo26.nftContract).getInvestmentAmount(1),
            beforeProductForNo26.raisedAmount
        );
        uint256 investor2Yield = CalculateYieldLib.calculateIndividualPeriodYield(
            periodYield,
            IInvestmentNFT(beforeProductForNo26.nftContract).getInvestmentAmount(2),
            beforeProductForNo26.raisedAmount
        );

        vm.prank(forwarder);
        Automation(address(automation)).performUpkeep(_performDataNo25);

        // Assert Product
        Schema.Product memory afterProductForNo26 = investment.getProduct(registerProductArgs1.productId);
        assertEq(afterProductForNo26.distributedCount, 2, "No26: distributedCount is not equal");
        assertEq(investor1Balance, usdt.balanceOf(investorArgs1.investor1), "No26: investor1Balance is not equal");
        assertEq(
            usdt.balanceOf(investorArgs1.investor2) - investor2Balance,
            investor2Yield,
            "No16: investor2Yield is not equal"
        );
        assertEq(
            usdt.balanceOf(investorArgs1.investor3) - investor3Balance,
            investor1Yield,
            "No26: investor3Yield is not equal"
        );
        assertEq(
            beforeProductForNo26.productPool - afterProductForNo26.productPool,
            investor1Yield + investor2Yield,
            "No26: productPool is not equal"
        );
        assertEq(
            investmentBalance - usdt.balanceOf(address(investment)),
            investor1Yield + investor2Yield,
            "No26: productPool is not equal"
        );
    }

    function _fromNo27_productID1_rePerformUpkeep_secondDistribution(bytes memory _performDataNo25) public {
        // ----------------------------------------------------------
        //  No27. Distribution automatic reexecution (ProductID1-second)
        // ----------------------------------------------------------
        vm.prank(forwarder);
        vm.expectRevert(IInvestmentErrors.BeforeDistributionStartDate.selector);
        Automation(address(automation)).performUpkeep(_performDataNo25);
    }

    function _fromNo31_productID2_performUpkeep_secondDistribution(bytes memory _performDataNo30) public {
        // ----------------------------------------------------------
        //  No31. Distribution automatic execution (ProductID2-second)
        // ----------------------------------------------------------
        // Balance before distribution
        uint256 investor1Balance = usdt.balanceOf(investorArgs2.investor1);
        uint256 investor2Balance = usdt.balanceOf(investorArgs2.investor2);
        uint256 investmentBalance = usdt.balanceOf(address(investment));

        Schema.Product memory beforeProductForNo31 = investment.getProduct(registerProductArgs2.productId);

        // Calculate period in seconds for 2nd distribution using library
        uint256 period = DistributionDateLib.calculateDistributionPeriod(
            beforeProductForNo31.distributionStartDate,
            beforeProductForNo31.distributionInterval,
            beforeProductForNo31.distributedCount, // current distributedCount for next distribution
            beforeProductForNo31.isMonthEnd
        );
        uint256 periodYield = CalculateYieldLib.calculatePeriodYield(
            beforeProductForNo31.raisedAmount, beforeProductForNo31.expectedYield, period
        );

        // Distribution amount to each investor
        uint256 investor1Yield = CalculateYieldLib.calculateIndividualPeriodYield(
            periodYield,
            IInvestmentNFT(beforeProductForNo31.nftContract).getInvestmentAmount(1),
            beforeProductForNo31.raisedAmount
        );
        uint256 investor2Yield = CalculateYieldLib.calculateIndividualPeriodYield(
            periodYield,
            IInvestmentNFT(beforeProductForNo31.nftContract).getInvestmentAmount(2),
            beforeProductForNo31.raisedAmount
        );

        vm.prank(forwarder);
        Automation(address(automation)).performUpkeep(_performDataNo30);

        // Assert Product
        Schema.Product memory afterProductForNo31 = investment.getProduct(registerProductArgs2.productId);
        assertEq(afterProductForNo31.distributedCount, 2, "No31: distributedCount is not equal");
        assertEq(
            usdt.balanceOf(investorArgs2.investor1) - investor1Balance,
            investor1Yield,
            "No31: investor1Yield is not equal"
        );
        assertEq(
            usdt.balanceOf(investorArgs2.investor2) - investor2Balance,
            investor2Yield,
            "No31: investor2Yield is not equal"
        );
        assertEq(
            beforeProductForNo31.productPool - afterProductForNo31.productPool,
            investor1Yield + investor2Yield,
            "No31: productPool is not equal"
        );
        assertEq(
            investmentBalance - usdt.balanceOf(address(investment)),
            investor1Yield + investor2Yield,
            "No31: productPool is not equal"
        );
    }

    function _fromNo35_productID1_performUpkeep_thirdDistribution(bytes memory _performDataNo34) public {
        // ----------------------------------------------------------
        //  No35. Distribution automatic execution (ProductID1-third)
        // ----------------------------------------------------------
        // Balance before distribution
        uint256 investor2Balance = usdt.balanceOf(investorArgs1.investor2);
        uint256 investor3Balance = usdt.balanceOf(investorArgs1.investor3);
        uint256 investmentBalance = usdt.balanceOf(address(investment));

        Schema.Product memory beforeProductForNo35 = investment.getProduct(registerProductArgs1.productId);

        // Calculate period in seconds for 3rd distribution using library
        uint256 period = DistributionDateLib.calculateDistributionPeriod(
            beforeProductForNo35.distributionStartDate,
            beforeProductForNo35.distributionInterval,
            beforeProductForNo35.distributedCount, // current distributedCount for next distribution
            beforeProductForNo35.isMonthEnd
        );
        uint256 periodYield = CalculateYieldLib.calculatePeriodYield(
            beforeProductForNo35.raisedAmount, beforeProductForNo35.expectedYield, period
        );

        // Distribution amount to each investor
        uint256 investor1Yield = CalculateYieldLib.calculateIndividualPeriodYield(
            periodYield,
            IInvestmentNFT(beforeProductForNo35.nftContract).getInvestmentAmount(1),
            beforeProductForNo35.raisedAmount
        );
        uint256 investor2Yield = CalculateYieldLib.calculateIndividualPeriodYield(
            periodYield,
            IInvestmentNFT(beforeProductForNo35.nftContract).getInvestmentAmount(2),
            beforeProductForNo35.raisedAmount
        );

        vm.prank(forwarder);
        Automation(address(automation)).performUpkeep(_performDataNo34);

        // Assert Product
        Schema.Product memory afterProductForNo35 = investment.getProduct(registerProductArgs1.productId);
        assertEq(afterProductForNo35.distributedCount, 3, "No35: distributedCount is not equal");
        assertEq(
            usdt.balanceOf(investorArgs1.investor2) - investor2Balance,
            investor2Yield,
            "No35: investor2Yield is not equal"
        );
        assertEq(
            usdt.balanceOf(investorArgs1.investor3) - investor3Balance,
            investor1Yield,
            "No35: investor3Yield is not equal"
        );
        assertEq(
            beforeProductForNo35.productPool - afterProductForNo35.productPool,
            investor1Yield + investor2Yield,
            "No35: productPool is not equal"
        );
        assertEq(
            investmentBalance - usdt.balanceOf(address(investment)),
            investor1Yield + investor2Yield,
            "No35: productPool is not equal"
        );
    }

    function _fromNo36_productID1_rePerformUpkeep_thirdDistribution(bytes memory _performDataNo34) public {
        // ----------------------------------------------------------
        //  No36. Distribution automatic reexecution (ProductID1-third)
        // ----------------------------------------------------------
        vm.prank(forwarder);
        vm.expectRevert(IInvestmentErrors.DistributionCompleted.selector);
        Automation(address(automation)).performUpkeep(_performDataNo34);
    }

    function _fromNo38_productID2_performUpkeep_maturity(bytes memory _performDataNo37) public {
        // ----------------------------------------------------------
        //  No38. Maturity automatic execution (ProductID2-maturity)
        // ----------------------------------------------------------
        // Balance before distribution
        uint256 investor1Balance = usdt.balanceOf(investorArgs2.investor1);
        uint256 investor2Balance = usdt.balanceOf(investorArgs2.investor2);
        uint256 investmentBalance = usdt.balanceOf(address(investment));

        Schema.Product memory beforeProductForNo38 = investment.getProduct(registerProductArgs2.productId);
        uint256 nft1Amount = IInvestmentNFT(beforeProductForNo38.nftContract).getInvestmentAmount(1);
        uint256 nft2Amount = IInvestmentNFT(beforeProductForNo38.nftContract).getInvestmentAmount(2);

        vm.prank(forwarder);
        Automation(address(automation)).performUpkeep(_performDataNo37);

        // Assert Product
        Schema.Product memory afterProductForNo38 = investment.getProduct(registerProductArgs2.productId);
        assertEq(afterProductForNo38.isMaturity, true, "No38: isMaturity is not equal");
        assertEq(
            afterProductForNo38.maturedTokenId,
            IInvestmentNFT(afterProductForNo38.nftContract).tokenIdCounter(),
            "No38: maturedTokenId is not equal"
        );
        assertEq(
            usdt.balanceOf(investorArgs2.investor1) - investor1Balance,
            nft1Amount,
            "No38: investor1Balance is not equal"
        );
        assertEq(
            usdt.balanceOf(investorArgs2.investor2) - investor2Balance,
            nft2Amount,
            "No38: investor2Balance is not equal"
        );
        assertEq(
            beforeProductForNo38.productPool - afterProductForNo38.productPool,
            afterProductForNo38.raisedAmount,
            "No38: productPool is not equal"
        );
        assertEq(
            investmentBalance - usdt.balanceOf(address(investment)),
            afterProductForNo38.raisedAmount,
            "No38: productPool is not equal"
        );
    }

    function _fromNo42_productID1_performUpkeep_maturity(bytes memory _performDataNo41) public {
        // ----------------------------------------------------------
        //  No42. Maturity automatic execution (ProductID1-maturity)
        // ----------------------------------------------------------
        // Balance before distribution
        uint256 investor1Balance = usdt.balanceOf(investorArgs1.investor1);
        uint256 investor2Balance = usdt.balanceOf(investorArgs1.investor2);
        uint256 investor3Balance = usdt.balanceOf(investorArgs1.investor3);
        uint256 investmentBalance = usdt.balanceOf(address(investment));

        Schema.Product memory beforeProductForNo42 = investment.getProduct(registerProductArgs1.productId);
        uint256 nft1Amount = IInvestmentNFT(beforeProductForNo42.nftContract).getInvestmentAmount(1);
        uint256 nft2Amount = IInvestmentNFT(beforeProductForNo42.nftContract).getInvestmentAmount(2);

        vm.prank(forwarder);
        Automation(address(automation)).performUpkeep(_performDataNo41);

        // Assert Product
        Schema.Product memory afterProductForNo42 = investment.getProduct(registerProductArgs1.productId);
        assertEq(afterProductForNo42.isMaturity, true, "No42: isMaturity is not equal");
        assertEq(
            afterProductForNo42.maturedTokenId,
            IInvestmentNFT(afterProductForNo42.nftContract).tokenIdCounter(),
            "No42: maturedTokenId is not equal"
        );
        assertEq(usdt.balanceOf(investorArgs1.investor1), investor1Balance, "No42: investor1Balance is not equal");
        assertEq(
            usdt.balanceOf(investorArgs1.investor2) - investor2Balance,
            nft2Amount,
            "No42: investor2Balance is not equal"
        );
        assertEq(
            usdt.balanceOf(investorArgs1.investor3) - investor3Balance,
            nft1Amount,
            "No42: investor1Balance is not equal"
        );
        assertEq(
            beforeProductForNo42.productPool - afterProductForNo42.productPool,
            afterProductForNo42.raisedAmount,
            "No42: productPool is not equal"
        );
        assertEq(
            investmentBalance - usdt.balanceOf(address(investment)),
            afterProductForNo42.raisedAmount,
            "No42: productPool is not equal"
        );
    }

    function _fromNo44_systemMonitoring() public {
        // ----------------------------------------------------------
        //  No44. System monitoring (information acquisition)
        // ----------------------------------------------------------

        // ProductID1
        Schema.Product memory product1ForNo44 = investment.getProduct(registerProductArgs1.productId);
        uint256 periodTolerance =
            CalculateYieldLib.calculatePeriodTolerance(InvestmentNFT(product1ForNo44.nftContract).tokenIdCounter());
        uint256 totalTolerance = periodTolerance * product1ForNo44.totalDistributionCount;

        assertEq(product1ForNo44.productId, registerProductArgs1.productId, "No44(productID1): productId is not equal");
        assertEq(
            IInvestmentNFT(product1ForNo44.nftContract).productId(),
            registerProductArgs1.productId,
            "No44(productID1): productId is not equal"
        );
        assertEq(
            product1ForNo44.offeringAmount,
            registerProductArgs1.offeringAmount,
            "No44(productID1): offeringAmount is not equal"
        );
        assertEq(
            product1ForNo44.minInvestment,
            registerProductArgs1.minInvestment,
            "No44(productID1): minInvestment is not equal"
        );
        assertEq(
            product1ForNo44.offeringEndDate,
            registerProductArgs1.offeringEndDate,
            "No44(productID1): offeringEndDate is not equal"
        );
        assertEq(
            product1ForNo44.raisedAmount,
            investAmountArgs1.investAmount1 + investAmountArgs1.investAmount2,
            "No44(productID1): raisedAmount is not equal"
        );
        assertTrue(totalTolerance >= product1ForNo44.productPool, "No44(productID1): productPool is not true");
        assertEq(
            product1ForNo44.maturityDate,
            registerProductArgs1.maturityDate,
            "No44(productID1): maturityDate is not equal"
        );
        assertEq(
            product1ForNo44.expectedYield,
            registerProductArgs1.expectedYield,
            "No44(productID1): expectedYield is not equal"
        );
        assertEq(
            product1ForNo44.operationStartDate,
            registerProductArgs1.operationStartDate,
            "No44(productID1): operationStartDate is not equal"
        );
        assertEq(
            product1ForNo44.distributionStartDate,
            registerProductArgs1.distributionStartDate,
            "No44(productID1): distributionStartDate is not equal"
        );
        assertEq(
            product1ForNo44.totalDistributionCount,
            registerProductArgs1.totalDistributionCount,
            "No44(productID1): totalDistributionCount is not equal"
        );
        assertEq(
            product1ForNo44.distributionInterval,
            registerProductArgs1.distributionInterval,
            "No44(productID1): distributionInterval is not equal"
        );
        assertEq(
            product1ForNo44.distributedCount,
            registerProductArgs1.totalDistributionCount,
            "No44(productID1): distributedCount is not equal"
        );
        assertEq(product1ForNo44.distributedYieldPerCount, 0, "No44(productID1): distributedYieldPerCount is not equal");
        assertEq(product1ForNo44.distributedTokenId, 0, "No44(productID1): distributedTokenId is not equal");
        assertEq(
            product1ForNo44.totalReturnedAmount,
            product1ForNo44.raisedAmount,
            "No44(productID1): totalReturnedAmount is not equal"
        );
        assertEq(
            product1ForNo44.maturedTokenId,
            IInvestmentNFT(product1ForNo44.nftContract).tokenIdCounter(),
            "No44(productID1): maturedTokenId is not equal"
        );
        assertTrue(product1ForNo44.isMaturity, "No44(productID1): isMaturity is not true");
        assertFalse(product1ForNo44.isInsufficientBalance, "No44(productID1): isInsufficientBalance is not false");

        // ProductID2
        Schema.Product memory product2ForNo44 = investment.getProduct(registerProductArgs2.productId);
        uint256 periodTolerance2 =
            CalculateYieldLib.calculatePeriodTolerance(InvestmentNFT(product2ForNo44.nftContract).tokenIdCounter());
        uint256 totalTolerance2 = periodTolerance2 * product2ForNo44.totalDistributionCount;

        assertEq(product2ForNo44.productId, registerProductArgs2.productId, "No44(productID2): productId is not equal");
        assertEq(
            IInvestmentNFT(product2ForNo44.nftContract).productId(),
            registerProductArgs2.productId,
            "No44(productID2): productId is not equal"
        );
        assertEq(
            product2ForNo44.offeringAmount,
            registerProductArgs2.offeringAmount,
            "No44(productID2): offeringAmount is not equal"
        );
        assertEq(
            product2ForNo44.minInvestment,
            registerProductArgs2.minInvestment,
            "No44(productID2): minInvestment is not equal"
        );
        assertEq(
            product2ForNo44.offeringEndDate,
            registerProductArgs2.offeringEndDate,
            "No44(productID2): offeringEndDate is not equal"
        );
        assertEq(
            product2ForNo44.raisedAmount,
            investAmountArgs2.investAmount1 + investAmountArgs2.investAmount2,
            "No44(productID2): raisedAmount is not equal"
        );
        assertTrue(totalTolerance2 >= product2ForNo44.productPool, "No44(productID2): productPool is not true");
        assertEq(
            product2ForNo44.maturityDate,
            registerProductArgs2.maturityDate,
            "No44(productID2): maturityDate is not equal"
        );
        assertEq(
            product2ForNo44.expectedYield,
            registerProductArgs2.expectedYield,
            "No44(productID2): expectedYield is not equal"
        );
        assertEq(
            product2ForNo44.operationStartDate,
            registerProductArgs2.operationStartDate,
            "No44(productID2): operationStartDate is not equal"
        );
        assertEq(
            product2ForNo44.distributionStartDate,
            registerProductArgs2.distributionStartDate,
            "No44(productID2): distributionStartDate is not equal"
        );
        assertEq(
            product2ForNo44.totalDistributionCount,
            registerProductArgs2.totalDistributionCount,
            "No44(productID2): totalDistributionCount is not equal"
        );
        assertEq(
            product2ForNo44.distributionInterval,
            registerProductArgs2.distributionInterval,
            "No44(productID2): distributionInterval is not equal"
        );
        assertEq(
            product2ForNo44.distributedCount,
            registerProductArgs2.totalDistributionCount,
            "No44(productID2): distributedCount is not equal"
        );
        assertEq(product2ForNo44.distributedYieldPerCount, 0, "No44(productID2): distributedYieldPerCount is not equal");
        assertEq(product2ForNo44.distributedTokenId, 0, "No44(productID2): distributedTokenId is not equal");
        assertEq(
            product2ForNo44.totalReturnedAmount,
            product2ForNo44.raisedAmount,
            "No44(productID2): totalReturnedAmount is not equal"
        );
        assertEq(
            product2ForNo44.maturedTokenId,
            IInvestmentNFT(product2ForNo44.nftContract).tokenIdCounter(),
            "No44(productID2): maturedTokenId is not equal"
        );
        assertTrue(product2ForNo44.isMaturity, "No44(productID2): isMaturity is not true");
        assertFalse(product2ForNo44.isInsufficientBalance, "No44(productID2): isInsufficientBalance is not false");
    }

    receive() external payable {}
}
