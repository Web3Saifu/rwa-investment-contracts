// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {MCTest} from "@mc-devkit/Flattened.sol";

// investment
import {Storage} from "bundle/investment/storage/Storage.sol";
import {Schema} from "bundle/investment/storage/Schema.sol";
import {IInvestment} from "bundle/investment/interfaces/IInvestment.sol";
import {IInvestmentErrors} from "bundle/investment/interfaces/IInvestmentErrors.sol";
import {IInvestmentEvents} from "bundle/investment/interfaces/IInvestmentEvents.sol";
import {InvestmentDeployer} from "script/deploy/InvestmentDeployer.sol";
import {CalculateYieldLib} from "bundle/investment/utils/CalculateYieldLib.sol";

// periphery
import {IAutomation} from "bundle/periphery/interfaces/IAutomation.sol";
import {Automation} from "bundle/periphery/Automation.sol";
import {IInvestmentNFT} from "bundle/periphery/interfaces/IInvestmentNFT.sol";
import {InvestmentNFT} from "bundle/periphery/InvestmentNFT.sol";

import {MockInvestmentERC20} from "test/investment/mocks/MockInvestmentERC20.sol";

contract InvestmentZeroYieldScenarioTest is MCTest {
    IInvestment public investment;
    MockInvestmentERC20 public usdt;
    Automation public automation;

    address safe;
    address admin1;
    address forwarder;
    address investor1;
    address investor2;

    function setUp() public {
        safe = makeAddr("safe");
        admin1 = makeAddr("admin1");
        forwarder = makeAddr("forwarder");
        investor1 = makeAddr("investor1");
        investor2 = makeAddr("investor2");

        address[] memory admins = new address[](1);
        admins[0] = admin1;

        usdt = new MockInvestmentERC20();
        vm.prank(safe);
        investment = IInvestment(InvestmentDeployer.deployInvestment(mc, admins, admins, address(usdt), safe));
        automation = new Automation(address(investment), forwarder);

        vm.prank(safe);
        investment.addAdmin(address(automation));
    }

    function test_zeroYield_longMaturity_singleDistribution_zeroPayout_thenMaturity() public {
        // Setup dates
        uint256 nowTs = 1735689600; // 2025-01-01 00:00:00 UTC
        vm.warp(nowTs);

        uint256 productId = 101;
        uint256 offeringAmount = 1_000_000_000_000; // 1,000,000 USD (scaled 1e6)
        uint256 minInvestment = 250_000_000; // 250 USD
        uint256 offeringEndDate = nowTs + 24 days; // 2025-01-25 00:00:00 UTC 相当
        uint256 operationStartDate = offeringEndDate; // 運用開始は募集終了と同日
        uint256 maturityDate = nowTs + (1000 * 365 days); // 実質無期限（yearsは非推奨）
        uint256 distributionStartDate = operationStartDate; // 運用開始と同日
        uint256 expectedYield = 0; // 0%
        uint256 totalDistributionCount = 1;
        uint256 distributionInterval = 0; // totalDistributionCount==1 なら 0 許容

        Schema.RegisterProductArgs memory registerArgs = Schema.RegisterProductArgs({
            productId: productId,
            offeringAmount: offeringAmount,
            minInvestment: minInvestment,
            offeringEndDate: offeringEndDate,
            maturityDate: maturityDate,
            expectedYield: expectedYield,
            operationStartDate: operationStartDate,
            distributionStartDate: distributionStartDate,
            totalDistributionCount: totalDistributionCount,
            distributionInterval: distributionInterval,
            baseTokenURI: "https://example.com/metadata/",
            requiredTier: 0
        });

        // Register
        vm.prank(admin1);
        investment.registerProduct(registerArgs);

        // Mint half in JPY path (admin mint)
        uint256 halfOffering = offeringAmount / 2;
        uint256 amountPer2 = halfOffering / 2;
        uint256 unitCount1 = amountPer2 / minInvestment;
        uint256 unitCount2 = amountPer2 / minInvestment;
        vm.startPrank(admin1);
        investment.mintNFT(productId, unitCount1, investor1);
        investment.mintNFT(productId, unitCount2, investor2);
        vm.stopPrank();

        // Invest remaining half in USDT path
        usdt.mint(investor1, amountPer2);
        vm.startPrank(investor1);
        usdt.approve(address(investment), amountPer2);
        investment.invest(productId, unitCount1);
        vm.stopPrank();

        usdt.mint(investor2, amountPer2);
        vm.startPrank(investor2);
        usdt.approve(address(investment), amountPer2);
        investment.invest(productId, unitCount2);
        vm.stopPrank();

        // Ensure raisedAmount == offeringAmount
        Schema.Product memory product = investment.getProduct(productId);
        assertEq(product.raisedAmount, offeringAmount, "raisedAmount mismatch");

        // Withdraw productPool fully to simulate zero pool prior to deposit
        uint256 poolBefore = usdt.balanceOf(address(investment));
        vm.prank(admin1);
        investment.withdraw(productId, poolBefore);
        assertEq(usdt.balanceOf(address(investment)), 0, "pool not withdrawn");

        // Deposit only principal back (since expectedYield=0、分配トレランスは自動側が考慮する)
        vm.startPrank(admin1);
        usdt.mint(admin1, offeringAmount);
        usdt.approve(address(investment), offeringAmount);
        investment.deposit(productId, offeringAmount);
        vm.stopPrank();

        // Move time to distributionStartDate（運用開始と同日）
        vm.warp(distributionStartDate);

        // CheckUpkeep should return DistributeYield first
        (bool upkeepDist, bytes memory dataDist) = Automation(address(automation)).checkUpkeep("");
        (IAutomation.ActionType actionDist, uint256 pidDist) = abi.decode(dataDist, (IAutomation.ActionType, uint256));
        assertTrue(upkeepDist, "no upkeep for distribution");
        assertEq(uint8(actionDist), uint8(IAutomation.ActionType.DistributeYield), "not DistributeYield");
        assertEq(pidDist, productId, "productId mismatch");

        // Capture balances before distribution
        uint256 inv1Before = usdt.balanceOf(investor1);
        uint256 inv2Before = usdt.balanceOf(investor2);
        uint256 investmentBefore = usdt.balanceOf(address(investment));

        // Perform distribution (should distribute 0)
        vm.prank(forwarder);
        Automation(address(automation)).performUpkeep(dataDist);

        Schema.Product memory afterDist = investment.getProduct(productId);
        assertEq(afterDist.distributedCount, 1, "distributedCount mismatch");
        assertEq(usdt.balanceOf(investor1) - inv1Before, 0, "non-zero distribution investor1");
        assertEq(usdt.balanceOf(investor2) - inv2Before, 0, "non-zero distribution investor2");
        assertEq(investmentBefore - usdt.balanceOf(address(investment)), 0, "pool reduced by distribution");

        // Next, maturity should be required
        // Ensure time has advanced to maturity (covers both cases: distributionStartDate ==/!= maturityDate)
        vm.warp(maturityDate);
        (bool upkeepMat, bytes memory dataMat) = Automation(address(automation)).checkUpkeep("");
        (IAutomation.ActionType actionMat, uint256 pidMat) = abi.decode(dataMat, (IAutomation.ActionType, uint256));
        assertTrue(upkeepMat, "no upkeep for maturity");
        assertEq(uint8(actionMat), uint8(IAutomation.ActionType.Maturity), "not Maturity");
        assertEq(pidMat, productId, "productId mismatch (maturity)");

        uint256 inv1BeforeMat = usdt.balanceOf(investor1);
        uint256 inv2BeforeMat = usdt.balanceOf(investor2);
        uint256 poolBeforeMat = usdt.balanceOf(address(investment));

        // Capture NFT principals before maturity (NFTs will be burned during maturity)
        Schema.Product memory beforeMat = investment.getProduct(productId);
        IInvestmentNFT.NFTInfo[] memory nftInfos = IInvestmentNFT(beforeMat.nftContract).getNFTInfos(1);
        uint256 principalInv1 = 0;
        uint256 principalInv2 = 0;
        uint256 totalPrincipal = 0;
        for (uint256 i = 0; i < nftInfos.length; i++) {
            totalPrincipal += nftInfos[i].investmentAmount;
            if (nftInfos[i].owner == investor1) {
                principalInv1 += nftInfos[i].investmentAmount;
            }
            if (nftInfos[i].owner == investor2) {
                principalInv2 += nftInfos[i].investmentAmount;
            }
        }

        // Perform maturity (should return principal and burn NFTs)
        vm.prank(forwarder);
        Automation(address(automation)).performUpkeep(dataMat);

        Schema.Product memory afterMat = investment.getProduct(productId);
        assertTrue(afterMat.isMaturity, "not matured");
        assertEq(usdt.balanceOf(investor1) - inv1BeforeMat, principalInv1, "principal investor1 mismatch");
        assertEq(usdt.balanceOf(investor2) - inv2BeforeMat, principalInv2, "principal investor2 mismatch");
        assertEq(afterMat.totalReturnedAmount, totalPrincipal, "totalReturnedAmount mismatch");
        assertEq(poolBeforeMat - usdt.balanceOf(address(investment)), afterMat.totalReturnedAmount, "pool mismatch");
    }

    receive() external payable {}
}
