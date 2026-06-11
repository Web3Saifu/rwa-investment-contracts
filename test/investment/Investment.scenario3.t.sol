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

contract InvestmentScenarioTest3 is MCTest {
    IInvestment public investment;
    MockInvestmentERC20 public usdt;
    Automation public automation;

    address safe;
    address admin1;
    address admin2;
    address[] admins;
    address forwarder;
    Schema.RegisterProductArgs registerProductArgs;
    Schema.RegisterProductArgs registerProductArgsTarget;
    address[] investors;

    uint256 constant TARGET_PRODUCT_ID = 1;
    uint256 constant PRODUCT_ID = 2;

    function setUp() public {
        // Generate addresses
        safe = makeAddr("safe");
        admin1 = makeAddr("admin1");
        admin2 = makeAddr("admin2");
        forwarder = makeAddr("forwarder");
        admins.push(admin1);
        for (uint256 i = 0; i < 200; i++) {
            string memory investor = string(abi.encodePacked("investor", vm.toString(i)));
            investors.push(makeAddr(investor));
        }

        // Deploy contracts
        usdt = new MockInvestmentERC20();
        vm.prank(safe);
        investment = IInvestment(InvestmentDeployer.deployInvestment(mc, admins, admins, address(usdt), safe));
        automation = new Automation(address(investment), forwarder);

        vm.prank(safe);
        investment.addAdmin(address(automation));
    }

    function test_scenario3_FourTimesDistribution() public {
        registerProductArgsTarget = Schema.RegisterProductArgs({
            productId: TARGET_PRODUCT_ID, // 1
            offeringAmount: 1_000_000_000_000, // 1,000,000 USD (1 USD = 150 JPY: 150,000,000 JPY)
            minInvestment: 250_000_000, // 250 USD (1 USD = 150 JPY: 37,500 JPY)
            offeringEndDate: 1737763200, // 2025-01-25 00:00:00 UTC
            maturityDate: 1774969200, // 2026-04-01 00:00:00 UTC
            expectedYield: 500, // 5%
            operationStartDate: 1738368000, // 2025-02-01 00:00:00 UTC
            distributionStartDate: 1748736000, // 2025-06-01 00:00:00 UTC
            totalDistributionCount: 4,
            distributionInterval: 3,
            baseTokenURI: "https://example.com/metadata/",
            requiredTier: 0
        });
        registerProductArgs = Schema.RegisterProductArgs({
            productId: PRODUCT_ID, // 2
            offeringAmount: 1_000_000_000_000, // 1,000,000 USD (1 USD = 150 JPY: 150,000,000 JPY)
            minInvestment: 250_000_000, // 250 USD (1 USD = 150 JPY: 37,500 JPY)
            offeringEndDate: 1737763200, // 2025-01-25 00:00:00 UTC
            maturityDate: 1774969200, // 2026-04-01 00:00:00 UTC
            expectedYield: 500, // 5%
            operationStartDate: 1738368000, // 2025-02-01 00:00:00 UTC
            distributionStartDate: 1748736000, // 2025-06-01 00:00:00 UTC
            totalDistributionCount: 4,
            distributionInterval: 3,
            baseTokenURI: "https://example.com/metadata/",
            requiredTier: 0
        });

        // ----------------------------------------------------------
        // No0. Set up time
        // ----------------------------------------------------------
        vm.warp(1735689600); // 2025-01-01 00:00:00 UTC

        // ----------------------------------------------------------
        // No1. Add admin by Safe
        // ----------------------------------------------------------
        vm.prank(safe);
        investment.addAdmin(admin2);
        address[] memory adminList = investment.getAdminList();
        assertEq(adminList.length, 3, "No1: adminList.length is not equal");
        assertEq(adminList[2], admin2, "No1: adminList[1] is not equal");

        // ----------------------------------------------------------
        // No2. RegisterProduct
        // ----------------------------------------------------------
        vm.startPrank(admin1);
        investment.registerProduct(registerProductArgsTarget);
        investment.registerProduct(registerProductArgs);
        vm.stopPrank();

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

        Schema.Product memory targetProductForNo2 = investment.getProduct(registerProductArgsTarget.productId);
        assertEq(targetProductForNo2.productId, registerProductArgsTarget.productId, "No2: productId is not equal");
        assertEq(
            targetProductForNo2.offeringAmount,
            registerProductArgsTarget.offeringAmount,
            "No2: offeringAmount is not equal"
        );
        assertEq(
            targetProductForNo2.minInvestment,
            registerProductArgsTarget.minInvestment,
            "No2: minInvestment is not equal"
        );
        assertEq(
            targetProductForNo2.offeringEndDate,
            registerProductArgsTarget.offeringEndDate,
            "No2: offeringEndDate is not equal"
        );
        assertEq(
            targetProductForNo2.maturityDate, registerProductArgsTarget.maturityDate, "No2: maturityDate is not equal"
        );
        assertEq(
            targetProductForNo2.expectedYield,
            registerProductArgsTarget.expectedYield,
            "No2: expectedYield is not equal"
        );
        assertEq(
            targetProductForNo2.operationStartDate,
            registerProductArgsTarget.operationStartDate,
            "No2: operationStartDate is not equal"
        );
        assertEq(
            targetProductForNo2.distributionStartDate,
            registerProductArgsTarget.distributionStartDate,
            "No2: distributionStartDate is not equal"
        ); // Same as maturity date in this scenario
        assertEq(
            targetProductForNo2.totalDistributionCount,
            registerProductArgsTarget.totalDistributionCount,
            "No2: totalDistributionCount is not equal"
        );
        assertEq(
            targetProductForNo2.distributionInterval,
            registerProductArgsTarget.distributionInterval,
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
        // Assert initial values
        assertEq(targetProductForNo2.raisedAmount, 0, "No2: raisedAmount is not equal");
        assertEq(targetProductForNo2.productPool, 0, "No2: productPool is not equal");
        assertEq(targetProductForNo2.distributedCount, 0, "No2: distributedCount is not equal");
        assertEq(targetProductForNo2.distributedYieldPerCount, 0, "No2: distributedYieldPerCount is not equal");
        assertEq(targetProductForNo2.distributedTokenId, 0, "No2: distributedTokenId is not equal");
        assertEq(targetProductForNo2.totalReturnedAmount, 0, "No2: totalReturnedAmount is not equal");
        assertEq(targetProductForNo2.maturedTokenId, 0, "No2: maturedTokenId is not equal");
        assertFalse(targetProductForNo2.isMaturity, "No2: isMaturity is not false");
        assertFalse(targetProductForNo2.isInsufficientBalance, "No2: isInsufficientBalance is not false");

        // ----------------------------------------------------------
        // No3. Invest half of offering amount (JPY)
        // ----------------------------------------------------------
        uint256 halfOfferingAmount = registerProductArgs.offeringAmount / 2;
        uint256 amountPer100 = halfOfferingAmount / 100;
        uint256 unitCount = amountPer100 / registerProductArgs.minInvestment;
        vm.startPrank(admin1);
        for (uint256 i = 0; i < 100; i++) {
            investment.mintNFT(PRODUCT_ID, unitCount, investors[i]);
        }
        for (uint256 i = 0; i < 100; i++) {
            investment.mintNFT(TARGET_PRODUCT_ID, unitCount, investors[i]);
        }
        vm.stopPrank();

        // Assert Product
        Schema.Product memory productForNo3 = investment.getProduct(PRODUCT_ID);
        Schema.Product memory targetProductForNo3 = investment.getProduct(TARGET_PRODUCT_ID);
        assertEq(productForNo3.raisedAmount, halfOfferingAmount, "No3: raisedAmount is not equal");
        assertEq(productForNo3.productPool, 0, "No3: productPool is not equal");
        assertEq(targetProductForNo3.raisedAmount, halfOfferingAmount, "No3: raisedAmount is not equal");
        assertEq(targetProductForNo3.productPool, 0, "No3: productPool is not equal");

        // Assert NFT
        for (uint256 i = 0; i < 100; i++) {
            assertEq(
                InvestmentNFT(productForNo3.nftContract).balanceOf(investors[i]),
                1,
                "No3: balanceOf(investors[i]) is not equal"
            );
        }
        assertEq(InvestmentNFT(productForNo3.nftContract).tokenIdCounter(), 100, "No3: tokenIdCounter is not equal");
        for (uint256 i = 0; i < 100; i++) {
            assertEq(
                InvestmentNFT(targetProductForNo3.nftContract).balanceOf(investors[i]),
                1,
                "No3: balanceOf(investors[i]) is not equal"
            );
        }
        assertEq(
            InvestmentNFT(targetProductForNo3.nftContract).tokenIdCounter(), 100, "No3: tokenIdCounter is not equal"
        );

        // ----------------------------------------------------------
        // No4. Invest half of offering amount (USDT)
        // ----------------------------------------------------------
        for (uint256 i = 100; i < 200; i++) {
            usdt.mint(investors[i], amountPer100);
            vm.startPrank(investors[i]);
            usdt.approve(address(investment), amountPer100);
            investment.invest(PRODUCT_ID, unitCount);
            vm.stopPrank();
        }
        for (uint256 i = 100; i < 200; i++) {
            usdt.mint(investors[i], amountPer100);
            vm.startPrank(investors[i]);
            usdt.approve(address(investment), amountPer100);
            investment.invest(TARGET_PRODUCT_ID, unitCount);
            vm.stopPrank();
        }

        // Assert Product
        Schema.Product memory productForNo4 = investment.getProduct(PRODUCT_ID);
        Schema.Product memory targetProductForNo4 = investment.getProduct(TARGET_PRODUCT_ID);
        assertEq(productForNo4.raisedAmount, registerProductArgs.offeringAmount, "No4: raisedAmount is not equal");
        assertEq(productForNo4.productPool, halfOfferingAmount, "No4: productPool is not equal");
        assertEq(targetProductForNo4.raisedAmount, registerProductArgs.offeringAmount, "No4: raisedAmount is not equal");
        assertEq(targetProductForNo4.productPool, halfOfferingAmount, "No4: productPool is not equal");

        // Assert NFT
        for (uint256 i = 100; i < 200; i++) {
            assertEq(
                InvestmentNFT(productForNo4.nftContract).balanceOf(investors[i]),
                1,
                "No4: balanceOf(investors[i]) is not equal"
            );
        }
        assertEq(InvestmentNFT(productForNo4.nftContract).tokenIdCounter(), 200, "No4: tokenIdCounter is not equal");
        for (uint256 i = 100; i < 200; i++) {
            assertEq(
                InvestmentNFT(targetProductForNo4.nftContract).balanceOf(investors[i]),
                1,
                "No4: balanceOf(investors[i]) is not equal"
            );
        }
        assertEq(
            InvestmentNFT(targetProductForNo4.nftContract).tokenIdCounter(), 200, "No4: tokenIdCounter is not equal"
        );

        // ----------------------------------------------------------
        // No5. Invest more than the amount being raised in JPY (Checking for errors)
        // ----------------------------------------------------------
        address investorNo5 = makeAddr("investorNo5");
        vm.expectRevert(IInvestmentErrors.ExceedOfferingAmount.selector);
        vm.prank(admin1);
        investment.mintNFT(TARGET_PRODUCT_ID, 1, investorNo5);

        // ----------------------------------------------------------
        // No6. Invest more than the amount being raised in USDT (Checking for errors)
        // ----------------------------------------------------------
        address investorNo6 = makeAddr("investorNo6");
        usdt.mint(investorNo6, registerProductArgs.minInvestment);

        vm.startPrank(investorNo6);
        usdt.approve(address(investment), registerProductArgs.minInvestment);
        vm.expectRevert(IInvestmentErrors.ExceedOfferingAmount.selector);
        investment.invest(TARGET_PRODUCT_ID, 1);
        vm.stopPrank();

        // ----------------------------------------------------------
        // No7. Automatic execution judgment processing (when there is no target)
        // ----------------------------------------------------------
        (bool upkeepNeededNo7, bytes memory performDataNo7) = Automation(address(automation)).checkUpkeep(abi.encode(0));

        assertFalse(upkeepNeededNo7, "No7: upkeepNeeded is not false");
        assertEq(performDataNo7.length, 0, "No7: performData is not equal");

        // ----------------------------------------------------------
        // No8. Withdraw (full amount)
        // ----------------------------------------------------------
        uint256 productPoolBalance = usdt.balanceOf(address(investment)) / 2;

        vm.startPrank(admin1);
        investment.withdraw(PRODUCT_ID, productPoolBalance);
        investment.withdraw(TARGET_PRODUCT_ID, productPoolBalance);
        vm.stopPrank();
        Schema.Product memory productForNo8 = investment.getProduct(PRODUCT_ID);
        Schema.Product memory targetProductForNo8 = investment.getProduct(TARGET_PRODUCT_ID);
        assertEq(usdt.balanceOf(address(investment)), 0, "No8: balanceOf(investment) is not equal");
        assertEq(productForNo8.productPool, 0, "No8: productPool is not equal");
        assertEq(usdt.balanceOf(address(investment)), 0, "No8: balanceOf(investment) is not equal");
        assertEq(targetProductForNo8.productPool, 0, "No8: productPool is not equal");

        // ----------------------------------------------------------
        // No9. Deposit twice the offering amount in USDT for a product other than the target
        // ----------------------------------------------------------
        uint256 beforeInvestmentBalance = usdt.balanceOf(address(investment));
        Schema.Product memory productForNo9 = investment.getProduct(PRODUCT_ID);
        uint256 depositAmount = productForNo9.offeringAmount * 2;
        usdt.mint(admin1, depositAmount);

        vm.startPrank(admin1);
        usdt.approve(address(investment), depositAmount);
        investment.deposit(PRODUCT_ID, depositAmount);
        vm.stopPrank();

        // Assert Product
        assertEq(
            usdt.balanceOf(address(investment)),
            beforeInvestmentBalance + depositAmount,
            "No9: balanceOf(investment) is not equal"
        );
        productForNo9 = investment.getProduct(PRODUCT_ID);
        assertEq(productForNo9.productPool, depositAmount, "No9: productPool is not equal");

        Schema.Product memory targetProductForNo9 = investment.getProduct(TARGET_PRODUCT_ID);
        assertEq(targetProductForNo9.productPool, 0, "No9: productPool is not equal");

        // ----------------------------------------------------------
        // No10. Advance the time to the first distribution date
        // ----------------------------------------------------------
        // Advance to 2025-06-01 00:00:00 UTC
        vm.warp(registerProductArgs.distributionStartDate);

        // ----------------------------------------------------------
        // No11. Automatic execution judgment processing (When there is Distribution)
        // ----------------------------------------------------------
        (bool upkeepNeededNo11, bytes memory performDataNo11) =
            Automation(address(automation)).checkUpkeep(abi.encode(0));
        (IAutomation.ActionType actionTypeNo11, uint256 productIdNo11) =
            abi.decode(performDataNo11, (IAutomation.ActionType, uint256));

        assertTrue(upkeepNeededNo11, "No11: upkeepNeeded is not True");
        assertEq(uint8(actionTypeNo11), uint8(IAutomation.ActionType.DistributeYield), "No11: actionType is not equal");
        assertEq(productIdNo11, TARGET_PRODUCT_ID, "No11: productId is not equal");

        // ----------------------------------------------------------
        // No12. Distribution automatic execution (Checking for errors)
        // ----------------------------------------------------------
        vm.expectEmit(true, true, true, true);
        emit IInvestmentEvents.InsufficientProductPoolForDistribution(TARGET_PRODUCT_ID);
        vm.prank(forwarder);
        Automation(address(automation)).performUpkeep(performDataNo11);

        // Assert Product
        Schema.Product memory afterProductForNo12 = investment.getProduct(TARGET_PRODUCT_ID);
        assertEq(afterProductForNo12.distributedCount, 0, "No12: distributedCount is not equal");
        assertEq(afterProductForNo12.distributedYieldPerCount, 0, "No12: distributedYieldPerCount is not equal");
        assertEq(afterProductForNo12.distributedTokenId, 0, "No12: distributedTokenId is not equal");
        assertEq(afterProductForNo12.totalReturnedAmount, 0, "No12: totalReturnedAmount is not equal");
        assertTrue(afterProductForNo12.isInsufficientBalance, "No12: isInsufficientBalance is not true");

        // ----------------------------------------------------------
        // No13. Automatic execution judgment processing (When there is Distribution)
        // ----------------------------------------------------------
        (bool upkeepNeededNo13, bytes memory performDataNo13) =
            Automation(address(automation)).checkUpkeep(abi.encode(0));
        (IAutomation.ActionType actionTypeNo13, uint256 productIdNo13) =
            abi.decode(performDataNo13, (IAutomation.ActionType, uint256));

        assertTrue(upkeepNeededNo13, "No13: upkeepNeeded is not True");
        assertEq(uint8(actionTypeNo13), uint8(IAutomation.ActionType.DistributeYield), "No13: actionType is not equal");
        assertEq(productIdNo13, PRODUCT_ID, "No13: productId is not equal");

        // ----------------------------------------------------------
        // No14. Execute yield distribution call 4 times using No13 data (performUpKeep)
        // ----------------------------------------------------------
        uint256[] memory investorBalancesNo14 = new uint256[](200);
        for (uint256 i = 0; i < investors.length; i++) {
            investorBalancesNo14[i] = usdt.balanceOf(investors[i]);
        }

        for (uint256 i = 0; i < 4; i++) {
            (bool upkeepNeededNo14, bytes memory performDataNo14) =
                Automation(address(automation)).checkUpkeep(abi.encode(0));
            (IAutomation.ActionType actionTypeNo14, uint256 productIdNo14) =
                abi.decode(performDataNo13, (IAutomation.ActionType, uint256));
            if (upkeepNeededNo14 && productIdNo14 == PRODUCT_ID) {
                vm.startPrank(forwarder);
                Automation(address(automation)).performUpkeep(performDataNo14);
                vm.stopPrank();
            } else {
                revert("No14: upkeepNeeded is not True or productId is not equal");
            }
        }

        // Assert Product
        Schema.Product memory productForNo14 = investment.getProduct(productIdNo13);
        uint256 periodYieldNo14 = CalculateYieldLib.calculatePeriodYield(
            productForNo14.raisedAmount,
            productForNo14.expectedYield,
            productForNo14.distributionStartDate - productForNo14.operationStartDate
        );
        uint256 investorYieldNo14 = CalculateYieldLib.calculateIndividualPeriodYield(
            periodYieldNo14,
            IInvestmentNFT(productForNo14.nftContract).getInvestmentAmount(1),
            productForNo14.raisedAmount
        );

        // Assert Investor Balance
        for (uint256 i = 0; i < investors.length; i++) {
            assertEq(
                usdt.balanceOf(investors[i]),
                investorBalancesNo14[i] + investorYieldNo14,
                "No14: balanceOf(investors[i]) is not equal"
            );
        }

        // Assert Product
        assertEq(productForNo14.distributedCount, 1, "No14: distributedCount is not equal");
        assertEq(productForNo14.distributedYieldPerCount, 0, "No14: distributedYieldPerCount is not equal");
        assertEq(productForNo14.distributedTokenId, 0, "No14: distributedTokenId is not equal");
        assertEq(productForNo14.totalReturnedAmount, 0, "No14: totalReturnedAmount is not equal");
        assertFalse(productForNo14.isInsufficientBalance, "No14: isInsufficientBalance is not false");

        // Assert targetProduct
        Schema.Product memory targetProductForNo14 = investment.getProduct(TARGET_PRODUCT_ID);
        assertEq(targetProductForNo14.distributedCount, 0, "No14: distributedCount is not equal");
        assertEq(targetProductForNo14.distributedYieldPerCount, 0, "No14: distributedYieldPerCount is not equal");
        assertEq(targetProductForNo14.distributedTokenId, 0, "No14: distributedTokenId is not equal");
        assertEq(targetProductForNo14.totalReturnedAmount, 0, "No14: totalReturnedAmount is not equal");
        assertTrue(targetProductForNo14.isInsufficientBalance, "No14: isInsufficientBalance is not true");

        // ----------------------------------------------------------
        // No15. Advance the time to the second distribution date
        // ----------------------------------------------------------
        (bool upkeepNeededNo15,) = Automation(address(automation)).checkUpkeep(abi.encode(0));

        assertFalse(upkeepNeededNo15, "No11: upkeepNeeded is not False");

        // ----------------------------------------------------------
        // No16. Advance the time to 1 month before the distribution interval from the first distribution date
        // ----------------------------------------------------------
        // Advance to 2025-08-01 00:00:00 UTC
        vm.warp(1753974000);

        // ----------------------------------------------------------
        // No17. Manually call the yield distribution process for the target product
        // ----------------------------------------------------------
        vm.expectEmit(true, true, true, true);
        emit IInvestmentEvents.InsufficientProductPoolForDistribution(TARGET_PRODUCT_ID);
        vm.prank(forwarder);
        Automation(address(automation)).performUpkeep(performDataNo11);

        // Assert Product
        Schema.Product memory afterProductForNo17 = investment.getProduct(TARGET_PRODUCT_ID);
        assertEq(afterProductForNo17.distributedCount, 0, "No17: distributedCount is not equal");
        assertEq(afterProductForNo17.distributedYieldPerCount, 0, "No17: distributedYieldPerCount is not equal");
        assertEq(afterProductForNo17.distributedTokenId, 0, "No17: distributedTokenId is not equal");
        assertEq(afterProductForNo17.totalReturnedAmount, 0, "No17: totalReturnedAmount is not equal");
        assertTrue(afterProductForNo17.isInsufficientBalance, "No17: isInsufficientBalance is not true");

        // ----------------------------------------------------------
        // No18. Deposit for the target product an amount equal to the offering amount plus the simulated yield
        // ----------------------------------------------------------
        uint256 beforeInvestmentBalanceNo18 = usdt.balanceOf(address(investment));
        uint256 beforePoolBalanceNo18 = investment.getProduct(TARGET_PRODUCT_ID).productPool;
        Schema.Product memory productForNo18 = investment.getProduct(TARGET_PRODUCT_ID);
        uint256 depositAmountNo18 = productForNo18.offeringAmount + investment.simulateTotalYield(TARGET_PRODUCT_ID);
        usdt.mint(admin1, depositAmountNo18);

        vm.startPrank(admin1);
        usdt.approve(address(investment), depositAmountNo18);
        investment.deposit(TARGET_PRODUCT_ID, depositAmountNo18);
        vm.stopPrank();

        // Assert Product
        assertEq(
            usdt.balanceOf(address(investment)),
            beforeInvestmentBalanceNo18 + depositAmountNo18,
            "No18: balanceOf(investment) is not equal"
        );
        productForNo18 = investment.getProduct(TARGET_PRODUCT_ID);
        assertEq(
            productForNo18.productPool, beforePoolBalanceNo18 + depositAmountNo18, "No18: productPool is not equal"
        );

        // ----------------------------------------------------------
        // No19. Manually call the yield distribution process for the target product (once)
        // ----------------------------------------------------------
        uint256[] memory investorBalancesNo19 = new uint256[](50);
        for (uint256 i = 0; i < investorBalancesNo19.length; i++) {
            investorBalancesNo19[i] = usdt.balanceOf(investors[i]);
        }

        vm.startPrank(admin1);
        investment.distributeYield(TARGET_PRODUCT_ID);
        vm.stopPrank();

        // Assert Product
        Schema.Product memory afterProductForNo19 = investment.getProduct(TARGET_PRODUCT_ID);
        assertEq(afterProductForNo19.distributedCount, 0, "No19: distributedCount is not equal");
        assertNotEq(afterProductForNo19.distributedYieldPerCount, 0, "No19: distributedYieldPerCount is not equal");
        assertEq(afterProductForNo19.distributedTokenId, 50, "No19: distributedTokenId is not equal");

        uint256 periodYieldNo19 = CalculateYieldLib.calculatePeriodYield(
            afterProductForNo19.raisedAmount,
            afterProductForNo19.expectedYield,
            afterProductForNo19.distributionStartDate - afterProductForNo19.operationStartDate
        );
        uint256 investorYieldNo19 = CalculateYieldLib.calculateIndividualPeriodYield(
            periodYieldNo19,
            IInvestmentNFT(afterProductForNo19.nftContract).getInvestmentAmount(1),
            afterProductForNo19.raisedAmount
        );
        for (uint256 i = 0; i < investorBalancesNo19.length; i++) {
            assertEq(
                usdt.balanceOf(investors[i]),
                investorBalancesNo19[i] + investorYieldNo19,
                "No19: balanceOf(investors[i]) is not equal"
            );
        }

        // ----------------------------------------------------------
        // No20. Automatic execution judgment processing (when there is target)
        // ----------------------------------------------------------
        (bool upkeepNeededNo20, bytes memory performDataNo20) =
            Automation(address(automation)).checkUpkeep(abi.encode(0));
        (IAutomation.ActionType actionTypeNo20, uint256 productIdNo20) =
            abi.decode(performDataNo20, (IAutomation.ActionType, uint256));

        // Assert
        assertTrue(upkeepNeededNo20, "No20: upkeepNeeded is not True");
        assertEq(uint8(actionTypeNo20), uint8(IAutomation.ActionType.DistributeYield), "No20: actionType is not equal");
        assertEq(productIdNo20, TARGET_PRODUCT_ID, "No20: productId is not equal");

        // ----------------------------------------------------------
        // No21. Automatic execution judgment processing (when there is target) 3 times
        // ----------------------------------------------------------
        uint256[] memory investorBalancesNo21 = new uint256[](200);
        for (uint256 i = 0; i < investors.length; i++) {
            investorBalancesNo21[i] = usdt.balanceOf(investors[i]);
        }
        for (uint256 i = 0; i < 3; i++) {
            (bool upkeepNeededNo21, bytes memory performDataNo21) =
                Automation(address(automation)).checkUpkeep(abi.encode(0));
            (IAutomation.ActionType actionTypeNo21, uint256 productIdNo21) =
                abi.decode(performDataNo21, (IAutomation.ActionType, uint256));
            if (upkeepNeededNo21 && productIdNo21 == TARGET_PRODUCT_ID) {
                vm.startPrank(forwarder);
                Automation(address(automation)).performUpkeep(performDataNo21);
                vm.stopPrank();
            } else {
                revert("No21: upkeepNeeded is not True or productId is not equal");
            }
        }

        // Assert Product
        Schema.Product memory afterProductForNo21 = investment.getProduct(TARGET_PRODUCT_ID);
        assertEq(afterProductForNo21.distributedCount, 1, "No21: distributedCount is not equal");
        assertEq(afterProductForNo21.distributedYieldPerCount, 0, "No21: distributedYieldPerCount is not equal");
        assertEq(afterProductForNo21.distributedTokenId, 0, "No21: distributedTokenId is not equal");
        for (uint256 i = 50; i < 200; i++) {
            assertEq(
                usdt.balanceOf(investors[i]),
                investorBalancesNo21[i] + investorYieldNo19,
                "No21: balanceOf(investors[i]) is not equal"
            );
        }

        // ----------------------------------------------------------
        // No22. Advance the time to 1 month
        // ----------------------------------------------------------
        // Advance to 2025-09-01 00:00:00 UTC
        vm.warp(1756684800);

        // ----------------------------------------------------------
        // No23. Automatic execution judgment processing (when there is target)
        // ----------------------------------------------------------
        (bool upkeepNeededNo23, bytes memory performDataNo23) =
            Automation(address(automation)).checkUpkeep(abi.encode(0));
        (IAutomation.ActionType actionTypeNo23, uint256 productIdNo23) =
            abi.decode(performDataNo23, (IAutomation.ActionType, uint256));

        // Assert
        assertTrue(upkeepNeededNo23, "No23: upkeepNeeded is not True");
        assertEq(uint8(actionTypeNo23), uint8(IAutomation.ActionType.DistributeYield), "No23: actionType is not equal");
        assertEq(productIdNo23, TARGET_PRODUCT_ID, "No23: productId is not equal");

        // ----------------------------------------------------------
        // No24. Automatic execution judgment processing 8 times
        // ----------------------------------------------------------
        uint256[] memory investorBalancesNo24 = new uint256[](200);
        for (uint256 i = 0; i < investors.length; i++) {
            investorBalancesNo24[i] = usdt.balanceOf(investors[i]);
        }

        // target product
        for (uint256 i = 0; i < 8; i++) {
            (bool upkeepNeededNo24, bytes memory performDataNo24) =
                Automation(address(automation)).checkUpkeep(abi.encode(0));
            (IAutomation.ActionType actionTypeNo24, uint256 productIdNo24) =
                abi.decode(performDataNo24, (IAutomation.ActionType, uint256));
            if (upkeepNeededNo24) {
                vm.startPrank(forwarder);
                Automation(address(automation)).performUpkeep(performDataNo24);
                vm.stopPrank();
            } else {
                revert("No24: upkeepNeeded is not True");
            }
        }

        // Assert Product
        Schema.Product memory afterTargetProductForNo24 = investment.getProduct(TARGET_PRODUCT_ID);
        assertEq(
            afterTargetProductForNo24.distributedCount, 2, "No24: distributedCount is not equal for target product"
        );
        assertEq(
            afterTargetProductForNo24.distributedYieldPerCount,
            0,
            "No24: distributedYieldPerCount is not equal for target product"
        );
        assertEq(
            afterTargetProductForNo24.distributedTokenId, 0, "No24: distributedTokenId is not equal for target product"
        );

        Schema.Product memory afterProductForNo24 = investment.getProduct(PRODUCT_ID);
        assertEq(afterProductForNo24.distributedCount, 2, "No24: distributedCount is not equal");
        assertEq(afterProductForNo24.distributedYieldPerCount, 0, "No24: distributedYieldPerCount is not equal");
        assertEq(afterProductForNo24.distributedTokenId, 0, "No24: distributedTokenId is not equal");

        // Calculate period in seconds for 2nd distribution using library
        uint256 periodNo24 = DistributionDateLib.calculateDistributionPeriod(
            afterProductForNo24.distributionStartDate,
            afterProductForNo24.distributionInterval,
            afterProductForNo24.distributedCount - 1,
            afterProductForNo24.isMonthEnd
        );
        uint256 periodYieldNo24 = CalculateYieldLib.calculatePeriodYield(
            afterProductForNo24.raisedAmount, afterProductForNo24.expectedYield, periodNo24
        );
        uint256 investorYieldNo24 = CalculateYieldLib.calculateIndividualPeriodYield(
            periodYieldNo24,
            IInvestmentNFT(afterProductForNo24.nftContract).getInvestmentAmount(1),
            afterProductForNo24.raisedAmount
        );
        for (uint256 i = 0; i < investors.length; i++) {
            assertEq(
                usdt.balanceOf(investors[i]),
                investorBalancesNo24[i] + (investorYieldNo24 * 2),
                "No24: balanceOf(investors[i]) is not equal"
            );
        }

        // ----------------------------------------------------------
        // No25. Advance the time by the distribution interval
        // ----------------------------------------------------------
        // Advance to 2025-12-01 00:00:00 UTC
        vm.warp(1764547200);

        // ----------------------------------------------------------
        // No26. Automatic execution judgment processing (when there is target)
        // ----------------------------------------------------------
        (bool upkeepNeededNo26, bytes memory performDataNo26) =
            Automation(address(automation)).checkUpkeep(abi.encode(0));
        (IAutomation.ActionType actionTypeNo26, uint256 productIdNo26) =
            abi.decode(performDataNo26, (IAutomation.ActionType, uint256));

        // Assert
        assertTrue(upkeepNeededNo26, "No26: upkeepNeeded is not True");
        assertEq(uint8(actionTypeNo26), uint8(IAutomation.ActionType.DistributeYield), "No26: actionType is not equal");
        assertEq(productIdNo26, TARGET_PRODUCT_ID, "No26: productId is not equal");

        // ----------------------------------------------------------
        // No27. Automatic execution judgment processing (when there is target) 8 times
        // ----------------------------------------------------------
        uint256[] memory investorBalancesNo27 = new uint256[](200);
        for (uint256 i = 0; i < investors.length; i++) {
            investorBalancesNo27[i] = usdt.balanceOf(investors[i]);
        }

        Schema.Product memory targetProductForNo27 = investment.getProduct(TARGET_PRODUCT_ID);
        // Calculate period in seconds for 3rd distribution using library
        uint256 periodNo27 = DistributionDateLib.calculateDistributionPeriod(
            targetProductForNo27.distributionStartDate,
            targetProductForNo27.distributionInterval,
            targetProductForNo27.distributedCount, // distributedCount = 2 (before 3rd distribution)
            targetProductForNo27.isMonthEnd
        );
        uint256 periodYieldNo27 = CalculateYieldLib.calculatePeriodYield(
            targetProductForNo27.raisedAmount, targetProductForNo27.expectedYield, periodNo27
        );
        uint256 investorYieldNo27 = CalculateYieldLib.calculateIndividualPeriodYield(
            periodYieldNo27,
            IInvestmentNFT(targetProductForNo27.nftContract).getInvestmentAmount(1),
            targetProductForNo27.raisedAmount
        );

        for (uint256 i = 0; i < 8; i++) {
            (bool upkeepNeededNo27, bytes memory performDataNo27) =
                Automation(address(automation)).checkUpkeep(abi.encode(0));
            (IAutomation.ActionType actionTypeNo27, uint256 productIdNo27) =
                abi.decode(performDataNo27, (IAutomation.ActionType, uint256));
            if (upkeepNeededNo27) {
                vm.startPrank(forwarder);
                Automation(address(automation)).performUpkeep(performDataNo27);
                vm.stopPrank();
            } else {
                revert("No27: upkeepNeeded is not True");
            }
        }

        // Assert Product
        Schema.Product memory afterTargetProductForNo27 = investment.getProduct(TARGET_PRODUCT_ID);
        assertEq(
            afterTargetProductForNo27.distributedCount, 3, "No27: distributedCount is not equal for target product"
        );
        assertEq(
            afterTargetProductForNo27.distributedYieldPerCount,
            0,
            "No27: distributedYieldPerCount is not equal for target product"
        );
        assertEq(
            afterTargetProductForNo27.distributedTokenId, 0, "No27: distributedTokenId is not equal for target product"
        );

        Schema.Product memory afterProductForNo27 = investment.getProduct(PRODUCT_ID);
        assertEq(afterProductForNo27.distributedCount, 3, "No27: distributedCount is not equal");
        assertEq(afterProductForNo27.distributedYieldPerCount, 0, "No27: distributedYieldPerCount is not equal");
        assertEq(afterProductForNo27.distributedTokenId, 0, "No27: distributedTokenId is not equal");

        for (uint256 i = 0; i < investors.length; i++) {
            assertEq(
                usdt.balanceOf(investors[i]),
                investorBalancesNo27[i] + (investorYieldNo27 * 2),
                "No27: balanceOf(investors[i]) is not equal"
            );
        }

        // ----------------------------------------------------------
        // No28. Advance the time by the distribution interval
        // ----------------------------------------------------------
        // Advance to 2026-03-01 00:00:00 UTC
        vm.warp(1772323200);

        // ----------------------------------------------------------
        // No29. Automatic execution judgment processing (when there is target)
        // ----------------------------------------------------------
        (bool upkeepNeededNo29, bytes memory performDataNo29) =
            Automation(address(automation)).checkUpkeep(abi.encode(0));
        (IAutomation.ActionType actionTypeNo29, uint256 productIdNo29) =
            abi.decode(performDataNo29, (IAutomation.ActionType, uint256));

        // Assert
        assertTrue(upkeepNeededNo29, "No29: upkeepNeeded is not True");
        assertEq(uint8(actionTypeNo29), uint8(IAutomation.ActionType.DistributeYield), "No29: actionType is not equal");
        assertEq(productIdNo29, TARGET_PRODUCT_ID, "No29: productId is not equal");

        // ----------------------------------------------------------
        // No30. Automatic execution judgment processing (when there is target) 4 times
        // ----------------------------------------------------------
        uint256[] memory investorBalancesNo30 = new uint256[](200);
        for (uint256 i = 0; i < investors.length; i++) {
            investorBalancesNo30[i] = usdt.balanceOf(investors[i]);
        }

        for (uint256 i = 0; i < 8; i++) {
            (bool upkeepNeededNo30, bytes memory performDataNo30) =
                Automation(address(automation)).checkUpkeep(abi.encode(0));
            (IAutomation.ActionType actionTypeNo30, uint256 productIdNo30) =
                abi.decode(performDataNo30, (IAutomation.ActionType, uint256));
            if (upkeepNeededNo30) {
                vm.startPrank(forwarder);
                Automation(address(automation)).performUpkeep(performDataNo30);
                vm.stopPrank();
            } else {
                revert("No30: upkeepNeeded is not True");
            }
        }

        // Assert Product
        Schema.Product memory afterTargetProductForNo30 = investment.getProduct(TARGET_PRODUCT_ID);
        assertEq(
            afterTargetProductForNo30.distributedCount, 4, "No30: distributedCount is not equal for target product"
        );
        assertEq(
            afterTargetProductForNo30.distributedYieldPerCount,
            0,
            "No30: distributedYieldPerCount is not equal for target product"
        );
        assertEq(
            afterTargetProductForNo30.distributedTokenId, 0, "No30: distributedTokenId is not equal for target product"
        );
        Schema.Product memory afterProductForNo30 = investment.getProduct(PRODUCT_ID);
        assertEq(afterProductForNo30.distributedCount, 4, "No30: distributedCount is not equal");
        assertEq(afterProductForNo30.distributedYieldPerCount, 0, "No30: distributedYieldPerCount is not equal");
        assertEq(afterProductForNo30.distributedTokenId, 0, "No30: distributedTokenId is not equal");

        // Note: distributedCount = 4 means all distributions are completed
        // This calculation is for the last distribution period (4th distribution)
        // Calculate period in seconds for 4th distribution using library
        // Use distributedCount = 3 (before 4th distribution) to calculate the 4th distribution period
        uint256 periodNo30 = DistributionDateLib.calculateDistributionPeriod(
            afterProductForNo30.distributionStartDate,
            afterProductForNo30.distributionInterval,
            3, // distributedCount = 3 for 4th distribution (before 4th distribution was done)
            afterProductForNo30.isMonthEnd
        );
        uint256 periodYieldNo30 = CalculateYieldLib.calculatePeriodYield(
            afterProductForNo30.raisedAmount, afterProductForNo30.expectedYield, periodNo30
        );
        uint256 investorYieldNo30 = CalculateYieldLib.calculateIndividualPeriodYield(
            periodYieldNo30,
            IInvestmentNFT(afterProductForNo30.nftContract).getInvestmentAmount(1),
            afterProductForNo30.raisedAmount
        );
        for (uint256 i = 0; i < investors.length; i++) {
            assertEq(
                usdt.balanceOf(investors[i]),
                investorBalancesNo30[i] + (investorYieldNo30 * 2),
                "No30: balanceOf(investors[i]) is not equal"
            );
        }

        // ----------------------------------------------------------
        // No31. Automatic execution judgment processing (when there is nontarget)
        // ----------------------------------------------------------
        (bool upkeepNeededNo31, bytes memory performDataNo31) =
            Automation(address(automation)).checkUpkeep(abi.encode(0));

        // Assert
        assertFalse(upkeepNeededNo31, "No31: upkeepNeeded is not True");
        assertEq(performDataNo31, "", "No31: performData is not equal");

        // ----------------------------------------------------------
        // No32. Advance the time to the maturity date
        // ----------------------------------------------------------
        // Advance to 2026-04-01 00:00:00 UTC
        vm.warp(1775001600);

        // ----------------------------------------------------------
        // No33. Admin withdrawal (full amount)
        // ----------------------------------------------------------
        uint256 beforeSafeBalance = usdt.balanceOf(safe);
        uint256 beforeInvestmentBalanceNo33 = usdt.balanceOf(address(investment));
        uint256 beforePoolBalanceNo33 = investment.getProduct(TARGET_PRODUCT_ID).productPool;
        Schema.Product memory productForNo33 = investment.getProduct(TARGET_PRODUCT_ID);
        uint256 withdrawAmountNo33 = productForNo33.productPool;
        vm.startPrank(admin2);
        investment.withdraw(TARGET_PRODUCT_ID, withdrawAmountNo33);
        vm.stopPrank();

        // Assert
        assertEq(
            usdt.balanceOf(address(investment)),
            beforeInvestmentBalanceNo33 - withdrawAmountNo33,
            "No33: balanceOf(investment) is not equal"
        );
        productForNo33 = investment.getProduct(TARGET_PRODUCT_ID);
        assertEq(
            productForNo33.productPool, beforePoolBalanceNo33 - withdrawAmountNo33, "No33: productPool is not equal"
        );
        assertEq(productForNo33.productPool, 0, "No33: productPoolBalance is not equal");
        assertEq(usdt.balanceOf(safe), beforeSafeBalance + withdrawAmountNo33, "No33: balanceOf(safe) is not equal");

        // ----------------------------------------------------------
        // No34. Automatic execution judgment processing (when there is target)
        // ----------------------------------------------------------
        (bool upkeepNeededNo34, bytes memory performDataNo34) =
            Automation(address(automation)).checkUpkeep(abi.encode(0));
        (IAutomation.ActionType actionTypeNo34, uint256 productIdNo34) =
            abi.decode(performDataNo34, (IAutomation.ActionType, uint256));

        // Assert
        assertTrue(upkeepNeededNo34, "No34: upkeepNeeded is not True");
        assertEq(uint8(actionTypeNo34), uint8(IAutomation.ActionType.Maturity), "No34: actionType is not equal");
        assertEq(productIdNo34, TARGET_PRODUCT_ID, "No34: productId is not equal");

        // ----------------------------------------------------------
        // No35. Automatic execution judgment processing (when there is target) error
        // ----------------------------------------------------------
        vm.expectEmit(true, true, true, true);
        emit IInvestmentEvents.InsufficientProductPoolForMaturity(TARGET_PRODUCT_ID);
        vm.startPrank(forwarder);
        Automation(address(automation)).performUpkeep(performDataNo34);
        vm.stopPrank();

        // Assert Product
        Schema.Product memory afterProductForNo35 = investment.getProduct(TARGET_PRODUCT_ID);
        assertEq(afterProductForNo35.maturedTokenId, 0, "No35: maturedTokenId is not equal");
        assertFalse(afterProductForNo35.isMaturity, "No35: isMaturity is not false");
        assertTrue(afterProductForNo35.isInsufficientBalance, "No35: isInsufficientBalance is not true");

        // ----------------------------------------------------------
        // No36. Automatic execution judgment processing (when there is target)
        // ----------------------------------------------------------
        (bool upkeepNeededNo36, bytes memory performDataNo36) =
            Automation(address(automation)).checkUpkeep(abi.encode(0));
        (IAutomation.ActionType actionTypeNo36, uint256 productIdNo36) =
            abi.decode(performDataNo36, (IAutomation.ActionType, uint256));

        // Assert
        assertTrue(upkeepNeededNo36, "No36: upkeepNeeded is not True");
        assertEq(uint8(actionTypeNo36), uint8(IAutomation.ActionType.Maturity), "No36: actionType is not equal");
        assertEq(productIdNo36, PRODUCT_ID, "No36: productId is not equal");

        // ----------------------------------------------------------
        // No37. Manually call the maturity process for the target product (once)
        // ----------------------------------------------------------
        vm.expectEmit(true, true, true, true);
        emit IInvestmentEvents.InsufficientProductPoolForMaturity(TARGET_PRODUCT_ID);
        vm.startPrank(admin2);
        investment.maturity(TARGET_PRODUCT_ID);
        vm.stopPrank();

        // Assert Product
        Schema.Product memory afterProductForNo37 = investment.getProduct(TARGET_PRODUCT_ID);
        assertEq(afterProductForNo37.maturedTokenId, 0, "No37: maturedTokenId is not equal");
        assertFalse(afterProductForNo37.isMaturity, "No37: isMaturity is not false");
        assertTrue(afterProductForNo37.isInsufficientBalance, "No37: isInsufficientBalance is not true");

        // ----------------------------------------------------------
        // No38. Admin deposit (for the offering amount)
        // ----------------------------------------------------------
        uint256 beforeInvestmentBalanceNo38 = usdt.balanceOf(address(investment));
        uint256 beforePoolBalanceNo38 = investment.getProduct(TARGET_PRODUCT_ID).productPool;
        Schema.Product memory productForNo38 = investment.getProduct(TARGET_PRODUCT_ID);
        usdt.mint(admin2, productForNo38.offeringAmount);

        vm.startPrank(admin2);
        usdt.approve(address(investment), productForNo38.offeringAmount);
        investment.deposit(TARGET_PRODUCT_ID, productForNo38.offeringAmount);
        vm.stopPrank();

        // Assert
        assertEq(
            usdt.balanceOf(address(investment)),
            beforeInvestmentBalanceNo38 + productForNo38.offeringAmount,
            "No38: balanceOf(investment) is not equal"
        );
        productForNo38 = investment.getProduct(TARGET_PRODUCT_ID);
        assertEq(
            productForNo38.productPool,
            beforePoolBalanceNo38 + productForNo38.offeringAmount,
            "No38: productPool is not equal"
        );

        // ----------------------------------------------------------
        // No39. Manually call the yield distribution process for the target product
        // ----------------------------------------------------------
        uint256[] memory investorBalancesNo39 = new uint256[](50);
        for (uint256 i = 0; i < investorBalancesNo39.length; i++) {
            investorBalancesNo39[i] = usdt.balanceOf(investors[i]);
        }

        // The amount to be redeemed per investor
        uint256 returnedAmountNo39 =
            InvestmentNFT(investment.getProduct(TARGET_PRODUCT_ID).nftContract).getInvestmentAmount(1);

        vm.startPrank(admin2);
        investment.maturity(TARGET_PRODUCT_ID);
        vm.stopPrank();

        // Assert Product
        Schema.Product memory afterProductForNo39 = investment.getProduct(TARGET_PRODUCT_ID);
        assertEq(afterProductForNo39.maturedTokenId, 50, "No39: maturedTokenId is not equal");
        assertFalse(afterProductForNo39.isMaturity, "No39: isMaturity is not false");
        assertFalse(afterProductForNo39.isInsufficientBalance, "No39: isInsufficientBalance is not false");

        for (uint256 i = 0; i < investorBalancesNo39.length; i++) {
            assertEq(
                usdt.balanceOf(investors[i]),
                investorBalancesNo39[i] + returnedAmountNo39,
                "No39: balanceOf(investors[i]) is not equal"
            );
        }

        // ----------------------------------------------------------
        // No40. Automatic execution judgment processing (when there is target)
        // ----------------------------------------------------------
        (bool upkeepNeededNo40, bytes memory performDataNo40) =
            Automation(address(automation)).checkUpkeep(abi.encode(0));
        (IAutomation.ActionType actionTypeNo40, uint256 productIdNo40) =
            abi.decode(performDataNo40, (IAutomation.ActionType, uint256));

        // Assert
        assertTrue(upkeepNeededNo40, "No40: upkeepNeeded is not True");
        assertEq(uint8(actionTypeNo40), uint8(IAutomation.ActionType.Maturity), "No40: actionType is not equal");
        assertEq(productIdNo40, TARGET_PRODUCT_ID, "No40: productId is not equal");

        // ----------------------------------------------------------
        // No41. Automatic execution judgment processing (when there is target) 3 times
        // ----------------------------------------------------------
        uint256[] memory investorBalancesNo41 = new uint256[](200);
        for (uint256 i = 0; i < investors.length; i++) {
            investorBalancesNo41[i] = usdt.balanceOf(investors[i]);
        }

        // The amount to be redeemed per investor (for tokenId starting from 51)
        uint256 returnedAmountNo41 =
            InvestmentNFT(investment.getProduct(TARGET_PRODUCT_ID).nftContract).getInvestmentAmount(51);

        for (uint256 i = 0; i < 3; i++) {
            (bool upkeepNeededNo41, bytes memory performDataNo41) =
                Automation(address(automation)).checkUpkeep(abi.encode(0));
            (IAutomation.ActionType actionTypeNo41, uint256 productIdNo41) =
                abi.decode(performDataNo41, (IAutomation.ActionType, uint256));
            if (upkeepNeededNo41 && productIdNo41 == TARGET_PRODUCT_ID) {
                vm.startPrank(forwarder);
                Automation(address(automation)).performUpkeep(performDataNo41);
                vm.stopPrank();
            } else {
                revert("No41: upkeepNeeded is not True or productId is not equal");
            }
        }

        // Assert Product
        Schema.Product memory afterProductForNo41 = investment.getProduct(TARGET_PRODUCT_ID);
        assertEq(
            afterProductForNo41.totalReturnedAmount,
            afterProductForNo41.offeringAmount,
            "No41: totalReturnedAmount is not equal"
        );
        assertEq(afterProductForNo41.maturedTokenId, 200, "No41: maturedTokenId is not equal");
        assertTrue(afterProductForNo41.isMaturity, "No41: isMaturity is not true");
        assertFalse(afterProductForNo41.isInsufficientBalance, "No41: isInsufficientBalance is not false");

        for (uint256 i = 50; i < investorBalancesNo41.length; i++) {
            assertEq(
                usdt.balanceOf(investors[i]),
                investorBalancesNo41[i] + returnedAmountNo41,
                "No41: balanceOf(investors[i]) is not equal"
            );
        }

        // ----------------------------------------------------------
        // No42. Automatic execution judgment processing (when there is no target) 4 times
        // ----------------------------------------------------------
        uint256[] memory investorBalancesNo42 = new uint256[](200);
        for (uint256 i = 0; i < investors.length; i++) {
            investorBalancesNo42[i] = usdt.balanceOf(investors[i]);
        }

        // The amount to be redeemed per investor (for tokenId starting from 51)
        uint256 returnedAmountNo42 =
            InvestmentNFT(investment.getProduct(PRODUCT_ID).nftContract).getInvestmentAmount(51);

        for (uint256 i = 0; i < 4; i++) {
            (bool upkeepNeededNo42, bytes memory performDataNo42) =
                Automation(address(automation)).checkUpkeep(abi.encode(0));
            (IAutomation.ActionType actionTypeNo42, uint256 productIdNo42) =
                abi.decode(performDataNo42, (IAutomation.ActionType, uint256));
            if (upkeepNeededNo42 && productIdNo42 == PRODUCT_ID) {
                vm.startPrank(forwarder);
                Automation(address(automation)).performUpkeep(performDataNo42);
                vm.stopPrank();
            } else {
                revert("No42: upkeepNeeded is not True or productId is not equal");
            }
        }

        // Assert Product
        Schema.Product memory afterProductForNo42 = investment.getProduct(PRODUCT_ID);
        assertEq(
            afterProductForNo42.totalReturnedAmount,
            afterProductForNo42.offeringAmount,
            "No42: totalReturnedAmount is not equal"
        );
        assertEq(afterProductForNo42.maturedTokenId, 200, "No42: maturedTokenId is not equal");
        assertTrue(afterProductForNo42.isMaturity, "No42: isMaturity is not true");
        assertFalse(afterProductForNo42.isInsufficientBalance, "No42: isInsufficientBalance is not false");

        for (uint256 i = 0; i < investorBalancesNo42.length; i++) {
            assertEq(
                usdt.balanceOf(investors[i]),
                investorBalancesNo42[i] + returnedAmountNo42,
                "No42: balanceOf(investors[i]) is not equal"
            );
        }

        // ----------------------------------------------------------
        // No43. Perform system monitoring (information retrieval)
        // ----------------------------------------------------------
        // Check all product information for the target
        Schema.Product memory targetProductForNo43 = investment.getProduct(TARGET_PRODUCT_ID);
        // productId
        assertEq(targetProductForNo43.productId, TARGET_PRODUCT_ID, "No43: productId is not equal");
        assertEq(targetProductForNo43.offeringAmount, 1_000_000_000_000, "No43: offeringAmount is not equal");
        assertEq(targetProductForNo43.minInvestment, 250_000_000, "No43: minInvestment is not equal");
        assertEq(targetProductForNo43.offeringEndDate, 1737763200, "No43: offeringEndDate is not equal");
        assertEq(targetProductForNo43.maturityDate, 1774969200, "No43: maturityDate is not equal");
        assertEq(targetProductForNo43.expectedYield, 500, "No43: expectedYield is not equal");
        assertEq(targetProductForNo43.operationStartDate, 1738368000, "No43: operationStartDate is not equal");
        assertEq(targetProductForNo43.distributionStartDate, 1748736000, "No43: distributionStartDate is not equal");
        assertEq(targetProductForNo43.totalDistributionCount, 4, "No43: totalDistributionCount is not equal");
        assertEq(targetProductForNo43.distributionInterval, 3, "No43: distributionInterval is not equal");
        assertEq(targetProductForNo43.distributedCount, 4, "No43: distributedCount is not equal");
        assertEq(targetProductForNo43.distributedYieldPerCount, 0, "No43: distributedYieldPerCount is not equal");
        assertEq(targetProductForNo43.distributedTokenId, 0, "No43: distributedTokenId is not equal");
        assertEq(
            targetProductForNo43.totalReturnedAmount,
            targetProductForNo43.offeringAmount,
            "No43: totalReturnedAmount is not equal"
        );
        assertEq(
            targetProductForNo43.raisedAmount, targetProductForNo43.offeringAmount, "No43: raisedAmount is not equal"
        );
        assertNotEq(
            targetProductForNo43.productPool, targetProductForNo43.offeringAmount / 2, "No43: productPool is not equal"
        );
        assertTrue(targetProductForNo43.isMaturity, "No43: isMaturity is not true");
        assertFalse(targetProductForNo43.isInsufficientBalance, "No43: isInsufficientBalance is not false");
        assertEq(targetProductForNo43.maturedTokenId, 200, "No43: maturedTokenId is not equal");
    }

    receive() external payable {}
}
