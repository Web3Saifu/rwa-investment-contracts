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

/// @notice TierRegistry・requiredTier・Invest / MintNFT の一連検証（シナリオ8）
contract InvestmentScenario8Test is MCTest {
    IInvestment public investment;
    MockInvestmentERC20 public usdt;

    address safe;
    address admin1;
    address[] admins;

    uint256 constant PRODUCT_ID_1 = 1;
    uint256 constant PRODUCT_ID_2 = 2;
    uint8 constant TIER_NONE = 0;
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

    function test_scenario8_TierRegistry_Register_Invest_MintNFT() public {
        vm.warp(OFFERING_END_DATE - 1 days);

        address investorA = makeAddr("investorA");
        address investorB = makeAddr("investorB");
        address investorC = makeAddr("investorC");

        MockTierSBT bronzeSbt = new MockTierSBT("BronzeSBT", "BRZ");

        // ------------------------------------------------------------------
        // 1. TierRegistry 初期状態（BRONZE）
        // ------------------------------------------------------------------
        address[] memory bronzeRow0 = investment.getAllowedByTierAddress(TIER_BRONZE);
        assertEq(bronzeRow0.length, 0, "No1: BRONZE allowedByTierAddress should be empty");

        // ------------------------------------------------------------------
        // 2. ProductID1 登録（requiredTier = NONE）
        // ------------------------------------------------------------------
        Schema.RegisterProductArgs memory args1 = Schema.RegisterProductArgs({
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
            requiredTier: TIER_NONE
        });

        vm.prank(admin1);
        investment.registerProduct(args1);

        Schema.Product memory p1 = investment.getProduct(PRODUCT_ID_1);
        assertEq(p1.productId, args1.productId, "No2: productId");
        assertEq(p1.offeringAmount, args1.offeringAmount, "No2: offeringAmount");
        assertEq(p1.minInvestment, args1.minInvestment, "No2: minInvestment");
        assertEq(p1.offeringEndDate, args1.offeringEndDate, "No2: offeringEndDate");
        assertEq(p1.maturityDate, args1.maturityDate, "No2: maturityDate");
        assertEq(p1.expectedYield, args1.expectedYield, "No2: expectedYield");
        assertEq(p1.operationStartDate, args1.operationStartDate, "No2: operationStartDate");
        assertEq(p1.distributionStartDate, args1.distributionStartDate, "No2: distributionStartDate");
        assertEq(p1.totalDistributionCount, args1.totalDistributionCount, "No2: totalDistributionCount");
        assertEq(p1.distributionInterval, args1.distributionInterval, "No2: distributionInterval");
        assertEq(p1.requiredTier, TIER_NONE, "No2: requiredTier NONE");
        assertTrue(p1.isMonthEnd, "No2: isMonthEnd (2028-02-29)");
        assertEq(p1.raisedAmount, 0, "No2: raisedAmount");
        assertEq(p1.productPool, 0, "No2: productPool");

        // ------------------------------------------------------------------
        // 3. BRONZE に BronzeSBT を登録
        // ------------------------------------------------------------------
        address[] memory sbts = new address[](1);
        sbts[0] = address(bronzeSbt);

        vm.startPrank(admin1);
        vm.expectEmit(true, false, false, true);
        emit IInvestmentEvents.TierAllowedByTierAddressUpdated(TIER_BRONZE, sbts);
        investment.setAllowedByTierAddress(TIER_BRONZE, sbts);
        vm.stopPrank();

        address[] memory bronzeRow3 = investment.getAllowedByTierAddress(TIER_BRONZE);
        assertEq(bronzeRow3.length, 1, "No3: one SBT");
        assertEq(bronzeRow3[0], address(bronzeSbt), "No3: BronzeSBT");

        // ------------------------------------------------------------------
        // 4. ProductID2 登録（requiredTier = BRONZE）
        // ------------------------------------------------------------------
        Schema.RegisterProductArgs memory args2 = args1;
        args2.productId = PRODUCT_ID_2;
        args2.requiredTier = TIER_BRONZE;

        vm.prank(admin1);
        investment.registerProduct(args2);

        Schema.Product memory p2reg = investment.getProduct(PRODUCT_ID_2);
        assertEq(p2reg.productId, PRODUCT_ID_2, "No4: productId");
        assertEq(p2reg.requiredTier, TIER_BRONZE, "No4: requiredTier BRONZE");
        assertEq(p2reg.raisedAmount, 0, "No4: raisedAmount");

        // ------------------------------------------------------------------
        // 5. Getter: requiredTier
        // ------------------------------------------------------------------
        assertEq(investment.getProduct(PRODUCT_ID_1).requiredTier, TIER_NONE, "No5: P1 requiredTier");
        assertEq(investment.getProduct(PRODUCT_ID_2).requiredTier, TIER_BRONZE, "No5: P2 requiredTier");

        address nft1 = investment.getProduct(PRODUCT_ID_1).nftContract;
        address nft2 = investment.getProduct(PRODUCT_ID_2).nftContract;

        // ------------------------------------------------------------------
        // 6. ProductID1 出資：投資家A（SBT 未保有）
        // ------------------------------------------------------------------
        uint256 unitA = 1;
        uint256 investAmtA = MIN_INVESTMENT * unitA;

        usdt.mint(investorA, investAmtA);
        vm.startPrank(investorA);
        usdt.approve(address(investment), investAmtA);
        vm.expectEmit(true, true, false, true);
        emit IInvestmentEvents.Invested(PRODUCT_ID_1, investorA, unitA, investAmtA, 1);
        investment.invest(PRODUCT_ID_1, unitA);
        vm.stopPrank();

        Schema.Product memory p1AfterA = investment.getProduct(PRODUCT_ID_1);
        assertEq(p1AfterA.raisedAmount, investAmtA, "No6: P1 raisedAmount");
        assertEq(p1AfterA.productPool, investAmtA, "No6: P1 productPool");
        assertEq(InvestmentNFT(nft1).balanceOf(investorA), 1, "No6: P1 NFT A");

        // ------------------------------------------------------------------
        // 7. ProductID2 出資：投資家B（SBT 未保有）→ NotEligible
        // ------------------------------------------------------------------
        uint256 unitB = 1;
        uint256 investAmtB = MIN_INVESTMENT * unitB;
        uint256 bBalBefore = usdt.balanceOf(investorB);
        Schema.Product memory p2Before6 = investment.getProduct(PRODUCT_ID_2);

        usdt.mint(investorB, investAmtB);
        vm.startPrank(investorB);
        usdt.approve(address(investment), investAmtB);
        vm.expectRevert(abi.encodeWithSelector(IInvestmentErrors.NotEligible.selector, TIER_BRONZE));
        investment.invest(PRODUCT_ID_2, unitB);
        vm.stopPrank();

        assertEq(usdt.balanceOf(investorB), bBalBefore + investAmtB, "No7: B USDT unchanged (revert)");
        Schema.Product memory p2After7 = investment.getProduct(PRODUCT_ID_2);
        assertEq(p2After7.raisedAmount, p2Before6.raisedAmount, "No7: P2 raisedAmount unchanged");
        assertEq(p2After7.productPool, p2Before6.productPool, "No7: P2 productPool unchanged");
        assertEq(InvestmentNFT(nft2).balanceOf(investorB), 0, "No7: P2 no NFT for B");

        // ------------------------------------------------------------------
        // 8. ProductID2 再出資：B（SBT まだ未保有）→ 依然 NotEligible
        // ------------------------------------------------------------------
        Schema.Product memory p2Before8 = investment.getProduct(PRODUCT_ID_2);
        vm.startPrank(investorB);
        vm.expectRevert(abi.encodeWithSelector(IInvestmentErrors.NotEligible.selector, TIER_BRONZE));
        investment.invest(PRODUCT_ID_2, unitB);
        vm.stopPrank();

        Schema.Product memory p2After8 = investment.getProduct(PRODUCT_ID_2);
        assertEq(p2After8.raisedAmount, p2Before8.raisedAmount, "No8: P2 raisedAmount unchanged");
        assertEq(InvestmentNFT(nft2).balanceOf(investorB), 0, "No8: P2 still no NFT");

        // ------------------------------------------------------------------
        // 9. B に BronzeSBT 付与
        // ------------------------------------------------------------------
        bronzeSbt.mint(investorB);
        assertGe(bronzeSbt.balanceOf(investorB), 1, "No9: B holds SBT");

        // ------------------------------------------------------------------
        // 10. ProductID2 出資：B（SBT 保有）→ 成功
        // ------------------------------------------------------------------
        vm.startPrank(investorB);
        vm.expectEmit(true, true, false, true);
        emit IInvestmentEvents.Invested(PRODUCT_ID_2, investorB, unitB, investAmtB, 1);
        investment.invest(PRODUCT_ID_2, unitB);
        vm.stopPrank();

        Schema.Product memory p2After10 = investment.getProduct(PRODUCT_ID_2);
        assertEq(p2After10.raisedAmount, investAmtB, "No10: P2 raisedAmount");
        assertEq(p2After10.productPool, investAmtB, "No10: P2 productPool");
        assertEq(InvestmentNFT(nft2).balanceOf(investorB), 1, "No10: P2 NFT B");

        // ------------------------------------------------------------------
        // 11. 手動 MintNFT：investor=C、SBT 未保有 → 成功（tier は minter 側で検証）
        // ------------------------------------------------------------------
        uint256 unitC = 1;
        uint256 investAmtC = MIN_INVESTMENT * unitC;
        Schema.Product memory p2Before11 = investment.getProduct(PRODUCT_ID_2);

        vm.startPrank(admin1);
        vm.expectEmit(true, true, false, true);
        emit IInvestmentEvents.Invested(PRODUCT_ID_2, investorC, unitC, investAmtC, 2);
        investment.mintNFT(PRODUCT_ID_2, unitC, investorC);
        vm.stopPrank();

        Schema.Product memory p2After11 = investment.getProduct(PRODUCT_ID_2);
        assertEq(p2After11.raisedAmount, p2Before11.raisedAmount + investAmtC, "No11: raisedAmount");
        assertEq(p2After11.productPool, p2Before11.productPool, "No11: productPool (mint does not add)");
        assertEq(InvestmentNFT(nft2).balanceOf(investorC), 1, "No11: C NFT");

        // ------------------------------------------------------------------
        // 12. C に BronzeSBT 付与（invest 経路の tier 検証用。mintNFT は tier 非依存）
        // ------------------------------------------------------------------
        bronzeSbt.mint(investorC);
        assertGe(bronzeSbt.balanceOf(investorC), 1, "No12: C holds SBT");

        // ------------------------------------------------------------------
        // 13. 最終 Getter 監視
        // ------------------------------------------------------------------
        Schema.Product memory p1Final = investment.getProduct(PRODUCT_ID_1);
        assertEq(p1Final.requiredTier, TIER_NONE, "No13: P1 requiredTier");
        assertEq(p1Final.raisedAmount, investAmtA, "No13: P1 raisedAmount");
        assertEq(p1Final.productPool, investAmtA, "No13: P1 productPool");

        Schema.Product memory p2Final = investment.getProduct(PRODUCT_ID_2);
        assertEq(p2Final.requiredTier, TIER_BRONZE, "No13: P2 requiredTier");
        assertEq(p2Final.raisedAmount, investAmtB + investAmtC, "No13: P2 raisedAmount");
        assertEq(p2Final.productPool, investAmtB, "No13: P2 productPool (Invest only, not MintNFT)");

        address[] memory bronzeFinal = investment.getAllowedByTierAddress(TIER_BRONZE);
        assertEq(bronzeFinal.length, 1, "No13: tier registry length");
        assertEq(bronzeFinal[0], address(bronzeSbt), "No13: tier registry SBT");
    }
}
