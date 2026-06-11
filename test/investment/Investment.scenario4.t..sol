// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {MCTest, MCDevKit} from "@mc-devkit/Flattened.sol";

// investment
import {Schema} from "bundle/investment/storage/Schema.sol";
import {IInvestment} from "bundle/investment/interfaces/IInvestment.sol";
import {IInvestmentErrors} from "bundle/investment/interfaces/IInvestmentErrors.sol";
import {InvestmentDeployer} from "script/deploy/InvestmentDeployer.sol";

// periphery
import {IAutomation} from "bundle/periphery/interfaces/IAutomation.sol";
import {Automation} from "bundle/periphery/Automation.sol";

import {MockInvestmentERC20} from "test/investment/mocks/MockInvestmentERC20.sol";

contract InvestmentScenario4Test is MCTest {
    using InvestmentDeployer for MCDevKit;

    IInvestment public investment;
    MockInvestmentERC20 public usdt;
    Automation public automation;

    address safe;
    address admin1;
    address admin2;
    address admin3;
    address admin4;
    address forwarder;
    Schema.RegisterProductArgs registerProductArgs;

    uint256 constant PRODUCT_ID = 1;
    uint256 constant OFFERING_AMOUNT = 1_000_000_000_000; // 1_000_000USD(1USD = 150JPY: 150_000_000JPY)
    uint256 constant MIN_INVESTMENT = 250_000_000; // 250USD(1USD = 150JPY: 37_500JPY)
    uint256 constant OFFERING_END_DATE = 1737763200; // 2025-01-25 00:00:00 UTC
    uint256 constant MATURITY_DATE = 1767225600; // 2026-01-01 00:00:00 UTC
    uint256 constant EXPECTED_YIELD = 500; // 5%
    uint256 constant OPERATION_STARTDATE = 1738368000; // 2025-02-01 00:00:00 UTC
    uint256 constant DISTRIBUTION_START_DATE = 1748736000; // 2025-06-01 00:00:00 UTC
    uint256 constant TOTAL_DISTRIBUTION_COUNT = 3;
    uint256 constant DISTRIBUTION_INTERVAL = 3;

    function setUp() public {
        // Safe, admin1〜4, forwarder
        safe = makeAddr("safe");
        admin1 = makeAddr("admin1");
        admin2 = makeAddr("admin2");
        admin3 = makeAddr("admin3");
        admin4 = makeAddr("admin4");
        forwarder = makeAddr("forwarder");

        // deploy（initialize 時点の admins は空。手順3で Safe が追加する）
        usdt = new MockInvestmentERC20();
        address[] memory initialAdmins = new address[](0);
        address[] memory initialMinters = new address[](1);
        initialMinters[0] = admin2;
        investment =
            IInvestment(InvestmentDeployer.deployInvestment(mc, initialAdmins, initialMinters, address(usdt), safe));
        automation = new Automation(address(investment), forwarder);

        // 手順3: Safe が admin 追加
        vm.startPrank(safe);
        investment.addAdmin(admin1);
        investment.addAdmin(admin2);
        investment.addAdmin(admin3);
        investment.addAdmin(address(automation));
        vm.stopPrank();

        registerProductArgs = Schema.RegisterProductArgs({
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
            baseTokenURI: "https://example.com/metadata/",
            requiredTier: 0
        });
    }

    /// @notice アクセス制御シナリオ（仕様: Safe / ホワイトリスト管理者 / Forwarder の住み分け）
    function test_access_control() public {
        // 手順4: admin3 は管理者追加不可
        vm.startPrank(admin3);
        vm.expectRevert(IInvestmentErrors.NotOwner.selector);
        investment.addAdmin(admin4);
        vm.stopPrank();

        // 手順5: admin3 は管理者削除不可
        vm.startPrank(admin3);
        vm.expectRevert(IInvestmentErrors.NotOwner.selector);
        investment.deleteAdmin(admin2);
        vm.stopPrank();

        // 手順6: Safe はホワイトリスト関数を呼べない
        vm.startPrank(safe);
        vm.expectRevert(IInvestmentErrors.NotMinter.selector);
        investment.mintNFT(1, 1, forwarder);
        vm.expectRevert(IInvestmentErrors.NotAdmin.selector);
        investment.withdraw(1, 10);
        vm.expectRevert(IInvestmentErrors.NotAdmin.selector);
        investment.deposit(1, 100);
        vm.expectRevert(IInvestmentErrors.NotAdmin.selector);
        investment.registerProduct(registerProductArgs);
        vm.expectRevert(IInvestmentErrors.NotAdmin.selector);
        investment.distributeYield(1);
        vm.expectRevert(IInvestmentErrors.NotAdmin.selector);
        investment.maturity(1);
        vm.expectRevert(IInvestmentErrors.NotAdmin.selector);
        investment.setAllowedByTierAddress(1, new address[](0));
        vm.stopPrank();

        // 手順7: admin2 はホワイトリスト関数を実行できる（権限エラーにならない）
        vm.startPrank(admin2);
        investment.registerProduct(registerProductArgs);
        investment.mintNFT(PRODUCT_ID, 10, forwarder);
        usdt.mint(admin2, 50_000_000_000_000);
        usdt.approve(address(investment), 50_000_000_000_000);
        investment.deposit(PRODUCT_ID, 50_000_000_000_000);
        investment.withdraw(PRODUCT_ID, 10);

        address[] memory emptySbts = new address[](0);
        investment.setAllowedByTierAddress(1, emptySbts);

        uint256[] memory distDates = investment.getDistributionDates(PRODUCT_ID);
        assertEq(distDates.length, TOTAL_DISTRIBUTION_COUNT, "distribution dates length");

        vm.warp(distDates[0]);
        investment.distributeYield(PRODUCT_ID);
        vm.stopPrank();

        // 手順8・9: performUpkeep は Forwarder のみ（中身の decode 前に NotForwarder）
        vm.prank(safe);
        vm.expectRevert(abi.encodeWithSelector(IAutomation.NotForwarder.selector, safe));
        automation.performUpkeep("");

        vm.prank(admin2);
        vm.expectRevert(abi.encodeWithSelector(IAutomation.NotForwarder.selector, admin2));
        automation.performUpkeep("");

        // 手順10: Forwarder は performUpkeep で分配を実行できる（Automation が Investment の admin）
        vm.warp(distDates[1]);
        (bool upkeepNeeded, bytes memory performData) = automation.checkUpkeep("");
        assertTrue(upkeepNeeded, "upkeep expected before 2nd distribution");
        (IAutomation.ActionType actionType, uint256 pid) = abi.decode(performData, (IAutomation.ActionType, uint256));
        assertEq(uint8(actionType), uint8(IAutomation.ActionType.DistributeYield), "expected DistributeYield");
        assertEq(pid, PRODUCT_ID, "productId mismatch");

        vm.prank(forwarder);
        automation.performUpkeep(performData);

        // 手順:7の続き
        vm.startPrank(admin2);
        vm.warp(distDates[2]);
        investment.distributeYield(PRODUCT_ID);

        vm.warp(MATURITY_DATE);
        investment.maturity(PRODUCT_ID);
        vm.stopPrank();
    }

    receive() external payable {}
}
