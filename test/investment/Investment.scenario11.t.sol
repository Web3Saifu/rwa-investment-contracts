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
import {MockInvestmentERC1155} from "test/investment/mocks/MockInvestmentERC1155.sol";
import {MockTierSBT} from "test/investment/mocks/MockTierSBT.sol";

/// @notice ERC721 / ERC1155 混在 OR 判定検証（シナリオ11）
contract InvestmentScenario11Test is MCTest {
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

    function test_scenario11_TierRegistry_Mixed721And1155_ORLogic() public {
        vm.warp(OFFERING_END_DATE - 1 days);

        address investorA = makeAddr("investorA");
        address investorB = makeAddr("investorB");
        address investorC = makeAddr("investorC");

        MockTierSBT bronzeSbt = new MockTierSBT("BronzeSBT", "BRZ");
        MockInvestmentERC1155 bronzePass1155 = new MockInvestmentERC1155();

        // ------------------------------------------------------------------
        // 1. BRONZE tier に [BronzeSBT721, BronzePass1155] を設定
        // ------------------------------------------------------------------
        address[] memory addresses = new address[](2);
        addresses[0] = address(bronzeSbt);
        addresses[1] = address(bronzePass1155);

        vm.startPrank(admin1);
        vm.expectEmit(true, false, false, true);
        emit IInvestmentEvents.TierAllowedByTierAddressUpdated(TIER_BRONZE, addresses);
        investment.setAllowedByTierAddress(TIER_BRONZE, addresses);
        vm.stopPrank();

        address[] memory rowNo1 = investment.getAllowedByTierAddress(TIER_BRONZE);
        assertEq(rowNo1.length, 2, "No1: address length");
        assertEq(rowNo1[0], address(bronzeSbt), "No1: address[0]");
        assertEq(rowNo1[1], address(bronzePass1155), "No1: address[1]");

        // ------------------------------------------------------------------
        // 2. BRONZE tier に tokenId [100] を設定
        // ------------------------------------------------------------------
        uint256[] memory ids = new uint256[](1);
        ids[0] = 100;
        vm.startPrank(admin1);
        vm.expectEmit(true, true, false, true);
        emit IInvestmentEvents.TierAllowedByTierIdUpdated(TIER_BRONZE, address(bronzePass1155), ids);
        investment.setAllowedByTierId(TIER_BRONZE, address(bronzePass1155), ids);
        vm.stopPrank();

        uint256[] memory rowNo2 = investment.getAllowedByTierId(TIER_BRONZE, address(bronzePass1155));
        assertEq(rowNo2.length, 1, "No2: id length");
        assertEq(rowNo2[0], 100, "No2: id[0]");

        // ------------------------------------------------------------------
        // 3. ProductID1 登録（requiredTier=BRONZE）
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
        address nft1 = p1.nftContract;
        assertEq(p1.productId, PRODUCT_ID_1, "No3: productId");
        assertEq(p1.offeringAmount, OFFERING_AMOUNT, "No3: offeringAmount");
        assertEq(p1.minInvestment, MIN_INVESTMENT, "No3: minInvestment");
        assertEq(p1.offeringEndDate, OFFERING_END_DATE, "No3: offeringEndDate");
        assertEq(p1.maturityDate, MATURITY_DATE, "No3: maturityDate");
        assertEq(p1.expectedYield, EXPECTED_YIELD, "No3: expectedYield");
        assertEq(p1.operationStartDate, OPERATION_STARTDATE, "No3: operationStartDate");
        assertEq(p1.distributionStartDate, DISTRIBUTION_START_DATE, "No3: distributionStartDate");
        assertEq(p1.totalDistributionCount, TOTAL_DISTRIBUTION_COUNT, "No3: totalDistributionCount");
        assertEq(p1.distributionInterval, DISTRIBUTION_INTERVAL, "No3: distributionInterval");
        assertEq(p1.requiredTier, TIER_BRONZE, "No3: requiredTier BRONZE");
        assertTrue(p1.isMonthEnd, "No3: isMonthEnd");
        assertEq(p1.raisedAmount, 0, "No3: raisedAmount");
        assertEq(p1.productPool, 0, "No3: productPool");

        // ------------------------------------------------------------------
        // 4-6. 保有条件セット
        // ------------------------------------------------------------------
        bronzeSbt.mint(investorA); // A: 721 only
        bronzePass1155.mint(investorB, 100, 1); // B: 1155 only
        assertGe(bronzeSbt.balanceOf(investorA), 1, "No4: A 721");
        assertEq(bronzePass1155.balanceOf(investorA, 100), 0, "No4: A no 1155");
        assertEq(bronzeSbt.balanceOf(investorB), 0, "No5: B no 721");
        assertGe(bronzePass1155.balanceOf(investorB, 100), 1, "No5: B 1155");
        assertEq(bronzeSbt.balanceOf(investorC), 0, "No6: C no 721");
        assertEq(bronzePass1155.balanceOf(investorC, 100), 0, "No6: C no 1155");

        // ------------------------------------------------------------------
        // 7. A 出資（721 のみ保有）→ 成功
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
        Schema.Product memory pAfter7 = investment.getProduct(PRODUCT_ID_1);
        assertEq(pAfter7.raisedAmount, investAmtA, "No7: raisedAmount");
        assertEq(pAfter7.productPool, investAmtA, "No7: productPool");
        assertEq(InvestmentNFT(nft1).balanceOf(investorA), 1, "No7: NFT A");

        // ------------------------------------------------------------------
        // 8. B 出資（1155 のみ保有）→ 成功
        // ------------------------------------------------------------------
        uint256 unitB = 1;
        uint256 investAmtB = MIN_INVESTMENT * unitB;
        usdt.mint(investorB, investAmtB);
        vm.startPrank(investorB);
        usdt.approve(address(investment), investAmtB);
        vm.expectEmit(true, true, false, true);
        emit IInvestmentEvents.Invested(PRODUCT_ID_1, investorB, unitB, investAmtB, 2);
        investment.invest(PRODUCT_ID_1, unitB);
        vm.stopPrank();
        Schema.Product memory pAfter8 = investment.getProduct(PRODUCT_ID_1);
        assertEq(pAfter8.raisedAmount, investAmtA + investAmtB, "No8: raisedAmount");
        assertEq(pAfter8.productPool, investAmtA + investAmtB, "No8: productPool");
        assertEq(InvestmentNFT(nft1).balanceOf(investorB), 1, "No8: NFT B");

        // ------------------------------------------------------------------
        // 9. C 出資（どちらも未保有）→ NotEligible
        // ------------------------------------------------------------------
        uint256 unitC = 1;
        uint256 investAmtC = MIN_INVESTMENT * unitC;
        usdt.mint(investorC, investAmtC);
        Schema.Product memory pBefore9 = investment.getProduct(PRODUCT_ID_1);
        vm.startPrank(investorC);
        usdt.approve(address(investment), investAmtC);
        vm.expectRevert(abi.encodeWithSelector(IInvestmentErrors.NotEligible.selector, TIER_BRONZE));
        investment.invest(PRODUCT_ID_1, unitC);
        vm.stopPrank();
        Schema.Product memory pAfter9 = investment.getProduct(PRODUCT_ID_1);
        assertEq(pAfter9.raisedAmount, pBefore9.raisedAmount, "No9: raisedAmount unchanged");
        assertEq(InvestmentNFT(nft1).balanceOf(investorC), 0, "No9: no NFT C");

        // ------------------------------------------------------------------
        // 10. 手動Mint investor=B（1155 のみ保有）→ 成功
        // ------------------------------------------------------------------
        vm.startPrank(admin1);
        vm.expectEmit(true, true, false, true);
        emit IInvestmentEvents.Invested(PRODUCT_ID_1, investorB, unitB, investAmtB, 3);
        investment.mintNFT(PRODUCT_ID_1, unitB, investorB);
        vm.stopPrank();

        Schema.Product memory pAfter10 = investment.getProduct(PRODUCT_ID_1);
        assertEq(pAfter10.raisedAmount, investAmtA + investAmtB + investAmtB, "No10: raisedAmount");
        assertEq(pAfter10.productPool, investAmtA + investAmtB, "No10: productPool invest only");
        assertEq(InvestmentNFT(nft1).balanceOf(investorB), 2, "No10: B has 2 NFTs");

        // ------------------------------------------------------------------
        // 11. 最終 Getter 監視
        // ------------------------------------------------------------------
        Schema.Product memory pFinal = investment.getProduct(PRODUCT_ID_1);
        assertEq(pFinal.requiredTier, TIER_BRONZE, "No11: requiredTier");
        assertEq(pFinal.raisedAmount, investAmtA + investAmtB + investAmtB, "No11: raisedAmount");
        assertEq(pFinal.productPool, investAmtA + investAmtB, "No11: productPool");

        address[] memory rowFinalAddr = investment.getAllowedByTierAddress(TIER_BRONZE);
        uint256[] memory rowFinalIds = investment.getAllowedByTierId(TIER_BRONZE, address(bronzePass1155));
        assertEq(rowFinalAddr.length, 2, "No11: address length");
        assertEq(rowFinalAddr[0], address(bronzeSbt), "No11: address[0]");
        assertEq(rowFinalAddr[1], address(bronzePass1155), "No11: address[1]");
        assertEq(rowFinalIds.length, 1, "No11: id length");
        assertEq(rowFinalIds[0], 100, "No11: id[0]");
    }
}
