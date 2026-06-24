// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {MCTest} from "@mc-devkit/Flattened.sol";

import {Schema} from "bundle/investment/storage/Schema.sol";
import {IInvestment} from "bundle/investment/interfaces/IInvestment.sol";
import {IInvestmentErrors} from "bundle/investment/interfaces/IInvestmentErrors.sol";
import {InvestmentDeployer} from "script/deploy/InvestmentDeployer.sol";
import {IInvestmentNFT} from "bundle/periphery/interfaces/IInvestmentNFT.sol";
import {MockInvestmentERC20} from "test/investment/mocks/MockInvestmentERC20.sol";

contract OODAEscrowCursorSequencesTest is MCTest {
    IInvestment internal investment;
    MockInvestmentERC20 internal usdt;
    address internal safe;
    address internal admin;
    address internal alice;
    address internal bob;

    uint256 internal constant UNIT = 10_000_000;
    uint256 internal constant OFFERING_END = 1_737_763_200;
    uint256 internal constant OPERATION_START = 1_738_368_000;
    uint256 internal constant DISTRIBUTION_START = 1_748_736_000;
    uint256 internal constant MATURITY = 1_767_225_600;

    function setUp() public {
        safe = makeAddr("safe");
        admin = makeAddr("admin");
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        address[] memory operators = new address[](1);
        operators[0] = admin;
        usdt = new MockInvestmentERC20();
        vm.prank(safe);
        investment = IInvestment(InvestmentDeployer.deployInvestment(mc, operators, operators, address(usdt), safe));
    }

    function _register(uint256 productId, uint256 expectedYield, uint256 distributionCount)
        internal
        returns (IInvestmentNFT nft)
    {
        Schema.RegisterProductArgs memory args = Schema.RegisterProductArgs({
            productId: productId,
            offeringAmount: 100 * UNIT,
            minInvestment: UNIT,
            offeringEndDate: OFFERING_END,
            maturityDate: MATURITY,
            expectedYield: expectedYield,
            operationStartDate: OPERATION_START,
            distributionStartDate: DISTRIBUTION_START,
            totalDistributionCount: distributionCount,
            distributionInterval: distributionCount == 1 ? 0 : 3,
            baseTokenURI: "",
            requiredTier: 0
        });
        vm.prank(admin);
        investment.registerProduct(args);
        nft = IInvestmentNFT(investment.getProduct(productId).nftContract);
    }

    function _mintMany(uint256 productId, uint256 count, address base) internal returns (uint256 raised) {
        for (uint256 i; i < count; ++i) {
            vm.prank(admin);
            investment.mintNFT(productId, 1, address(uint160(base) + uint160(i)));
            raised += UNIT;
        }
    }

    function _fund(uint256 productId, uint256 amount) internal {
        usdt.mint(admin, amount);
        vm.prank(admin);
        usdt.approve(address(investment), amount);
        vm.prank(admin);
        investment.deposit(productId, amount);
    }

    function _runDistributionBatch(uint256 productId, uint256 timestamp) internal {
        vm.warp(timestamp);
        vm.prank(admin);
        investment.distributeYield(productId);
    }

    function _runAllDistributionRounds(uint256 productId, uint256 tokenCount) internal {
        uint256[] memory dates = investment.getDistributionDates(productId);
        uint256 batches = (tokenCount + 49) / 50;
        for (uint256 round; round < dates.length; ++round) {
            for (uint256 batch; batch < batches; ++batch) {
                _runDistributionBatch(productId, dates[round]);
            }
        }
    }

    // Sequence 6: clearing an escrow in the middle of a 51-token round cannot recreate or repay that slot.
    function test_06_midRoundClaimThenContinuationAndMaturityPaysYieldOnce() public {
        IInvestmentNFT nft = _register(1, 500, 1);
        uint256 raised = _mintMany(1, 51, alice);
        _fund(1, raised + investment.simulateTotalYield(1));

        usdt.setBlocked(alice, true);
        _runDistributionBatch(1, DISTRIBUTION_START);
        uint256 escrow = investment.getUnclaimedYield(1, 1, 1);
        assertGt(escrow, 0);
        assertEq(investment.getProduct(1).distributedTokenId, 50);

        usdt.setBlocked(alice, false);
        vm.prank(alice);
        investment.claimYield(1, 1, 1);
        _runDistributionBatch(1, DISTRIBUTION_START);
        assertEq(investment.getUnclaimedYield(1, 1, 1), 0, "continued round must not recreate slot 1");

        vm.warp(MATURITY);
        vm.prank(admin);
        investment.maturity(1);
        vm.prank(admin);
        investment.maturity(1);

        assertEq(usdt.balanceOf(alice), UNIT + escrow, "token 1 receives one yield plus principal");
        assertEq(nft.getInvestmentAmount(1), 0, "token 1 burned after principal settlement");
    }

    // Sequence 7: a cleared yield slot stays cleared across subsequent ownership changes.
    function test_07_transferClaimTransferBackDoesNotResurrectYield() public {
        IInvestmentNFT nft = _register(1, 500, 1);
        _mintMany(1, 1, alice);
        _fund(1, UNIT + investment.simulateTotalYield(1));
        usdt.setBlocked(alice, true);
        _runDistributionBatch(1, DISTRIBUTION_START);
        uint256 escrow = investment.getUnclaimedYield(1, 1, 1);

        vm.prank(alice);
        nft.transferFrom(alice, bob, 1);
        vm.prank(bob);
        investment.claimYield(1, 1, 1);
        vm.prank(bob);
        nft.transferFrom(bob, alice, 1);
        usdt.setBlocked(alice, false);

        vm.warp(MATURITY);
        vm.prank(admin);
        investment.maturity(1);
        assertEq(usdt.balanceOf(bob), escrow, "B receives the cleared yield once");
        assertEq(usdt.balanceOf(alice), UNIT, "A receives principal only after transfer back");
        assertEq(investment.getUnclaimedYield(1, 1, 1), 0);
    }

    // Sequence 8: failures inside batch 1 become escrow; the cursor safely starts batch 2 at token 51.
    function test_08_partialMaturityWithFailedTokenDoesNotCorruptCursor() public {
        IInvestmentNFT nft = _register(1, 0, 1);
        uint256 raised = _mintMany(1, 51, alice);
        _fund(1, raised + investment.simulateTotalYield(1));
        _runAllDistributionRounds(1, 51);

        address holder2 = address(uint160(alice) + 1);
        usdt.setBlocked(holder2, true);
        vm.warp(MATURITY);
        vm.prank(admin);
        investment.maturity(1);
        assertEq(investment.getProduct(1).maturedTokenId, 50);
        assertEq(investment.getUnclaimedPrincipal(1, 2), UNIT, "failed token gets principal escrow");

        vm.prank(admin);
        investment.maturity(1);
        Schema.Product memory product = investment.getProduct(1);
        assertTrue(product.isMaturity);
        assertEq(product.maturedTokenId, 51);
        assertEq(nft.getInvestmentAmount(51), 0, "token 51 was not skipped");

        usdt.setBlocked(holder2, false);
        vm.prank(holder2);
        investment.claimPrincipal(1, 2);
        assertEq(usdt.balanceOf(holder2), UNIT, "failed token remains claimable after later batch");
        assertEq(nft.getInvestmentAmount(2), 0);
    }

    // Sequence 9: failed claimPrincipal leaves all slots intact; a successful retry clears all atomically.
    function test_09_failedPrincipalClaimRetryIsAtomicAcrossMultipleYieldSlots() public {
        IInvestmentNFT nft = _register(1, 500, 3);
        _mintMany(1, 1, alice);
        _fund(1, UNIT + investment.simulateTotalYield(1));
        usdt.setBlocked(alice, true);
        _runAllDistributionRounds(1, 1);

        uint256 totalYield;
        for (uint256 i = 1; i <= 3; ++i) totalYield += investment.getUnclaimedYield(1, 1, i);
        assertGt(totalYield, 0);

        vm.warp(MATURITY);
        vm.prank(admin);
        investment.maturity(1);
        assertEq(investment.getUnclaimedPrincipal(1, 1), UNIT);

        vm.expectRevert(IInvestmentErrors.ClaimTransferFailed.selector);
        vm.prank(alice);
        investment.claimPrincipal(1, 1);
        assertEq(investment.getUnclaimedPrincipal(1, 1), UNIT, "principal survives failed claim");
        for (uint256 i = 1; i <= 3; ++i) assertGt(investment.getUnclaimedYield(1, 1, i), 0);

        usdt.setBlocked(alice, false);
        vm.prank(alice);
        investment.claimPrincipal(1, 1);
        assertEq(usdt.balanceOf(alice), UNIT + totalYield, "retry pays exact aggregate once");
        assertEq(investment.getUnclaimedPrincipal(1, 1), 0);
        for (uint256 i = 1; i <= 3; ++i) assertEq(investment.getUnclaimedYield(1, 1, i), 0);
        assertEq(nft.getInvestmentAmount(1), 0);
    }
}
