// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {MCTest} from "@mc-devkit/Flattened.sol";
import {stdError} from "forge-std/StdError.sol";

import {Schema} from "bundle/investment/storage/Schema.sol";
import {IInvestment} from "bundle/investment/interfaces/IInvestment.sol";
import {IInvestmentErrors} from "bundle/investment/interfaces/IInvestmentErrors.sol";
import {InvestmentDeployer} from "script/deploy/InvestmentDeployer.sol";
import {IInvestmentNFT} from "bundle/periphery/interfaces/IInvestmentNFT.sol";
import {CalculateYieldLib} from "bundle/investment/utils/CalculateYieldLib.sol";
import {MockInvestmentERC20} from "test/investment/mocks/MockInvestmentERC20.sol";

contract HPRoundingUnderflowPermanentLockTest is MCTest {
    IInvestment internal investment;
    MockInvestmentERC20 internal usdt;

    address internal safe;
    address internal admin;
    address internal victim;
    address internal smallPositionInvestor;

    uint256 internal constant PRODUCT_ID = 1;
    uint256 internal constant MIN_INVESTMENT = 250_000_000; // 250 USDT, 6 decimals
    uint256 internal constant VICTIM_UNITS = 1_000;
    uint256 internal constant SMALL_POSITION_NFTS = 50;
    uint256 internal constant OFFERING = (VICTIM_UNITS + SMALL_POSITION_NFTS) * MIN_INVESTMENT;
    uint256 internal constant OPERATION_START = 1_738_368_000;
    uint256 internal constant DISTRIBUTION_START = OPERATION_START + 631;
    uint256 internal constant MATURITY = DISTRIBUTION_START + 1 days;

    function setUp() public {
        safe = makeAddr("safe");
        admin = makeAddr("admin");
        victim = makeAddr("victim");
        smallPositionInvestor = makeAddr("smallPositionInvestor");

        address[] memory operators = new address[](1);
        operators[0] = admin;
        usdt = new MockInvestmentERC20();
        vm.prank(safe);
        investment = IInvestment(InvestmentDeployer.deployInvestment(mc, operators, operators, address(usdt), safe));

        vm.prank(admin);
        investment.registerProduct(
            Schema.RegisterProductArgs({
                productId: PRODUCT_ID,
                offeringAmount: OFFERING,
                minInvestment: MIN_INVESTMENT,
                offeringEndDate: 1_737_763_200,
                maturityDate: MATURITY,
                expectedYield: 1, // 1 basis point
                operationStartDate: OPERATION_START,
                distributionStartDate: DISTRIBUTION_START,
                totalDistributionCount: 1,
                distributionInterval: 0,
                baseTokenURI: "",
                requiredTier: 0
            })
        );
    }

    function test_permanentProductLockFromRoundingUnderflow() public {
        uint256 periodYield = CalculateYieldLib.calculatePeriodYield(OFFERING, 1, 631);
        uint256 victimPrincipal = VICTIM_UNITS * MIN_INVESTMENT;
        uint256 victimYield = CalculateYieldLib.calculateIndividualPeriodYield(periodYield, victimPrincipal, OFFERING);
        uint256 smallPositionYield =
            CalculateYieldLib.calculateIndividualPeriodYield(periodYield, MIN_INVESTMENT, OFFERING);

        assertEq(periodYield, 525);
        assertEq(victimYield, 500);
        assertEq(smallPositionYield, 1);

        usdt.mint(victim, victimPrincipal);
        vm.prank(victim);
        usdt.approve(address(investment), victimPrincipal);
        vm.prank(victim);
        investment.invest(PRODUCT_ID, VICTIM_UNITS); // Token 1: 250,000 USDT victim position.

        usdt.mint(smallPositionInvestor, SMALL_POSITION_NFTS * MIN_INVESTMENT);
        vm.prank(smallPositionInvestor);
        usdt.approve(address(investment), type(uint256).max);
        for (uint256 i; i < SMALL_POSITION_NFTS; ++i) {
            vm.prank(smallPositionInvestor);
            investment.invest(PRODUCT_ID, 1); // Tokens 2-51: 50 minimum-sized positions.
        }

        uint256 simulatedYieldBudget = investment.simulateTotalYield(PRODUCT_ID);
        assertEq(simulatedYieldBudget, 578); // periodYield 525 + period tolerance 53.
        usdt.mint(admin, simulatedYieldBudget);
        vm.prank(admin);
        usdt.approve(address(investment), simulatedYieldBudget);
        vm.prank(admin);
        investment.deposit(PRODUCT_ID, simulatedYieldBudget);

        vm.warp(DISTRIBUTION_START);
        vm.prank(admin);
        investment.distributeYield(PRODUCT_ID); // Batch 1 processes token IDs 1-50.

        Schema.Product memory stalled = investment.getProduct(PRODUCT_ID);
        assertEq(stalled.distributedTokenId, 50);
        assertEq(stalled.distributedYieldPerCount, 549); // 500 large-position yield + 49 minimum-position yields.
        assertEq(stalled.distributedCount, 0);
        assertFalse(stalled.isInsufficientBalance);
        assertEq(usdt.balanceOf(victim), 500);

        // At cursor 50, tolerance remainder is 4. The next precheck evaluates 525 + 4 - 549.
        vm.expectRevert(stdError.arithmeticError);
        vm.prank(admin);
        investment.distributeYield(PRODUCT_ID);

        // Overfunding cannot repair arithmetic that panics before the balance comparison.
        usdt.mint(admin, 1_000_000);
        vm.prank(admin);
        usdt.approve(address(investment), 1_000_000);
        vm.prank(admin);
        investment.deposit(PRODUCT_ID, 1_000_000);
        vm.expectRevert(stdError.arithmeticError);
        vm.prank(admin);
        investment.distributeYield(PRODUCT_ID);

        vm.warp(MATURITY);
        vm.expectRevert(IInvestmentErrors.BeforeDistributionCompleted.selector);
        vm.prank(admin);
        investment.maturity(PRODUCT_ID);

        vm.expectRevert(IInvestmentErrors.ProductNotMatured.selector);
        vm.prank(victim);
        investment.claimPrincipal(PRODUCT_ID, 1);

        IInvestmentNFT nft = IInvestmentNFT(investment.getProduct(PRODUCT_ID).nftContract);
        assertEq(nft.ownerOf(1), victim);
        assertEq(nft.getInvestmentAmount(1), victimPrincipal);
    }
}
