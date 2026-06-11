// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {MCTest, MCDevKit} from "@mc-devkit/Flattened.sol";

import {Schema} from "bundle/investment/storage/Schema.sol";
import {IInvestment} from "bundle/investment/interfaces/IInvestment.sol";
import {IInvestmentErrors} from "bundle/investment/interfaces/IInvestmentErrors.sol";
import {IInvestmentEvents} from "bundle/investment/interfaces/IInvestmentEvents.sol";
import {InvestmentDeployer} from "script/deploy/InvestmentDeployer.sol";
import {CalculateYieldLib} from "bundle/investment/utils/CalculateYieldLib.sol";
import {DistributionDateLib} from "bundle/investment/utils/DistributionDateLib.sol";

import {IInvestmentNFT} from "bundle/periphery/interfaces/IInvestmentNFT.sol";
import {MockInvestmentERC20} from "test/investment/mocks/MockInvestmentERC20.sol";

/**
 * @title F-2026-17221 GetClaimableYieldSlots mid-round visibility
 * @notice Regression: getClaimableYieldSlots must expose escrow entries written
 *         during an in-progress multi-batch distribution round.
 */
contract F202617221GetClaimableYieldSlotsMidRoundTest is MCTest {
    IInvestment investment;
    MockInvestmentERC20 usdt;

    address safe;
    address admin;
    address investor1;
    address[] admins;

    uint256 constant PRODUCT_ID = 1;
    uint256 constant OFFERING_AMOUNT = 1_000_000_000_000;
    uint256 constant MIN_INVESTMENT = 250_000_000;
    uint256 constant OFFERING_END_DATE = 1737763200;
    uint256 constant MATURITY_DATE = 1767225600;
    uint256 constant EXPECTED_YIELD = 500;
    uint256 constant OPERATION_STARTDATE = 1738368000;
    uint256 constant DISTRIBUTION_START_DATE = 1748736000;
    uint256 constant TOTAL_DISTRIBUTION_COUNT = 3;
    uint256 constant DISTRIBUTION_INTERVAL = 3;

    uint256 constant TOTAL_INVESTORS = 60;
    uint256 constant BLOCKED_TOKEN_ID = 30;

    function setUp() public {
        safe = makeAddr("safe");
        admin = makeAddr("admin");
        investor1 = makeAddr("investor1");
        admins.push(admin);

        usdt = new MockInvestmentERC20();
        vm.prank(safe);
        investment = IInvestment(InvestmentDeployer.deployInvestment(mc, admins, admins, address(usdt), safe));
    }

    function _registerAndMintAll() internal returns (IInvestmentNFT nft, uint256 individualYield) {
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

        uint256 units = (OFFERING_AMOUNT / TOTAL_INVESTORS) / MIN_INVESTMENT;
        uint256 actualInvestPerUser = units * MIN_INVESTMENT;

        for (uint256 i = 0; i < TOTAL_INVESTORS; i++) {
            address holderAddr = address(uint160(uint160(investor1) + i));
            usdt.mint(holderAddr, actualInvestPerUser);
            vm.prank(holderAddr);
            usdt.approve(address(investment), actualInvestPerUser);
            vm.prank(holderAddr);
            investment.invest(PRODUCT_ID, units);
        }

        product = investment.getProduct(PRODUCT_ID);

        uint256 firstPeriod =
            DistributionDateLib.calculateFirstDistributionPeriod(DISTRIBUTION_START_DATE, OPERATION_STARTDATE);
        uint256 periodYield =
            CalculateYieldLib.calculatePeriodYield(product.raisedAmount, product.expectedYield, firstPeriod);
        individualYield =
            CalculateYieldLib.calculateIndividualPeriodYield(periodYield, actualInvestPerUser, product.raisedAmount);

        uint256 tolerance = CalculateYieldLib.calculatePeriodTolerance(nft.tokenIdCounter());
        uint256 poolAmount = periodYield + tolerance;
        usdt.mint(admin, poolAmount);
        vm.prank(admin);
        usdt.approve(address(investment), poolAmount);
        vm.prank(admin);
        investment.deposit(PRODUCT_ID, poolAmount);
    }

    /// @notice After the first sub-batch (ids 1-50), mid-round escrow entries must be visible
    function test_getClaimableYieldSlots_exposesMidRoundEscrow() public {
        (, uint256 individualYield) = _registerAndMintAll();

        address blockedHolder = address(uint160(uint160(investor1) + (BLOCKED_TOKEN_ID - 1)));
        usdt.setBlocked(blockedHolder, true);

        vm.warp(DISTRIBUTION_START_DATE);

        vm.prank(admin);
        investment.distributeYield(PRODUCT_ID);

        Schema.Product memory product = investment.getProduct(PRODUCT_ID);
        assertEq(product.distributedCount, 0, "round still in progress");
        assertEq(product.distributedTokenId, 50, "first sub-batch stopped at 50");

        assertEq(
            investment.getUnclaimedYield(PRODUCT_ID, BLOCKED_TOKEN_ID, 1),
            individualYield,
            "direct getter exposes the in-progress escrow entry"
        );

        Schema.ClaimableYieldSlot[] memory slots = investment.getClaimableYieldSlots(PRODUCT_ID, BLOCKED_TOKEN_ID);
        assertEq(slots.length, 1, "mid-round escrow slot must be visible");
        assertEq(slots[0].distributionIndex, 1);
        assertEq(slots[0].amount, individualYield);
    }

    /// @notice getClaimableForToken must also expose mid-round escrow via getClaimableYieldSlots
    function test_getClaimableForToken_exposesMidRoundEscrow() public {
        (, uint256 individualYield) = _registerAndMintAll();

        address blockedHolder = address(uint160(uint160(investor1) + (BLOCKED_TOKEN_ID - 1)));
        usdt.setBlocked(blockedHolder, true);

        vm.warp(DISTRIBUTION_START_DATE);

        vm.prank(admin);
        investment.distributeYield(PRODUCT_ID);

        Schema.TokenClaimableStatus memory status =
            investment.getClaimableForToken(PRODUCT_ID, BLOCKED_TOKEN_ID, blockedHolder);
        assertEq(status.yieldSlots.length, 1, "getClaimableForToken must expose mid-round slot");
        assertEq(status.yieldSlots[0].distributionIndex, 1);
        assertEq(status.yieldSlots[0].amount, individualYield);
    }

    /// @notice After the second sub-batch completes the round, slots remain visible
    function test_getClaimableYieldSlots_stillVisibleAfterRoundCompletes() public {
        (, uint256 individualYield) = _registerAndMintAll();

        address blockedHolder = address(uint160(uint160(investor1) + (BLOCKED_TOKEN_ID - 1)));
        usdt.setBlocked(blockedHolder, true);

        vm.warp(DISTRIBUTION_START_DATE);

        vm.prank(admin);
        investment.distributeYield(PRODUCT_ID);

        vm.prank(admin);
        investment.distributeYield(PRODUCT_ID);

        Schema.Product memory product = investment.getProduct(PRODUCT_ID);
        assertEq(product.distributedCount, 1, "round completed");

        Schema.ClaimableYieldSlot[] memory slots = investment.getClaimableYieldSlots(PRODUCT_ID, BLOCKED_TOKEN_ID);
        assertEq(slots.length, 1, "slot visible after round completion");
        assertEq(slots[0].distributionIndex, 1);
        assertEq(slots[0].amount, individualYield);
    }

    /// @notice No false positives for tokens without escrow during mid-round
    function test_getClaimableYieldSlots_emptyForNonEscrowedToken() public {
        _registerAndMintAll();

        vm.warp(DISTRIBUTION_START_DATE);

        vm.prank(admin);
        investment.distributeYield(PRODUCT_ID);

        Schema.Product memory product = investment.getProduct(PRODUCT_ID);
        assertEq(product.distributedCount, 0, "round still in progress");

        Schema.ClaimableYieldSlot[] memory slots = investment.getClaimableYieldSlots(PRODUCT_ID, 1);
        assertEq(slots.length, 0, "non-escrowed token must return empty");
    }

    /// @notice When all distributions are complete, maxIndex is capped at totalDistributionCount
    function test_getClaimableYieldSlots_cappedAtTotalDistributionCount() public {
        _registerAndMintAll();

        vm.warp(DISTRIBUTION_START_DATE);

        vm.prank(admin);
        investment.distributeYield(PRODUCT_ID);
        vm.prank(admin);
        investment.distributeYield(PRODUCT_ID);

        Schema.Product memory product = investment.getProduct(PRODUCT_ID);
        assertEq(product.distributedCount, 1, "first round complete");

        Schema.ClaimableYieldSlot[] memory slots = investment.getClaimableYieldSlots(PRODUCT_ID, 1);
        assertEq(slots.length, 0, "non-escrowed token still empty after round completion");
    }
}
