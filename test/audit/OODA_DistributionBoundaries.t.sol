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

contract OODADistributionBoundariesTest is MCTest {
    IInvestment internal investment;
    MockInvestmentERC20 internal usdt;
    address internal safe;
    address internal admin;
    address internal alice;
    address internal buyer;

    uint256 internal constant UNIT = 1_000_000;
    uint256 internal constant OFFERING_END = 1_737_763_200;
    uint256 internal constant OPERATION_START = 1_738_368_000;
    uint256 internal constant DISTRIBUTION_START = 1_748_736_000;
    uint256 internal constant MATURITY = 1_830_297_600;

    function setUp() public {
        safe = makeAddr("safe");
        admin = makeAddr("admin");
        alice = makeAddr("alice");
        buyer = makeAddr("buyer");
        address[] memory operators = new address[](1);
        operators[0] = admin;
        usdt = new MockInvestmentERC20();
        vm.prank(safe);
        investment = IInvestment(InvestmentDeployer.deployInvestment(mc, operators, operators, address(usdt), safe));
    }

    function _register(
        uint256 productId,
        uint256 offering,
        uint256 minInvestment,
        uint256 expectedYield,
        uint256 distributionCount,
        uint256 operationStart,
        uint256 distributionStart,
        uint256 maturity
    ) internal returns (IInvestmentNFT nft) {
        vm.prank(admin);
        investment.registerProduct(
            Schema.RegisterProductArgs({
                productId: productId,
                offeringAmount: offering,
                minInvestment: minInvestment,
                offeringEndDate: OFFERING_END,
                maturityDate: maturity,
                expectedYield: expectedYield,
                operationStartDate: operationStart,
                distributionStartDate: distributionStart,
                totalDistributionCount: distributionCount,
                distributionInterval: distributionCount == 1 ? 0 : 1,
                baseTokenURI: "",
                requiredTier: 0
            })
        );
        nft = IInvestmentNFT(investment.getProduct(productId).nftContract);
    }

    function _mintEqual(uint256 productId, uint256 count, uint256 units, address base) internal {
        for (uint256 i; i < count; ++i) {
            vm.prank(admin);
            investment.mintNFT(productId, units, address(uint160(base) + uint160(i)));
        }
    }

    function _fund(uint256 productId, uint256 amount) internal {
        usdt.mint(admin, amount);
        vm.prank(admin);
        usdt.approve(address(investment), amount);
        vm.prank(admin);
        investment.deposit(productId, amount);
    }

    function _distribute(uint256 productId, uint256 timestamp) internal {
        vm.warp(timestamp);
        vm.prank(admin);
        investment.distributeYield(productId);
    }

    function _setup51() internal returns (IInvestmentNFT nft, address holder1, address holder51, uint256 yieldEach) {
        nft = _register(1, 51 * UNIT, UNIT, 500, 1, OPERATION_START, DISTRIBUTION_START, MATURITY);
        _mintEqual(1, 51, 1, alice);
        _fund(1, 51 * UNIT + investment.simulateTotalYield(1));
        holder1 = alice;
        holder51 = address(uint160(alice) + 50);
        yieldEach = investment.simulateIndividualPeriodYield(1, 1)[0];
    }

    function test_13_processedNftTransferCannotDuplicateRound() public {
        (IInvestmentNFT nft, address holder1,, uint256 yieldEach) = _setup51();
        _distribute(1, DISTRIBUTION_START);
        assertEq(usdt.balanceOf(holder1), yieldEach);

        vm.prank(holder1);
        nft.transferFrom(holder1, buyer, 1);
        _distribute(1, DISTRIBUTION_START);

        assertEq(usdt.balanceOf(buyer), 0, "buyer cannot replay an already processed round");
        assertEq(investment.getUnclaimedYield(1, 1, 1), 0);
        assertEq(investment.getProduct(1).distributedCount, 1);
    }

    function test_14_unprocessedNftTransferPaysExactlyCurrentOwner() public {
        (IInvestmentNFT nft,, address holder51, uint256 yieldEach) = _setup51();
        _distribute(1, DISTRIBUTION_START);

        vm.prank(holder51);
        nft.transferFrom(holder51, buyer, 51);
        _distribute(1, DISTRIBUTION_START);

        assertEq(usdt.balanceOf(holder51), 0);
        assertEq(usdt.balanceOf(buyer), yieldEach, "buyer receives the unprocessed token's round once");
        assertEq(investment.getUnclaimedYield(1, 51, 1), 0);
    }

    function _assertMixedFailureBoundary(uint256 count) internal {
        _register(1, count * UNIT, UNIT, 500, 1, OPERATION_START, DISTRIBUTION_START, MATURITY);
        _mintEqual(1, count, 1, alice);
        _fund(1, count * UNIT + investment.simulateTotalYield(1));
        uint256 yieldEach = investment.simulateIndividualPeriodYield(1, 1)[0];

        for (uint256 i; i < count; i += 3) usdt.setBlocked(address(uint160(alice) + uint160(i)), true);
        uint256 batches = (count + 49) / 50;
        for (uint256 i; i < batches; ++i) _distribute(1, DISTRIBUTION_START);

        uint256 accounted;
        for (uint256 i; i < count; ++i) {
            address holder = address(uint160(alice) + uint160(i));
            uint256 escrow = investment.getUnclaimedYield(1, i + 1, 1);
            accounted += usdt.balanceOf(holder) + escrow;
            if (i % 3 == 0) assertEq(escrow, yieldEach);
            else assertEq(usdt.balanceOf(holder), yieldEach);
        }
        assertEq(accounted, count * yieldEach, "every token is accounted exactly once");
        Schema.Product memory product = investment.getProduct(1);
        assertEq(product.distributedCount, 1);
        assertEq(product.distributedTokenId, 0);
    }

    function test_15_boundary49MixedFailures() public { _assertMixedFailureBoundary(49); }
    function test_15_boundary50MixedFailures() public { _assertMixedFailureBoundary(50); }
    function test_15_boundary51MixedFailures() public { _assertMixedFailureBoundary(51); }

    function test_16_threeBatchClaimsStaySynchronizedThroughMaturity() public {
        IInvestmentNFT nft = _register(1, 101 * UNIT, UNIT, 500, 1, OPERATION_START, DISTRIBUTION_START, MATURITY);
        _mintEqual(1, 101, 1, alice);
        _fund(1, 101 * UNIT + investment.simulateTotalYield(1));

        uint256[3] memory ids = [uint256(10), uint256(60), uint256(101)];
        for (uint256 i; i < 3; ++i) usdt.setBlocked(address(uint160(alice) + uint160(ids[i] - 1)), true);

        for (uint256 batch; batch < 3; ++batch) {
            _distribute(1, DISTRIBUTION_START);
            uint256 expectedCursor = batch < 2 ? (batch + 1) * 50 : 0;
            assertEq(investment.getProduct(1).distributedTokenId, expectedCursor);
            address holder = address(uint160(alice) + uint160(ids[batch] - 1));
            usdt.setBlocked(holder, false);
            vm.prank(holder);
            investment.claimYield(1, ids[batch], 1);
        }

        vm.warp(MATURITY);
        for (uint256 batch; batch < 3; ++batch) {
            vm.prank(admin);
            investment.maturity(1);
        }
        assertTrue(investment.getProduct(1).isMaturity);
        assertEq(nft.getInvestmentAmount(1), 0);
        assertEq(nft.getInvestmentAmount(51), 0);
        assertEq(nft.getInvestmentAmount(101), 0);
    }

    function test_17_twentyFourRoundsNeverExceedSimulatedToleranceBudget() public {
        uint256 count = 51;
        _register(1, count * UNIT, UNIT, 9999, 24, OPERATION_START, DISTRIBUTION_START, MATURITY);
        _mintEqual(1, count, 1, alice);
        uint256 yieldBudget = investment.simulateTotalYield(1);
        _fund(1, count * UNIT + yieldBudget);

        uint256[] memory dates = investment.getDistributionDates(1);
        for (uint256 round; round < dates.length; ++round) {
            _distribute(1, dates[round]);
            _distribute(1, dates[round]);
        }

        uint256 paid;
        for (uint256 i; i < count; ++i) paid += usdt.balanceOf(address(uint160(alice) + uint160(i)));
        assertLe(paid, yieldBudget, "aggregate payout cannot exceed simulated yield plus tolerance");
        assertEq(investment.getProduct(1).productPool, count * UNIT + yieldBudget - paid);
        assertEq(investment.getProduct(1).distributedCount, 24);
    }

    function test_18_roundingMakesThirdBatchPrecheckUnderflowPermanently() public {
        uint256 operationStart = 1_738_368_000;
        uint256 period;
        for (uint256 candidate = 1 days; candidate < 365 days; candidate += 1 hours) {
            if (CalculateYieldLib.calculatePeriodYield(101, 9999, candidate) == 51) {
                period = candidate;
                break;
            }
        }
        assertGt(period, 0, "test must find a period yielding exactly 51 units");
        uint256 distributionStart = operationStart + period;
        uint256 maturity = distributionStart + 1 days;

        _register(1, 101, 1, 9999, 1, operationStart, distributionStart, maturity);
        _mintEqual(1, 101, 1, alice);
        assertEq(investment.simulateIndividualPeriodYield(1, 1)[0], 1);
        _fund(1, 101 + investment.simulateTotalYield(1));

        _distribute(1, distributionStart);
        _distribute(1, distributionStart);
        Schema.Product memory partialState = investment.getProduct(1);
        assertEq(partialState.distributedTokenId, 100);
        assertEq(partialState.distributedYieldPerCount, 100);
        assertEq(partialState.distributedCount, 0);

        vm.expectRevert(stdError.arithmeticError);
        vm.prank(admin);
        investment.distributeYield(1);
        vm.expectRevert(stdError.arithmeticError);
        vm.prank(admin);
        investment.distributeYield(1);
    }

    function test_18_realisticPermissionlessInvestPathAlsoPermanentlyUnderflows() public {
        uint256 realisticMinimum = 250_000_000; // 250 USDT at 6 decimals
        uint256 offering = 101 * realisticMinimum;
        uint256 operationStart = OPERATION_START;
        uint256 period;
        for (uint256 candidate = 1; candidate < 1 days; ++candidate) {
            if (CalculateYieldLib.calculatePeriodYield(offering, 1, candidate) == 51) {
                period = candidate;
                break;
            }
        }
        assertGt(period, 0, "valid 1 bps period yielding exactly 51 micro-USDT must exist");
        uint256 distributionStart = operationStart + period;
        uint256 maturity = distributionStart + 1 days;

        _register(1, offering, realisticMinimum, 1, 1, operationStart, distributionStart, maturity);
        usdt.mint(buyer, realisticMinimum);
        vm.prank(buyer);
        usdt.approve(address(investment), realisticMinimum);
        vm.prank(buyer);
        investment.invest(1, 1);

        usdt.mint(alice, 100 * realisticMinimum);
        vm.prank(alice);
        usdt.approve(address(investment), type(uint256).max);
        for (uint256 i; i < 100; ++i) {
            vm.prank(alice);
            investment.invest(1, 1);
        }

        assertEq(investment.getProduct(1).raisedAmount, offering);
        assertEq(investment.simulateIndividualPeriodYield(1, 1)[0], 1);
        assertEq(investment.simulateTotalYield(1), 155, "51 period yield plus 104 defined tolerance");
        _fund(1, 155);

        _distribute(1, distributionStart);
        _distribute(1, distributionStart);
        Schema.Product memory stalled = investment.getProduct(1);
        assertEq(stalled.distributedTokenId, 100);
        assertEq(stalled.distributedYieldPerCount, 100);
        assertEq(stalled.distributedCount, 0);
        assertFalse(stalled.isInsufficientBalance, "recovery flag is never set because arithmetic panics first");

        _fund(1, 1_000_000); // Massive overfunding cannot repair an arithmetic precheck.
        vm.expectRevert(stdError.arithmeticError);
        vm.prank(admin);
        investment.distributeYield(1);

        vm.warp(maturity);
        vm.expectRevert(IInvestmentErrors.BeforeDistributionCompleted.selector);
        vm.prank(admin);
        investment.maturity(1);
        vm.expectRevert(IInvestmentErrors.ProductNotMatured.selector);
        vm.prank(buyer);
        investment.claimPrincipal(1, 1);
    }

    function test_18_minorityAttackerCanFreezeLargerHonestPosition() public {
        uint256 realisticMinimum = 250_000_000;
        uint256 victimUnits = 1_000;
        uint256 attackerNfts = 50;
        uint256 totalUnits = victimUnits + attackerNfts;
        uint256 offering = totalUnits * realisticMinimum;
        uint256 period;
        uint256 periodYield;
        uint256 victimYield;
        uint256 attackerYield;

        for (uint256 candidate = 1; candidate < 1 days; ++candidate) {
            uint256 candidatePeriodYield = CalculateYieldLib.calculatePeriodYield(offering, 1, candidate);
            uint256 candidateVictimYield = CalculateYieldLib.calculateIndividualPeriodYield(
                candidatePeriodYield, victimUnits * realisticMinimum, offering
            );
            uint256 candidateAttackerYield =
                CalculateYieldLib.calculateIndividualPeriodYield(candidatePeriodYield, realisticMinimum, offering);
            uint256 firstBatchPayout = candidateVictimYield + 49 * candidateAttackerYield;
            if (candidateAttackerYield > 0 && firstBatchPayout > candidatePeriodYield + 4) {
                period = candidate;
                periodYield = candidatePeriodYield;
                victimYield = candidateVictimYield;
                attackerYield = candidateAttackerYield;
                break;
            }
        }
        assertGt(period, 0, "a valid minority-griefing period must exist");

        uint256 distributionStart = OPERATION_START + period;
        uint256 maturity = distributionStart + 1 days;
        _register(1, offering, realisticMinimum, 1, 1, OPERATION_START, distributionStart, maturity);

        usdt.mint(buyer, victimUnits * realisticMinimum);
        vm.prank(buyer);
        usdt.approve(address(investment), victimUnits * realisticMinimum);
        vm.prank(buyer);
        investment.invest(1, victimUnits); // Honest token 1 represents 250,000 USDT.

        usdt.mint(alice, attackerNfts * realisticMinimum);
        vm.prank(alice);
        usdt.approve(address(investment), type(uint256).max);
        for (uint256 i; i < attackerNfts; ++i) {
            vm.prank(alice);
            investment.invest(1, 1);
        }

        _fund(1, investment.simulateTotalYield(1));
        _distribute(1, distributionStart);
        Schema.Product memory stalled = investment.getProduct(1);
        assertEq(stalled.distributedTokenId, 50);
        assertEq(stalled.distributedYieldPerCount, victimYield + 49 * attackerYield);
        assertGt(stalled.distributedYieldPerCount, periodYield + 4, "next precheck must underflow");

        vm.expectRevert(stdError.arithmeticError);
        vm.prank(admin);
        investment.distributeYield(1);
        vm.warp(maturity);
        vm.expectRevert(IInvestmentErrors.BeforeDistributionCompleted.selector);
        vm.prank(admin);
        investment.maturity(1);
    }

    function test_19_normalizedEarlyDistributionMakesLateInvestorMissYield() public {
        uint256 day = 1_735_689_600;
        vm.warp(day - 1 days);
        vm.prank(admin);
        investment.registerProduct(
            Schema.RegisterProductArgs({
                productId: 1,
                offeringAmount: UNIT,
                minInvestment: UNIT,
                offeringEndDate: day + 30 minutes,
                maturityDate: day + 1 hours,
                expectedYield: 500,
                operationStartDate: day + 22 hours,
                distributionStartDate: day + 23 hours,
                totalDistributionCount: 1,
                distributionInterval: 0,
                baseTokenURI: "",
                requiredTier: 0
            })
        );

        _distribute(1, day);
        assertEq(investment.getProduct(1).distributedCount, 1, "empty round completes before offering closes");

        vm.warp(day + 10 minutes);
        usdt.mint(alice, UNIT);
        vm.prank(alice);
        usdt.approve(address(investment), UNIT);
        vm.prank(alice);
        investment.invest(1, 1);

        vm.warp(day + 1 hours);
        vm.prank(admin);
        investment.maturity(1);
        assertEq(usdt.balanceOf(alice), UNIT, "late investor receives principal but no scheduled yield");
    }
}
