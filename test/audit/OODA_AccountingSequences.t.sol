// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {MCTest} from "@mc-devkit/Flattened.sol";

import {Schema} from "bundle/investment/storage/Schema.sol";
import {IInvestment} from "bundle/investment/interfaces/IInvestment.sol";
import {InvestmentDeployer} from "script/deploy/InvestmentDeployer.sol";
import {IInvestmentNFT} from "bundle/periphery/interfaces/IInvestmentNFT.sol";
import {MockInvestmentERC20} from "test/investment/mocks/MockInvestmentERC20.sol";

contract OODAAccountingSequencesTest is MCTest {
    IInvestment internal investment;
    MockInvestmentERC20 internal usdt;

    address internal safe;
    address internal admin;
    address internal alice;
    address internal bob;

    uint256 internal constant UNIT = 100_000_000;
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

    function _register(uint256 productId, uint256 expectedYield) internal returns (IInvestmentNFT nft) {
        Schema.RegisterProductArgs memory args = Schema.RegisterProductArgs({
            productId: productId,
            offeringAmount: 100 * UNIT,
            minInvestment: UNIT,
            offeringEndDate: OFFERING_END,
            maturityDate: MATURITY,
            expectedYield: expectedYield,
            operationStartDate: OPERATION_START,
            distributionStartDate: DISTRIBUTION_START,
            totalDistributionCount: 1,
            distributionInterval: 0,
            baseTokenURI: "",
            requiredTier: 0
        });
        vm.prank(admin);
        investment.registerProduct(args);
        nft = IInvestmentNFT(investment.getProduct(productId).nftContract);
    }

    function _invest(uint256 productId, address holder) internal {
        usdt.mint(holder, UNIT);
        vm.prank(holder);
        usdt.approve(address(investment), UNIT);
        vm.prank(holder);
        investment.invest(productId, 1);
    }

    function _deposit(uint256 productId, uint256 amount) internal {
        usdt.mint(admin, amount);
        vm.prank(admin);
        usdt.approve(address(investment), amount);
        vm.prank(admin);
        investment.deposit(productId, amount);
    }

    function _distribute(uint256 productId) internal {
        vm.warp(DISTRIBUTION_START);
        vm.prank(admin);
        investment.distributeYield(productId);
    }

    function _mature(uint256 productId) internal {
        vm.warp(MATURITY);
        vm.prank(admin);
        investment.maturity(productId);
    }

    function _withdraw(uint256 productId, uint256 amount) internal {
        vm.prank(admin);
        investment.withdraw(productId, amount);
    }

    // Sequence 1: another product can withdraw only its own pool; P1's yield escrow remains physically backed.
    function test_01_crossProductDepositWithdrawCannotConsumeYieldEscrow() public {
        _register(1, 500);
        _register(2, 0);
        _invest(1, alice);
        _withdraw(1, UNIT);

        uint256 yieldFunding = investment.simulateTotalYield(1);
        _deposit(1, yieldFunding);
        uint256 aliceYield = investment.simulateIndividualPeriodYield(1, 1)[0];
        usdt.setBlocked(alice, true);
        _distribute(1);

        uint256 escrow = investment.getUnclaimedYield(1, 1, 1);
        assertEq(escrow, aliceYield, "P1 yield must be escrowed");

        _deposit(2, 7 * UNIT);
        _withdraw(2, 7 * UNIT);

        uint256 p1Pool = investment.getProduct(1).productPool;
        assertEq(usdt.balanceOf(address(investment)), p1Pool + escrow, "pool plus escrow must remain backed");

        usdt.setBlocked(alice, false);
        vm.prank(alice);
        investment.claimYield(1, 1, 1);
        assertEq(usdt.balanceOf(alice), aliceYield, "escrow claimant receives exact yield");
        assertEq(usdt.balanceOf(address(investment)), p1Pool, "claim consumes escrow backing only");
    }

    // Sequence 2: claim order across products does not create insolvency.
    function test_02_yieldThenPrincipalClaimsRemainBackedInEitherOrder() public {
        _register(1, 500);
        _register(2, 0);
        _invest(1, alice);
        _invest(2, bob);
        _deposit(1, investment.simulateTotalYield(1));
        uint256 aliceYield = investment.simulateIndividualPeriodYield(1, 1)[0];
        usdt.setBlocked(alice, true);
        _distribute(1);

        _distribute(2);
        usdt.setBlocked(bob, true);
        _mature(2);

        assertEq(investment.getUnclaimedPrincipal(2, 1), UNIT, "P2 principal escrow exists");
        usdt.setBlocked(alice, false);
        vm.prank(alice);
        investment.claimYield(1, 1, 1);
        assertGe(usdt.balanceOf(address(investment)), UNIT, "P2 principal remains backed after P1 claim");

        usdt.setBlocked(bob, false);
        vm.prank(bob);
        investment.claimPrincipal(2, 1);
        assertEq(usdt.balanceOf(bob), UNIT, "P2 principal remains claimable");
        assertEq(usdt.balanceOf(alice), aliceYield, "P1 received one yield payment");
    }

    // Sequence 3: a different product's withdrawable pool excludes P1's principal escrow economically.
    function test_03_crossProductWithdrawCannotConsumePrincipalEscrow() public {
        _register(1, 0);
        _register(2, 0);
        _invest(1, alice);
        _distribute(1);
        usdt.setBlocked(alice, true);
        _mature(1);
        assertEq(investment.getUnclaimedPrincipal(1, 1), UNIT);

        _deposit(2, 9 * UNIT);
        _withdraw(2, 9 * UNIT);
        assertEq(usdt.balanceOf(address(investment)), UNIT, "principal escrow backing must remain");

        usdt.setBlocked(alice, false);
        vm.prank(alice);
        investment.claimPrincipal(1, 1);
        assertEq(usdt.balanceOf(alice), UNIT);
        assertEq(usdt.balanceOf(address(investment)), 0);
    }

    // Sequence 4: global P2 liquidity cannot bypass P1's per-product pool check.
    function test_04_offchainMintCannotUseAnotherProductsLiquidityAtMaturity() public {
        IInvestmentNFT p1Nft = _register(1, 0);
        vm.prank(admin);
        investment.mintNFT(1, 1, alice);

        _register(2, 0);
        _deposit(1, investment.simulateTotalYield(1));
        _deposit(2, UNIT);
        _distribute(1);
        _mature(1);

        Schema.Product memory p1 = investment.getProduct(1);
        assertTrue(p1.isInsufficientBalance, "P1 must be flagged underfunded");
        assertFalse(p1.isMaturity, "P1 must not settle with P2 funds");
        assertEq(p1Nft.ownerOf(1), alice, "P1 NFT remains outstanding");
        assertEq(
            usdt.balanceOf(address(investment)),
            UNIT + investment.getProduct(1).productPool,
            "P2 liquidity is untouched"
        );
        assertEq(investment.getProduct(2).productPool, UNIT, "P2 pool accounting is intact");
    }

    // Sequence 5: settling and withdrawing P1's surplus cannot consume P2 principal.
    function test_05_settleFirstProductThenWithdrawSurplusDoesNotBreakSecond() public {
        _register(1, 0);
        _register(2, 0);
        _invest(1, alice);
        _invest(2, bob);
        _deposit(1, UNIT / 2);
        _distribute(1);
        _distribute(2);

        _mature(1);
        _withdraw(1, UNIT / 2);
        assertEq(usdt.balanceOf(address(investment)), UNIT, "P2 principal remains after P1 settlement and withdrawal");

        _mature(2);
        assertEq(usdt.balanceOf(bob), UNIT, "P2 settles in full");
        assertEq(usdt.balanceOf(address(investment)), 0);
    }
}
