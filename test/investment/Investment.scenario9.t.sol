// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {MCTest} from "@mc-devkit/Flattened.sol";

import {Schema} from "bundle/investment/storage/Schema.sol";
import {IInvestment} from "bundle/investment/interfaces/IInvestment.sol";
import {IInvestmentErrors} from "bundle/investment/interfaces/IInvestmentErrors.sol";
import {IInvestmentEvents} from "bundle/investment/interfaces/IInvestmentEvents.sol";
import {InvestmentDeployer} from "script/deploy/InvestmentDeployer.sol";

import {InvestmentNFT} from "bundle/periphery/InvestmentNFT.sol";

import {MockInvestmentERC20} from "test/investment/mocks/MockInvestmentERC20.sol";
import {MockTierSBT} from "test/investment/mocks/MockTierSBT.sol";

/// @notice 中央 TierRegistry 更新のみで既存商品の可否が変わることを検証（シナリオ9）
contract InvestmentScenario9Test is MCTest {
    IInvestment public investment;
    MockInvestmentERC20 public usdt;

    address safe;
    address admin1;
    address[] admins;

    uint256 constant PRODUCT_ID_1 = 1;
    uint8 constant TIER_BRONZE = 1;

    uint256 constant OFFERING_AMOUNT = 1_000_000_000_000; // 1,000,000 USDT
    uint256 constant MIN_INVESTMENT = 250_000_000; // 250 USDT
    uint256 constant OFFERING_END_DATE = 1831939200; // 2028-01-20 00:00:00 UTC
    uint256 constant MATURITY_DATE = 1840665600; // 2028-04-30 00:00:00 UTC
    uint256 constant EXPECTED_YIELD = 500; // 5%
    uint256 constant OPERATION_STARTDATE = 1832889600; // 2028-01-31 00:00:00 UTC
    uint256 constant DISTRIBUTION_START_DATE = 1835395200; // 2028-02-29 00:00:00 UTC
    uint256 constant TOTAL_DISTRIBUTION_COUNT = 2;
    uint256 constant DISTRIBUTION_INTERVAL = 1; // 1 month

    string constant BASE_TOKEN_URI = "https://example.com/metadata/";

    function setUp() public {
        safe = makeAddr("safe");
        admin1 = makeAddr("admin1");
        admins.push(admin1);

        usdt = new MockInvestmentERC20();
        vm.prank(safe);
        investment = IInvestment(InvestmentDeployer.deployInvestment(mc, admins, admins, address(usdt), safe));
    }

    function test_scenario9_TierRegistry_Update_AffectsExistingProduct() public {
        // invest / mintNFT の両方が許可される時間帯
        vm.warp(OFFERING_END_DATE - 1 days);

        address investorA = makeAddr("investorA");
        address investorB = makeAddr("investorB");

        MockTierSBT bronzeSbt = new MockTierSBT("BronzeSBT", "BRZ");
        MockTierSBT silverSbt = new MockTierSBT("SilverSBT", "SLV");
        MockTierSBT goldSbt = new MockTierSBT("GoldSBT", "GLD");

        // ------------------------------------------------------------------
        // 1. BRONZE tier = [BronzeSBT]
        // ------------------------------------------------------------------
        address[] memory bronzeOnly = new address[](1);
        bronzeOnly[0] = address(bronzeSbt);

        vm.startPrank(admin1);
        vm.expectEmit(true, false, false, true);
        emit IInvestmentEvents.TierAllowedByTierAddressUpdated(TIER_BRONZE, bronzeOnly);
        investment.setAllowedByTierAddress(TIER_BRONZE, bronzeOnly);
        vm.stopPrank();

        address[] memory rowNo2 = investment.getAllowedByTierAddress(TIER_BRONZE);
        assertEq(rowNo2.length, 1, "No2: tier row length");
        assertEq(rowNo2[0], address(bronzeSbt), "No2: tier row[0]");

        // ------------------------------------------------------------------
        // 2. ProductID1 登録（requiredTier = BRONZE）
        // ------------------------------------------------------------------
        Schema.RegisterProductArgs memory args = Schema.RegisterProductArgs({
            productId: PRODUCT_ID_1,
            offeringAmount: OFFERING_AMOUNT,
            minInvestment: MIN_INVESTMENT,
            offeringEndDate: OFFERING_END_DATE,
            maturityDate: MATURITY_DATE,
            expectedYield: EXPECTED_YIELD,
            operationStartDate: OPERATION_STARTDATE,
            distributionStartDate: DISTRIBUTION_START_DATE,
            totalDistributionCount: TOTAL_DISTRIBUTION_COUNT,
            distributionInterval: DISTRIBUTION_INTERVAL,
            baseTokenURI: BASE_TOKEN_URI,
            requiredTier: TIER_BRONZE
        });

        vm.prank(admin1);
        investment.registerProduct(args);

        Schema.Product memory p1 = investment.getProduct(PRODUCT_ID_1);
        assertEq(p1.productId, PRODUCT_ID_1, "No1: productId");
        assertEq(p1.offeringAmount, OFFERING_AMOUNT, "No1: offeringAmount");
        assertEq(p1.minInvestment, MIN_INVESTMENT, "No1: minInvestment");
        assertEq(p1.offeringEndDate, OFFERING_END_DATE, "No1: offeringEndDate");
        assertEq(p1.maturityDate, MATURITY_DATE, "No1: maturityDate");
        assertEq(p1.expectedYield, EXPECTED_YIELD, "No1: expectedYield");
        assertEq(p1.operationStartDate, OPERATION_STARTDATE, "No1: operationStartDate");
        assertEq(p1.distributionStartDate, DISTRIBUTION_START_DATE, "No1: distributionStartDate");
        assertEq(p1.totalDistributionCount, TOTAL_DISTRIBUTION_COUNT, "No1: totalDistributionCount");
        assertEq(p1.distributionInterval, DISTRIBUTION_INTERVAL, "No1: distributionInterval");
        assertEq(p1.requiredTier, TIER_BRONZE, "No1: requiredTier BRONZE");
        assertTrue(p1.isMonthEnd, "No1: isMonthEnd");
        assertEq(p1.raisedAmount, 0, "No1: raisedAmount");
        assertEq(p1.productPool, 0, "No1: productPool");

        address nft1 = p1.nftContract;

        // ------------------------------------------------------------------
        // 3. A に Silver、B に Gold を付与（A/B とも Bronze 未保有）
        // ------------------------------------------------------------------
        silverSbt.mint(investorA);
        goldSbt.mint(investorB);

        assertGe(silverSbt.balanceOf(investorA), 1, "No3: A silver >= 1");
        assertEq(bronzeSbt.balanceOf(investorA), 0, "No3: A bronze == 0");
        assertEq(goldSbt.balanceOf(investorA), 0, "No3: A gold == 0");

        assertGe(goldSbt.balanceOf(investorB), 1, "No3: B gold >= 1");
        assertEq(bronzeSbt.balanceOf(investorB), 0, "No3: B bronze == 0");
        assertEq(silverSbt.balanceOf(investorB), 0, "No3: B silver == 0");

        // ------------------------------------------------------------------
        // 4. A が出資（Silver のみ保有）→ NotEligible
        // ------------------------------------------------------------------
        uint256 unitA = 1;
        uint256 investAmtA = MIN_INVESTMENT * unitA;
        usdt.mint(investorA, investAmtA);

        Schema.Product memory pBefore4 = investment.getProduct(PRODUCT_ID_1);
        vm.startPrank(investorA);
        usdt.approve(address(investment), investAmtA);
        vm.expectRevert(abi.encodeWithSelector(IInvestmentErrors.NotEligible.selector, TIER_BRONZE));
        investment.invest(PRODUCT_ID_1, unitA);
        vm.stopPrank();

        Schema.Product memory pAfter4 = investment.getProduct(PRODUCT_ID_1);
        assertEq(pAfter4.raisedAmount, pBefore4.raisedAmount, "No4: raisedAmount unchanged");
        assertEq(pAfter4.productPool, pBefore4.productPool, "No4: productPool unchanged");
        assertEq(InvestmentNFT(nft1).balanceOf(investorA), 0, "No4: no NFT for A");

        // ------------------------------------------------------------------
        // 5. BRONZE tier = [Bronze, Silver, Gold] に置換
        // ------------------------------------------------------------------
        address[] memory bronzeSilverGold = new address[](3);
        bronzeSilverGold[0] = address(bronzeSbt);
        bronzeSilverGold[1] = address(silverSbt);
        bronzeSilverGold[2] = address(goldSbt);

        vm.startPrank(admin1);
        vm.expectEmit(true, false, false, true);
        emit IInvestmentEvents.TierAllowedByTierAddressUpdated(TIER_BRONZE, bronzeSilverGold);
        investment.setAllowedByTierAddress(TIER_BRONZE, bronzeSilverGold);
        vm.stopPrank();

        address[] memory rowNo5 = investment.getAllowedByTierAddress(TIER_BRONZE);
        assertEq(rowNo5.length, 3, "No5: tier row length");
        assertEq(rowNo5[0], address(bronzeSbt), "No5: row[0]");
        assertEq(rowNo5[1], address(silverSbt), "No5: row[1]");
        assertEq(rowNo5[2], address(goldSbt), "No5: row[2]");

        // ------------------------------------------------------------------
        // 6. A が再出資（Silver のみ保有）→ 成功
        // ------------------------------------------------------------------
        vm.startPrank(investorA);
        vm.expectEmit(true, true, false, true);
        emit IInvestmentEvents.Invested(PRODUCT_ID_1, investorA, unitA, investAmtA, 1);
        investment.invest(PRODUCT_ID_1, unitA);
        vm.stopPrank();

        Schema.Product memory pAfter6 = investment.getProduct(PRODUCT_ID_1);
        assertEq(pAfter6.requiredTier, TIER_BRONZE, "No6: requiredTier unchanged");
        assertEq(pAfter6.raisedAmount, investAmtA, "No6: raisedAmount");
        assertEq(pAfter6.productPool, investAmtA, "No6: productPool");
        assertEq(InvestmentNFT(nft1).balanceOf(investorA), 1, "No6: NFT for A");

        // ------------------------------------------------------------------
        // 7. 手動 MintNFT（investor=B、Gold のみ保有）→ 成功
        // ------------------------------------------------------------------
        uint256 unitB = 1;
        uint256 investAmtB = MIN_INVESTMENT * unitB;

        vm.startPrank(admin1);
        vm.expectEmit(true, true, false, true);
        emit IInvestmentEvents.Invested(PRODUCT_ID_1, investorB, unitB, investAmtB, 2);
        investment.mintNFT(PRODUCT_ID_1, unitB, investorB);
        vm.stopPrank();

        Schema.Product memory pAfter7 = investment.getProduct(PRODUCT_ID_1);
        assertEq(pAfter7.raisedAmount, investAmtA + investAmtB, "No7: raisedAmount");
        assertEq(pAfter7.productPool, investAmtA, "No7: productPool invest only");
        assertEq(InvestmentNFT(nft1).balanceOf(investorB), 1, "No7: NFT for B");

        // ------------------------------------------------------------------
        // 8. Getter 監視: requiredTier と TierRegistry
        // ------------------------------------------------------------------
        Schema.Product memory pFinal = investment.getProduct(PRODUCT_ID_1);
        assertEq(pFinal.requiredTier, TIER_BRONZE, "No8: requiredTier still BRONZE");
        assertEq(pFinal.raisedAmount, investAmtA + investAmtB, "No8: final raisedAmount");
        assertEq(pFinal.productPool, investAmtA, "No8: final productPool");

        address[] memory rowFinal = investment.getAllowedByTierAddress(TIER_BRONZE);
        assertEq(rowFinal.length, 3, "No8: final row length");
        assertEq(rowFinal[0], address(bronzeSbt), "No8: final row[0]");
        assertEq(rowFinal[1], address(silverSbt), "No8: final row[1]");
        assertEq(rowFinal[2], address(goldSbt), "No8: final row[2]");
    }
}
