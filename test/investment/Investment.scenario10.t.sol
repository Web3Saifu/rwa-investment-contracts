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

/// @notice ERC1155 TierRegistry 基本動作検証（シナリオ10）
contract InvestmentScenario10Test is MCTest {
    IInvestment public investment;
    MockInvestmentERC20 public usdt;

    address safe;
    address admin1;
    address[] admins;

    uint256 constant PRODUCT_ID_1 = 1;
    uint8 constant TIER_SILVER = 2;

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

    function test_scenario10_TierRegistry_ERC1155_Register_Invest_MintNFT() public {
        vm.warp(OFFERING_END_DATE - 1 days);

        address investorA = makeAddr("investorA");
        address investorB = makeAddr("investorB");
        address investorC = makeAddr("investorC");
        address investorD = makeAddr("investorD");

        MockInvestmentERC1155 pass1155 = new MockInvestmentERC1155();
        MockInvestmentERC1155 pass1155B = new MockInvestmentERC1155();

        // ------------------------------------------------------------------
        // 1. SILVER tier 初期状態
        // ------------------------------------------------------------------
        address[] memory silverRow0 = investment.getAllowedByTierAddress(TIER_SILVER);
        uint256[] memory idsRow0 = investment.getAllowedByTierId(TIER_SILVER, address(pass1155));
        assertEq(silverRow0.length, 0, "No1: allowedByTierAddress empty");
        assertEq(idsRow0.length, 0, "No1: allowedByTierId empty");

        // ------------------------------------------------------------------
        // 2. SILVER tier に ERC1155Address 設定
        // ------------------------------------------------------------------
        address[] memory allowedAddresses = new address[](1);
        allowedAddresses[0] = address(pass1155);

        vm.startPrank(admin1);
        vm.expectEmit(true, false, false, true);
        emit IInvestmentEvents.TierAllowedByTierAddressUpdated(TIER_SILVER, allowedAddresses);
        investment.setAllowedByTierAddress(TIER_SILVER, allowedAddresses);
        vm.stopPrank();

        address[] memory silverRow2 = investment.getAllowedByTierAddress(TIER_SILVER);
        assertEq(silverRow2.length, 1, "No2: address length");
        assertEq(silverRow2[0], address(pass1155), "No2: address[0]");
        assertEq(investment.getAllowedByTierId(TIER_SILVER, address(pass1155)).length, 0, "No2: id still empty");

        // ------------------------------------------------------------------
        // 3. ProductID1 登録（requiredTier = SILVER）
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
            requiredTier: TIER_SILVER
        });

        vm.prank(admin1);
        investment.registerProduct(args);

        Schema.Product memory p1 = investment.getProduct(PRODUCT_ID_1);
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
        assertEq(p1.requiredTier, TIER_SILVER, "No3: requiredTier SILVER");
        assertTrue(p1.isMonthEnd, "No3: isMonthEnd");
        assertEq(p1.raisedAmount, 0, "No3: raisedAmount");
        assertEq(p1.productPool, 0, "No3: productPool");
        address nft1 = p1.nftContract;

        // ------------------------------------------------------------------
        // 4. A 出資（未保有）→ NotEligible
        // ------------------------------------------------------------------
        uint256 unitA = 1;
        uint256 investAmtA = MIN_INVESTMENT * unitA;
        usdt.mint(investorA, investAmtA);

        Schema.Product memory pBefore4 = investment.getProduct(PRODUCT_ID_1);
        vm.startPrank(investorA);
        usdt.approve(address(investment), investAmtA);
        vm.expectRevert(abi.encodeWithSelector(IInvestmentErrors.NotEligible.selector, TIER_SILVER));
        investment.invest(PRODUCT_ID_1, unitA);
        vm.stopPrank();

        Schema.Product memory pAfter4 = investment.getProduct(PRODUCT_ID_1);
        assertEq(pAfter4.raisedAmount, pBefore4.raisedAmount, "No4: raisedAmount unchanged");
        assertEq(pAfter4.productPool, pBefore4.productPool, "No4: productPool unchanged");
        assertEq(InvestmentNFT(nft1).balanceOf(investorA), 0, "No4: no NFT for A");

        // ------------------------------------------------------------------
        // 5. SILVER tier に tokenId [2,3] 設定
        // ------------------------------------------------------------------
        uint256[] memory ids = new uint256[](2);
        ids[0] = 2;
        ids[1] = 3;

        vm.startPrank(admin1);
        vm.expectEmit(true, true, false, true);
        emit IInvestmentEvents.TierAllowedByTierIdUpdated(TIER_SILVER, address(pass1155), ids);
        investment.setAllowedByTierId(TIER_SILVER, address(pass1155), ids);
        vm.stopPrank();

        uint256[] memory idsRow5 = investment.getAllowedByTierId(TIER_SILVER, address(pass1155));
        assertEq(idsRow5.length, 2, "No5: id length");
        assertEq(idsRow5[0], 2, "No5: id[0]");
        assertEq(idsRow5[1], 3, "No5: id[1]");

        // ------------------------------------------------------------------
        // 6. A 再出資（まだ未保有）→ NotEligible
        // ------------------------------------------------------------------
        Schema.Product memory pBefore6 = investment.getProduct(PRODUCT_ID_1);
        vm.startPrank(investorA);
        vm.expectRevert(abi.encodeWithSelector(IInvestmentErrors.NotEligible.selector, TIER_SILVER));
        investment.invest(PRODUCT_ID_1, unitA);
        vm.stopPrank();
        Schema.Product memory pAfter6 = investment.getProduct(PRODUCT_ID_1);
        assertEq(pAfter6.raisedAmount, pBefore6.raisedAmount, "No6: raisedAmount unchanged");
        assertEq(pAfter6.productPool, pBefore6.productPool, "No6: productPool unchanged");

        // ------------------------------------------------------------------
        // 7. A に id=2 を付与
        // ------------------------------------------------------------------
        pass1155.mint(investorA, 2, 1);
        assertGe(pass1155.balanceOf(investorA, 2), 1, "No7: A has id=2");
        assertEq(pass1155.balanceOf(investorA, 3), 0, "No7: A id=3 optional");

        // ------------------------------------------------------------------
        // 8. A 出資（id=2 保有）→ 成功
        // ------------------------------------------------------------------
        vm.startPrank(investorA);
        vm.expectEmit(true, true, false, true);
        emit IInvestmentEvents.Invested(PRODUCT_ID_1, investorA, unitA, investAmtA, 1);
        investment.invest(PRODUCT_ID_1, unitA);
        vm.stopPrank();

        Schema.Product memory pAfter8 = investment.getProduct(PRODUCT_ID_1);
        assertEq(pAfter8.raisedAmount, investAmtA, "No8: raisedAmount");
        assertEq(pAfter8.productPool, investAmtA, "No8: productPool");
        assertEq(InvestmentNFT(nft1).balanceOf(investorA), 1, "No8: NFT A");

        // ------------------------------------------------------------------
        // 9. 手動Mint investor=B（ERC1155 未保有）→ 成功（tier は minter 側で検証）
        // ------------------------------------------------------------------
        uint256 unitB = 1;
        uint256 investAmtB = MIN_INVESTMENT * unitB;

        vm.startPrank(admin1);
        vm.expectEmit(true, true, false, true);
        emit IInvestmentEvents.Invested(PRODUCT_ID_1, investorB, unitB, investAmtB, 2);
        investment.mintNFT(PRODUCT_ID_1, unitB, investorB);
        vm.stopPrank();

        Schema.Product memory pAfter9 = investment.getProduct(PRODUCT_ID_1);
        assertEq(pAfter9.raisedAmount, investAmtA + investAmtB, "No9: raisedAmount");
        assertEq(pAfter9.productPool, investAmtA, "No9: productPool (mint does not add)");
        assertEq(InvestmentNFT(nft1).balanceOf(investorB), 1, "No9: NFT B");

        // ------------------------------------------------------------------
        // 10. B に id=2 を付与（invest 経路の tier 検証用。mintNFT は tier 非依存）
        // ------------------------------------------------------------------
        pass1155.mint(investorB, 2, 1);
        assertGe(pass1155.balanceOf(investorB, 2), 1, "No10: B has id=2");

        // ------------------------------------------------------------------
        // 11. C に id=3 を付与後に出資（OR 条件）→ 成功
        // ------------------------------------------------------------------
        uint256 unitC = 1;
        uint256 investAmtC = MIN_INVESTMENT * unitC;
        pass1155.mint(investorC, 3, 1);
        usdt.mint(investorC, investAmtC);
        assertGe(pass1155.balanceOf(investorC, 3), 1, "No11: C has id=3");

        vm.startPrank(investorC);
        usdt.approve(address(investment), investAmtC);
        vm.expectEmit(true, true, false, true);
        emit IInvestmentEvents.Invested(PRODUCT_ID_1, investorC, unitC, investAmtC, 3);
        investment.invest(PRODUCT_ID_1, unitC);
        vm.stopPrank();
        Schema.Product memory pAfter11 = investment.getProduct(PRODUCT_ID_1);
        assertEq(pAfter11.raisedAmount, investAmtA + investAmtB + investAmtC, "No11: raisedAmount");
        assertEq(pAfter11.productPool, investAmtA + investAmtC, "No11: productPool");
        assertEq(InvestmentNFT(nft1).balanceOf(investorC), 1, "No11: NFT C");

        // ------------------------------------------------------------------
        // 12. SILVER tier に 2つ目の ERC1155（pass1155B）を追加
        // ------------------------------------------------------------------
        address[] memory allowedAddresses2 = new address[](2);
        allowedAddresses2[0] = address(pass1155);
        allowedAddresses2[1] = address(pass1155B);

        uint256[] memory idsB = new uint256[](1);
        idsB[0] = 77;

        vm.startPrank(admin1);
        vm.expectEmit(true, false, false, true);
        emit IInvestmentEvents.TierAllowedByTierAddressUpdated(TIER_SILVER, allowedAddresses2);
        investment.setAllowedByTierAddress(TIER_SILVER, allowedAddresses2);

        // ------------------------------------------------------------------
        // 13. pass1155B に tokenId [77] を設定
        // ------------------------------------------------------------------
        vm.expectEmit(true, true, false, true);
        emit IInvestmentEvents.TierAllowedByTierIdUpdated(TIER_SILVER, address(pass1155B), idsB);
        investment.setAllowedByTierId(TIER_SILVER, address(pass1155B), idsB);
        vm.stopPrank();

        // ------------------------------------------------------------------
        // 14. 投資家D に pass1155B tokenId=2 を付与して出資 → NotEligible（混線しない）
        // ------------------------------------------------------------------
        pass1155B.mint(investorD, 2, 1);
        assertGe(pass1155B.balanceOf(investorD, 2), 1, "No14: D has pass1155B id=2");

        uint256 unitD = 1;
        uint256 investAmtD = MIN_INVESTMENT * unitD;
        usdt.mint(investorD, investAmtD);
        vm.startPrank(investorD);
        usdt.approve(address(investment), investAmtD);
        vm.expectRevert(abi.encodeWithSelector(IInvestmentErrors.NotEligible.selector, TIER_SILVER));
        investment.invest(PRODUCT_ID_1, unitD);
        vm.stopPrank();

        // ------------------------------------------------------------------
        // 15. 投資家D に pass1155B tokenId=77 を付与して出資 → 成功
        // ------------------------------------------------------------------
        pass1155B.mint(investorD, 77, 1);
        assertGe(pass1155B.balanceOf(investorD, 77), 1, "No15: D has pass1155B id=77");

        vm.startPrank(investorD);
        vm.expectEmit(true, true, false, true);
        emit IInvestmentEvents.Invested(PRODUCT_ID_1, investorD, unitD, investAmtD, 4);
        investment.invest(PRODUCT_ID_1, unitD);
        vm.stopPrank();

        // ------------------------------------------------------------------
        // 16. 最終 Getter 監視
        // ------------------------------------------------------------------
        Schema.Product memory pFinal = investment.getProduct(PRODUCT_ID_1);
        assertEq(pFinal.requiredTier, TIER_SILVER, "No16: requiredTier");
        assertEq(pFinal.raisedAmount, investAmtA + investAmtB + investAmtC + investAmtD, "No16: raisedAmount");
        assertEq(pFinal.productPool, investAmtA + investAmtC + investAmtD, "No16: productPool");

        address[] memory finalAddresses = investment.getAllowedByTierAddress(TIER_SILVER);
        uint256[] memory finalIds = investment.getAllowedByTierId(TIER_SILVER, address(pass1155));
        uint256[] memory finalIdsB = investment.getAllowedByTierId(TIER_SILVER, address(pass1155B));
        assertEq(finalAddresses.length, 2, "No16: address length");
        assertEq(finalAddresses[0], address(pass1155), "No16: address[0]");
        assertEq(finalAddresses[1], address(pass1155B), "No16: address[1]");
        assertEq(finalIds.length, 2, "No16: id(pass1155) length");
        assertEq(finalIds[0], 2, "No16: id(pass1155)[0]");
        assertEq(finalIds[1], 3, "No16: id(pass1155)[1]");
        assertEq(finalIdsB.length, 1, "No16: id(pass1155B) length");
        assertEq(finalIdsB[0], 77, "No16: id(pass1155B)[0]");
    }
}
