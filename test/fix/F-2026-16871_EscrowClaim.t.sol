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
 * @title F-2026-16871 EscrowClaim tests
 * @notice Audit PoC: push transfer failure must not block batch liveness; claim by current NFT owner
 */
contract F202616871EscrowClaimTest is MCTest {
    IInvestment investment;
    MockInvestmentERC20 usdt;

    address safe;
    address admin;
    address investor1;
    address investor2;
    address newOwner;
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

    function setUp() public {
        safe = makeAddr("safe");
        admin = makeAddr("admin");
        investor1 = makeAddr("investor1");
        investor2 = makeAddr("investor2");
        newOwner = makeAddr("newOwner");
        admins.push(admin);

        usdt = new MockInvestmentERC20();
        vm.prank(safe);
        investment = IInvestment(InvestmentDeployer.deployInvestment(mc, admins, admins, address(usdt), safe));
    }

    function _registerAndInvest() internal returns (IInvestmentNFT nft, uint256 yield2) {
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
        uint256 invest2 = invest1;

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
        uint256 poolAmount = periodYield + tolerance;
        usdt.mint(admin, poolAmount);
        vm.prank(admin);
        usdt.approve(address(investment), poolAmount);
        vm.prank(admin);
        investment.deposit(PRODUCT_ID, poolAmount);
    }

    function test_blacklist_doesNotBlockBatch() public {
        (IInvestmentNFT nft, uint256 yield2) = _registerAndInvest();
        nft; // silence unused in some builds

        usdt.setBlocked(investor2, true);

        vm.warp(DISTRIBUTION_START_DATE);
        vm.prank(admin);
        investment.distributeYield(PRODUCT_ID);

        Schema.Product memory product = investment.getProduct(PRODUCT_ID);
        assertEq(product.distributedCount, 1);
        assertGt(usdt.balanceOf(investor1), 0);
        assertEq(usdt.balanceOf(investor2), 0);
        assertEq(investment.getUnclaimedYield(PRODUCT_ID, 2, 1), yield2);
    }

    function test_maturity_after_partial_escrow() public {
        _registerAndInvest();

        usdt.setBlocked(investor2, true);
        vm.warp(DISTRIBUTION_START_DATE);
        vm.prank(admin);
        investment.distributeYield(PRODUCT_ID);

        vm.warp(MATURITY_DATE);
        vm.prank(admin);
        investment.maturity(PRODUCT_ID);

        Schema.Product memory product = investment.getProduct(PRODUCT_ID);
        assertTrue(product.isMaturity);
        assertEq(product.distributedCount, TOTAL_DISTRIBUTION_COUNT);
    }

    function test_claimYield_afterNftTransfer() public {
        _registerAndInvest();

        usdt.setBlocked(investor2, true);
        vm.warp(DISTRIBUTION_START_DATE);
        vm.prank(admin);
        investment.distributeYield(PRODUCT_ID);

        Schema.Product memory product = investment.getProduct(PRODUCT_ID);
        IInvestmentNFT nft = IInvestmentNFT(product.nftContract);

        vm.prank(investor2);
        IERC721(address(nft)).transferFrom(investor2, newOwner, 2);

        usdt.setBlocked(investor2, false);
        usdt.setBlocked(newOwner, false);

        vm.prank(newOwner);
        investment.claimYield(PRODUCT_ID, 2, 1);

        assertEq(investment.getUnclaimedYield(PRODUCT_ID, 2, 1), 0);
        assertGt(usdt.balanceOf(newOwner), 0);
    }

    function test_claimYield_reverts_whenStillBlacklisted() public {
        (, uint256 yield2) = _registerAndInvest();

        usdt.setBlocked(investor2, true);
        vm.warp(DISTRIBUTION_START_DATE);
        vm.prank(admin);
        investment.distributeYield(PRODUCT_ID);

        vm.prank(investor2);
        vm.expectRevert(IInvestmentErrors.ClaimTransferFailed.selector);
        investment.claimYield(PRODUCT_ID, 2, 1);

        assertEq(investment.getUnclaimedYield(PRODUCT_ID, 2, 1), yield2);
    }
}
