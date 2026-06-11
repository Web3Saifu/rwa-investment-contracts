// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {MCTest, MCDevKit} from "@mc-devkit/Flattened.sol";

import {Schema} from "bundle/investment/storage/Schema.sol";
import {Storage} from "bundle/investment/storage/Storage.sol";
import {IInvestment} from "bundle/investment/interfaces/IInvestment.sol";
import {IInvestmentErrors} from "bundle/investment/interfaces/IInvestmentErrors.sol";
import {IInvestmentEvents} from "bundle/investment/interfaces/IInvestmentEvents.sol";
import {InvestmentDeployer} from "script/deploy/InvestmentDeployer.sol";
import {CalculateYieldLib} from "bundle/investment/utils/CalculateYieldLib.sol";
import {DistributionDateLib} from "bundle/investment/utils/DistributionDateLib.sol";

import {IInvestmentNFT} from "bundle/periphery/interfaces/IInvestmentNFT.sol";
import {MockInvestmentERC20} from "test/investment/mocks/MockInvestmentERC20.sol";

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title F-2026-17209 Yield Escrow Locked After Burn
 * @notice Verifies that maturity and claimPrincipal sweep unclaimed yield before burning NFT.
 */
contract F202617209Test is MCTest {
    IInvestment investment;
    MockInvestmentERC20 usdt;

    address safe;
    address admin;
    address investor1;
    address investor2;
    address[] admins;

    uint256 constant PRODUCT_ID = 1;
    uint256 constant OFFERING_AMOUNT = 1_000_000_000_000;
    uint256 constant MIN_INVESTMENT = 250_000_000;
    uint256 constant OFFERING_END_DATE = 1737763200;
    uint256 constant MATURITY_DATE = 1767225600;
    uint256 constant EXPECTED_YIELD = 500;
    uint256 constant OPERATION_STARTDATE = 1738368000;
    uint256 constant DISTRIBUTION_START_DATE = 1748736000;
    uint256 constant TOTAL_DISTRIBUTION_COUNT = 1;
    uint256 constant DISTRIBUTION_INTERVAL = 3;

    uint256 constant PRODUCT_ID_MULTI = 2;
    uint256 constant TOTAL_DISTRIBUTION_COUNT_MULTI = 3;

    function setUp() public {
        safe = makeAddr("safe");
        admin = makeAddr("admin");
        investor1 = makeAddr("investor1");
        investor2 = makeAddr("investor2");
        admins.push(admin);

        usdt = new MockInvestmentERC20();
        vm.prank(safe);
        investment = IInvestment(InvestmentDeployer.deployInvestment(mc, admins, admins, address(usdt), safe));
    }

    function _setup() internal returns (IInvestmentNFT nft, uint256 yield2, uint256 invest2) {
        Schema.RegisterProductArgs memory args = Schema.RegisterProductArgs({
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
            baseTokenURI: "",
            requiredTier: 0
        });

        vm.prank(admin);
        investment.registerProduct(args);

        Schema.Product memory product = investment.getProduct(PRODUCT_ID);
        nft = IInvestmentNFT(product.nftContract);

        uint256 units = OFFERING_AMOUNT / MIN_INVESTMENT / 2;
        uint256 invest1 = MIN_INVESTMENT * units;
        invest2 = invest1;

        usdt.mint(investor1, invest1);
        usdt.mint(investor2, invest2);
        vm.prank(investor1);
        usdt.approve(address(investment), invest1);
        vm.prank(investor2);
        usdt.approve(address(investment), invest2);
        vm.prank(investor1);
        investment.invest(PRODUCT_ID, units);
        vm.prank(investor2);
        investment.invest(PRODUCT_ID, units);

        product = investment.getProduct(PRODUCT_ID);
        uint256 firstPeriod =
            DistributionDateLib.calculateFirstDistributionPeriod(DISTRIBUTION_START_DATE, OPERATION_STARTDATE);
        uint256 periodYield =
            CalculateYieldLib.calculatePeriodYield(product.raisedAmount, product.expectedYield, firstPeriod);
        yield2 = CalculateYieldLib.calculateIndividualPeriodYield(periodYield, invest2, product.raisedAmount);

        uint256 tolerance = CalculateYieldLib.calculatePeriodTolerance(nft.tokenIdCounter());
        uint256 poolAmount = periodYield + tolerance + (invest1 + invest2);
        usdt.mint(admin, poolAmount);
        vm.prank(admin);
        usdt.approve(address(investment), poolAmount);
        vm.prank(admin);
        investment.deposit(PRODUCT_ID, poolAmount);
    }

    function _setupMultiDist() internal returns (IInvestmentNFT nft, uint256 invest2) {
        Schema.RegisterProductArgs memory args = Schema.RegisterProductArgs({
            productId: PRODUCT_ID_MULTI,
            offeringAmount: OFFERING_AMOUNT,
            minInvestment: MIN_INVESTMENT,
            offeringEndDate: OFFERING_END_DATE,
            maturityDate: MATURITY_DATE,
            expectedYield: EXPECTED_YIELD,
            operationStartDate: OPERATION_STARTDATE,
            distributionStartDate: DISTRIBUTION_START_DATE,
            totalDistributionCount: TOTAL_DISTRIBUTION_COUNT_MULTI,
            distributionInterval: DISTRIBUTION_INTERVAL,
            baseTokenURI: "",
            requiredTier: 0
        });

        vm.prank(admin);
        investment.registerProduct(args);

        Schema.Product memory product = investment.getProduct(PRODUCT_ID_MULTI);
        nft = IInvestmentNFT(product.nftContract);

        uint256 units = OFFERING_AMOUNT / MIN_INVESTMENT / 2;
        uint256 invest1 = MIN_INVESTMENT * units;
        invest2 = invest1;

        usdt.mint(investor1, invest1);
        usdt.mint(investor2, invest2);
        vm.prank(investor1);
        usdt.approve(address(investment), invest1);
        vm.prank(investor2);
        usdt.approve(address(investment), invest2);
        vm.prank(investor1);
        investment.invest(PRODUCT_ID_MULTI, units);
        vm.prank(investor2);
        investment.invest(PRODUCT_ID_MULTI, units);

        uint256 poolAmount = (invest1 + invest2) * 2;
        usdt.mint(admin, poolAmount);
        vm.prank(admin);
        usdt.approve(address(investment), poolAmount);
        vm.prank(admin);
        investment.deposit(PRODUCT_ID_MULTI, poolAmount);
    }

    /// @notice Maturity sweeps escrowed yield when investor is unblocked at maturity time.
    function test_maturity_sweepsUnclaimedYield() public {
        (IInvestmentNFT nft, uint256 yield2, uint256 invest2) = _setup();

        usdt.setBlocked(investor2, true);
        vm.warp(DISTRIBUTION_START_DATE);
        vm.prank(admin);
        investment.distributeYield(PRODUCT_ID);

        assertEq(investment.getUnclaimedYield(PRODUCT_ID, 2, 1), yield2, "yield should be escrowed");

        usdt.setBlocked(investor2, false);

        vm.warp(MATURITY_DATE);
        vm.prank(admin);
        investment.maturity(PRODUCT_ID);

        assertEq(nft.getInvestmentAmount(2), 0, "NFT 2 should be burned");
        assertEq(investment.getUnclaimedYield(PRODUCT_ID, 2, 1), 0, "yield escrow should be cleared");
        assertEq(usdt.balanceOf(investor2), invest2 + yield2, "investor2 should receive principal + yield");
    }

    /// @notice Maturity escrows principal when transfer fails (BL continues), yield stays escrowed.
    function test_maturity_escrowAll_whenSweepFails() public {
        (IInvestmentNFT nft, uint256 yield2, uint256 invest2) = _setup();

        usdt.setBlocked(investor2, true);
        vm.warp(DISTRIBUTION_START_DATE);
        vm.prank(admin);
        investment.distributeYield(PRODUCT_ID);

        vm.warp(MATURITY_DATE);
        vm.prank(admin);
        investment.maturity(PRODUCT_ID);

        assertEq(nft.getInvestmentAmount(2), invest2, "NFT 2 should NOT be burned");
        assertEq(investment.getUnclaimedYield(PRODUCT_ID, 2, 1), yield2, "yield should remain escrowed");
        assertEq(investment.getUnclaimedPrincipal(PRODUCT_ID, 2), invest2, "principal should be escrowed");
    }

    /// @notice claimPrincipal sweeps escrowed yield together with principal.
    function test_claimPrincipal_sweepsYield() public {
        (IInvestmentNFT nft, uint256 yield2, uint256 invest2) = _setup();

        usdt.setBlocked(investor2, true);
        vm.warp(DISTRIBUTION_START_DATE);
        vm.prank(admin);
        investment.distributeYield(PRODUCT_ID);

        vm.warp(MATURITY_DATE);
        vm.prank(admin);
        investment.maturity(PRODUCT_ID);

        usdt.setBlocked(investor2, false);

        vm.prank(investor2);
        investment.claimPrincipal(PRODUCT_ID, 2);

        assertEq(nft.getInvestmentAmount(2), 0, "NFT 2 should be burned after claimPrincipal");
        assertEq(investment.getUnclaimedYield(PRODUCT_ID, 2, 1), 0, "yield escrow should be cleared");
        assertEq(investment.getUnclaimedPrincipal(PRODUCT_ID, 2), 0, "principal escrow should be cleared");
        assertEq(usdt.balanceOf(investor2), invest2 + yield2, "investor2 should receive principal + yield");
    }

    /// @notice claimPrincipal reverts if transfer fails (BL still active), escrow unchanged.
    function test_claimPrincipal_revert_whenStillBlocked() public {
        (, uint256 yield2, uint256 invest2) = _setup();

        usdt.setBlocked(investor2, true);
        vm.warp(DISTRIBUTION_START_DATE);
        vm.prank(admin);
        investment.distributeYield(PRODUCT_ID);

        vm.warp(MATURITY_DATE);
        vm.prank(admin);
        investment.maturity(PRODUCT_ID);

        vm.prank(investor2);
        vm.expectRevert(IInvestmentErrors.ClaimTransferFailed.selector);
        investment.claimPrincipal(PRODUCT_ID, 2);

        assertEq(investment.getUnclaimedYield(PRODUCT_ID, 2, 1), yield2, "yield escrow should remain");
        assertEq(investment.getUnclaimedPrincipal(PRODUCT_ID, 2), invest2, "principal escrow should remain");
    }

    /// @notice Maturity with no yield escrow burns normally (happy path regression).
    function test_maturity_noYieldEscrow_normalBurn() public {
        (IInvestmentNFT nft,, uint256 invest2) = _setup();

        vm.warp(DISTRIBUTION_START_DATE);
        vm.prank(admin);
        investment.distributeYield(PRODUCT_ID);

        vm.warp(MATURITY_DATE);
        vm.prank(admin);
        investment.maturity(PRODUCT_ID);

        assertEq(nft.getInvestmentAmount(2), 0, "NFT 2 should be burned");
        assertGt(usdt.balanceOf(investor2), invest2, "investor2 should receive principal (+ yield from push)");
    }

    /// @notice claimYield before maturity still works; maturity then burns with no leftover yield.
    function test_claimYield_beforeMaturity_thenNormalBurn() public {
        (IInvestmentNFT nft, uint256 yield2, uint256 invest2) = _setup();

        usdt.setBlocked(investor2, true);
        vm.warp(DISTRIBUTION_START_DATE);
        vm.prank(admin);
        investment.distributeYield(PRODUCT_ID);

        usdt.setBlocked(investor2, false);

        vm.prank(investor2);
        investment.claimYield(PRODUCT_ID, 2, 1);
        assertEq(usdt.balanceOf(investor2), yield2, "investor2 claimed yield");
        assertEq(investment.getUnclaimedYield(PRODUCT_ID, 2, 1), 0, "yield escrow cleared by claimYield");

        vm.warp(MATURITY_DATE);
        vm.prank(admin);
        investment.maturity(PRODUCT_ID);

        assertEq(nft.getInvestmentAmount(2), 0, "NFT 2 should be burned at maturity");
        assertEq(usdt.balanceOf(investor2), yield2 + invest2, "investor2 has yield + principal");
    }

    // ======================== Multi-distribution tests ========================

    /// @notice Maturity sweeps escrowed yield across multiple distribution rounds (slots 1 & 3 escrowed, slot 2 pushed).
    function test_maturity_multipleDistributions_sweep() public {
        (IInvestmentNFT nft, uint256 invest2) = _setupMultiDist();

        uint256 distDate1 =
            DistributionDateLib.calculateNextDistributionDate(DISTRIBUTION_START_DATE, DISTRIBUTION_INTERVAL, 0, false);
        uint256 distDate2 =
            DistributionDateLib.calculateNextDistributionDate(DISTRIBUTION_START_DATE, DISTRIBUTION_INTERVAL, 1, false);
        uint256 distDate3 =
            DistributionDateLib.calculateNextDistributionDate(DISTRIBUTION_START_DATE, DISTRIBUTION_INTERVAL, 2, false);

        // Round 1: investor2 blocked → escrowed
        usdt.setBlocked(investor2, true);
        vm.warp(distDate1);
        vm.prank(admin);
        investment.distributeYield(PRODUCT_ID_MULTI);
        uint256 yieldSlot1 = investment.getUnclaimedYield(PRODUCT_ID_MULTI, 2, 1);
        assertGt(yieldSlot1, 0, "slot 1 should be escrowed");

        // Round 2: investor2 unblocked → pushed
        usdt.setBlocked(investor2, false);
        vm.warp(distDate2);
        vm.prank(admin);
        investment.distributeYield(PRODUCT_ID_MULTI);
        uint256 yieldPushed2 = usdt.balanceOf(investor2);
        assertGt(yieldPushed2, 0, "round 2 yield should be pushed");
        assertEq(investment.getUnclaimedYield(PRODUCT_ID_MULTI, 2, 2), 0, "slot 2 should not be escrowed");

        // Round 3: investor2 blocked again → escrowed
        usdt.setBlocked(investor2, true);
        vm.warp(distDate3);
        vm.prank(admin);
        investment.distributeYield(PRODUCT_ID_MULTI);
        uint256 yieldSlot3 = investment.getUnclaimedYield(PRODUCT_ID_MULTI, 2, 3);
        assertGt(yieldSlot3, 0, "slot 3 should be escrowed");

        // Unblock and run maturity — expect YieldReceived + YieldClaimed per escrowed slot
        usdt.setBlocked(investor2, false);
        vm.warp(MATURITY_DATE);

        vm.expectEmit(true, true, true, true);
        emit IInvestmentEvents.YieldReceived(PRODUCT_ID_MULTI, 2, investor2, yieldSlot1);
        vm.expectEmit(true, true, true, true);
        emit IInvestmentEvents.YieldClaimed(PRODUCT_ID_MULTI, 2, investor2, yieldSlot1, 1);
        vm.expectEmit(true, true, true, true);
        emit IInvestmentEvents.YieldReceived(PRODUCT_ID_MULTI, 2, investor2, yieldSlot3);
        vm.expectEmit(true, true, true, true);
        emit IInvestmentEvents.YieldClaimed(PRODUCT_ID_MULTI, 2, investor2, yieldSlot3, 3);

        vm.prank(admin);
        investment.maturity(PRODUCT_ID_MULTI);

        assertEq(nft.getInvestmentAmount(2), 0, "NFT 2 should be burned");
        assertEq(investment.getUnclaimedYield(PRODUCT_ID_MULTI, 2, 1), 0, "slot 1 escrow should be cleared");
        assertEq(investment.getUnclaimedYield(PRODUCT_ID_MULTI, 2, 2), 0, "slot 2 should still be 0");
        assertEq(investment.getUnclaimedYield(PRODUCT_ID_MULTI, 2, 3), 0, "slot 3 escrow should be cleared");
        assertEq(
            usdt.balanceOf(investor2),
            yieldPushed2 + yieldSlot1 + yieldSlot3 + invest2,
            "investor2 should receive pushed yield + swept yields + principal"
        );
    }

    // ======================== Event verification tests ========================

    /// @notice Maturity sweep emits individual YieldReceived + YieldClaimed events per escrowed slot.
    function test_maturity_emitsYieldClaimedPerSlot() public {
        (, uint256 yield2,) = _setup();

        usdt.setBlocked(investor2, true);
        vm.warp(DISTRIBUTION_START_DATE);
        vm.prank(admin);
        investment.distributeYield(PRODUCT_ID);

        usdt.setBlocked(investor2, false);
        vm.warp(MATURITY_DATE);

        vm.expectEmit(true, true, true, true);
        emit IInvestmentEvents.YieldReceived(PRODUCT_ID, 2, investor2, yield2);
        vm.expectEmit(true, true, true, true);
        emit IInvestmentEvents.YieldClaimed(PRODUCT_ID, 2, investor2, yield2, 1);

        vm.prank(admin);
        investment.maturity(PRODUCT_ID);
    }

    /// @notice claimPrincipal sweep emits individual YieldReceived + YieldClaimed events per escrowed slot.
    function test_claimPrincipal_emitsYieldClaimedPerSlot() public {
        (, uint256 yield2,) = _setup();

        usdt.setBlocked(investor2, true);
        vm.warp(DISTRIBUTION_START_DATE);
        vm.prank(admin);
        investment.distributeYield(PRODUCT_ID);

        vm.warp(MATURITY_DATE);
        vm.prank(admin);
        investment.maturity(PRODUCT_ID);

        usdt.setBlocked(investor2, false);

        vm.expectEmit(true, true, true, true);
        emit IInvestmentEvents.YieldReceived(PRODUCT_ID, 2, investor2, yield2);
        vm.expectEmit(true, true, true, true);
        emit IInvestmentEvents.YieldClaimed(PRODUCT_ID, 2, investor2, yield2, 1);

        vm.prank(investor2);
        investment.claimPrincipal(PRODUCT_ID, 2);
    }

    // ======================== Partial claim + sweep test ========================

    /// @notice Investor claims one yield slot via claimYield; maturity sweeps the remaining escrowed slots.
    function test_partialClaimYield_thenMaturity_sweepsRemaining() public {
        (IInvestmentNFT nft, uint256 invest2) = _setupMultiDist();

        uint256 distDate1 =
            DistributionDateLib.calculateNextDistributionDate(DISTRIBUTION_START_DATE, DISTRIBUTION_INTERVAL, 0, false);
        uint256 distDate2 =
            DistributionDateLib.calculateNextDistributionDate(DISTRIBUTION_START_DATE, DISTRIBUTION_INTERVAL, 1, false);
        uint256 distDate3 =
            DistributionDateLib.calculateNextDistributionDate(DISTRIBUTION_START_DATE, DISTRIBUTION_INTERVAL, 2, false);

        // All 3 rounds with investor2 blocked → all escrowed
        usdt.setBlocked(investor2, true);

        vm.warp(distDate1);
        vm.prank(admin);
        investment.distributeYield(PRODUCT_ID_MULTI);

        vm.warp(distDate2);
        vm.prank(admin);
        investment.distributeYield(PRODUCT_ID_MULTI);

        vm.warp(distDate3);
        vm.prank(admin);
        investment.distributeYield(PRODUCT_ID_MULTI);

        uint256 yieldSlot1 = investment.getUnclaimedYield(PRODUCT_ID_MULTI, 2, 1);
        uint256 yieldSlot2 = investment.getUnclaimedYield(PRODUCT_ID_MULTI, 2, 2);
        uint256 yieldSlot3 = investment.getUnclaimedYield(PRODUCT_ID_MULTI, 2, 3);
        assertGt(yieldSlot1, 0, "slot 1 escrowed");
        assertGt(yieldSlot2, 0, "slot 2 escrowed");
        assertGt(yieldSlot3, 0, "slot 3 escrowed");

        // Unblock and claim only slot 2 manually
        usdt.setBlocked(investor2, false);
        vm.prank(investor2);
        investment.claimYield(PRODUCT_ID_MULTI, 2, 2);
        assertEq(investment.getUnclaimedYield(PRODUCT_ID_MULTI, 2, 2), 0, "slot 2 claimed");
        assertEq(usdt.balanceOf(investor2), yieldSlot2, "investor2 received slot 2 yield");

        // Maturity: should sweep only slot 1 and 3
        vm.warp(MATURITY_DATE);

        vm.expectEmit(true, true, true, true);
        emit IInvestmentEvents.YieldReceived(PRODUCT_ID_MULTI, 2, investor2, yieldSlot1);
        vm.expectEmit(true, true, true, true);
        emit IInvestmentEvents.YieldClaimed(PRODUCT_ID_MULTI, 2, investor2, yieldSlot1, 1);
        vm.expectEmit(true, true, true, true);
        emit IInvestmentEvents.YieldReceived(PRODUCT_ID_MULTI, 2, investor2, yieldSlot3);
        vm.expectEmit(true, true, true, true);
        emit IInvestmentEvents.YieldClaimed(PRODUCT_ID_MULTI, 2, investor2, yieldSlot3, 3);

        vm.prank(admin);
        investment.maturity(PRODUCT_ID_MULTI);

        assertEq(nft.getInvestmentAmount(2), 0, "NFT 2 should be burned");
        assertEq(investment.getUnclaimedYield(PRODUCT_ID_MULTI, 2, 1), 0, "slot 1 swept");
        assertEq(investment.getUnclaimedYield(PRODUCT_ID_MULTI, 2, 2), 0, "slot 2 already claimed");
        assertEq(investment.getUnclaimedYield(PRODUCT_ID_MULTI, 2, 3), 0, "slot 3 swept");
        assertEq(
            usdt.balanceOf(investor2),
            yieldSlot1 + yieldSlot2 + yieldSlot3 + invest2,
            "investor2 has all yields + principal"
        );
    }
}
