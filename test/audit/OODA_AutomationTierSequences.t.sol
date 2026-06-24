// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {MCTest} from "@mc-devkit/Flattened.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import {Schema} from "bundle/investment/storage/Schema.sol";
import {IInvestment} from "bundle/investment/interfaces/IInvestment.sol";
import {IInvestmentErrors} from "bundle/investment/interfaces/IInvestmentErrors.sol";
import {InvestmentDeployer} from "script/deploy/InvestmentDeployer.sol";
import {IAutomation} from "bundle/periphery/interfaces/IAutomation.sol";
import {Automation} from "bundle/periphery/Automation.sol";
import {MockInvestmentERC20} from "test/investment/mocks/MockInvestmentERC20.sol";

contract OODAUnavailableTierSBT {
    fallback() external { revert("SBT unavailable"); }
}

contract OODAValidTierSBT is ERC721 {
    constructor() ERC721("Valid Tier", "TIER") {}
    function mint(address to) external { _mint(to, 1); }
}

contract OODAAutomationTierSequencesTest is MCTest {
    IInvestment internal investment;
    MockInvestmentERC20 internal usdt;
    Automation internal automation;
    address internal safe;
    address internal admin;
    address internal forwarder;
    address internal alice;

    uint256 internal constant UNIT = 1_000_000;
    uint256 internal constant OFFERING_END = 1_737_763_200;
    uint256 internal constant OPERATION_START = 1_738_368_000;
    uint256 internal constant DISTRIBUTION_START = 1_748_736_000;
    uint256 internal constant MATURITY = 1_830_297_600;

    function setUp() public {
        safe = makeAddr("safe");
        admin = makeAddr("admin");
        forwarder = makeAddr("forwarder");
        alice = makeAddr("alice");
        address[] memory operators = new address[](1);
        operators[0] = admin;
        usdt = new MockInvestmentERC20();
        vm.prank(safe);
        investment = IInvestment(InvestmentDeployer.deployInvestment(mc, operators, operators, address(usdt), safe));
        automation = new Automation(address(investment), forwarder);
        vm.prank(safe);
        investment.addAdmin(address(automation));
    }

    function _register(uint256 productId, uint256 distributionCount, uint256 maturity, uint8 tier) internal {
        vm.prank(admin);
        investment.registerProduct(
            Schema.RegisterProductArgs({
                productId: productId,
                offeringAmount: 100 * UNIT,
                minInvestment: UNIT,
                offeringEndDate: OFFERING_END,
                maturityDate: maturity,
                expectedYield: 500,
                operationStartDate: OPERATION_START,
                distributionStartDate: DISTRIBUTION_START,
                totalDistributionCount: distributionCount,
                distributionInterval: distributionCount == 1 ? 0 : 1,
                baseTokenURI: "",
                requiredTier: tier
            })
        );
    }

    function _perform(bytes memory data) internal {
        vm.prank(forwarder);
        automation.performUpkeep(data);
    }

    function _deposit(uint256 productId, uint256 amount) internal {
        usdt.mint(admin, amount);
        vm.prank(admin);
        usdt.approve(address(investment), amount);
        vm.prank(admin);
        investment.deposit(productId, amount);
    }

    function test_20_stalePerformDataCannotBypassDownstreamRoundGuards() public {
        _register(1, 3, MATURITY, 0);
        uint256[] memory dates = investment.getDistributionDates(1);
        vm.warp(dates[2]);
        (bool needed, bytes memory staleData) = automation.checkUpkeep("");
        assertTrue(needed);

        _perform(staleData);
        _perform(staleData);
        _perform(staleData);
        assertEq(investment.getProduct(1).distributedCount, 3, "each overdue round advances once");

        vm.expectRevert(IInvestmentErrors.DistributionCompleted.selector);
        vm.prank(forwarder);
        automation.performUpkeep(staleData);
    }

    function test_21_maturityCannotRunBeforeAllSimultaneouslyDueRounds() public {
        _register(1, 2, MATURITY, 0);
        uint256[] memory dates = investment.getDistributionDates(1);
        vm.warp(MATURITY > dates[1] ? MATURITY : dates[1]);
        bytes memory prematureMaturity = abi.encode(IAutomation.ActionType.Maturity, uint256(1));

        vm.expectRevert(IInvestmentErrors.BeforeDistributionCompleted.selector);
        vm.prank(forwarder);
        automation.performUpkeep(prematureMaturity);

        for (uint256 i; i < 2; ++i) {
            (bool needed, bytes memory data) = automation.checkUpkeep("");
            assertTrue(needed);
            (IAutomation.ActionType action,) = abi.decode(data, (IAutomation.ActionType, uint256));
            assertEq(uint8(action), uint8(IAutomation.ActionType.DistributeYield));
            _perform(data);
        }

        (bool maturityNeeded, bytes memory maturityData) = automation.checkUpkeep("");
        assertTrue(maturityNeeded);
        (IAutomation.ActionType finalAction,) = abi.decode(maturityData, (IAutomation.ActionType, uint256));
        assertEq(uint8(finalAction), uint8(IAutomation.ActionType.Maturity));
        _perform(maturityData);
        assertTrue(investment.getProduct(1).isMaturity);
    }

    function test_22_shortRecoveryDoesNotPermanentlyStarveLaterProduct() public {
        _register(1, 1, MATURITY, 0);
        _register(2, 1, MATURITY, 0);
        vm.prank(admin);
        investment.mintNFT(1, 1, alice);
        vm.warp(DISTRIBUTION_START);

        (bool needed, bytes memory p1Data) = automation.checkUpkeep("");
        assertTrue(needed);
        _perform(p1Data);
        assertTrue(investment.getProduct(1).isInsufficientBalance);

        _deposit(1, 1);
        (needed, p1Data) = automation.checkUpkeep("");
        assertTrue(needed);
        _perform(p1Data);
        assertTrue(investment.getProduct(1).isInsufficientBalance, "short deposit is re-flagged");

        bytes memory p2Data;
        (needed, p2Data) = automation.checkUpkeep("");
        assertTrue(needed);
        (, uint256 selectedProduct) = abi.decode(p2Data, (IAutomation.ActionType, uint256));
        assertEq(selectedProduct, 2, "flagged P1 is skipped so P2 remains reachable");
        _perform(p2Data);

        uint256 remaining = investment.simulateTotalYield(1) - investment.getProduct(1).productPool;
        _deposit(1, remaining);
        (needed, p1Data) = automation.checkUpkeep("");
        assertTrue(needed);
        (, selectedProduct) = abi.decode(p1Data, (IAutomation.ActionType, uint256));
        assertEq(selectedProduct, 1);
        _perform(p1Data);
        assertEq(investment.getProduct(1).distributedCount, 1);
    }

    function test_23_swapAndPopRemovalPreservesAllLiveProducts() public {
        for (uint256 id = 1; id <= 5; ++id) _register(id, 1, MATURITY, 0);
        vm.warp(DISTRIBUTION_START);
        for (uint256 id = 1; id <= 5; ++id) {
            vm.prank(admin);
            investment.distributeYield(id);
        }
        vm.warp(MATURITY);

        uint256[3] memory removed = [uint256(1), uint256(3), uint256(4)];
        for (uint256 i; i < removed.length; ++i) {
            vm.prank(admin);
            investment.maturity(removed[i]);
            Schema.Product[] memory live = investment.getActiveProducts();
            for (uint256 j; j < live.length; ++j) {
                assertFalse(live[j].isMaturity);
                for (uint256 k = j + 1; k < live.length; ++k) assertTrue(live[j].productId != live[k].productId);
            }
        }

        Schema.Product[] memory remaining = investment.getActiveProducts();
        assertEq(remaining.length, 2);
        assertTrue(
            (remaining[0].productId == 5 && remaining[1].productId == 2)
                || (remaining[0].productId == 2 && remaining[1].productId == 5)
        );
        (bool needed, bytes memory data) = automation.checkUpkeep("");
        assertTrue(needed);
        (, uint256 selectedProduct) = abi.decode(data, (IAutomation.ActionType, uint256));
        assertTrue(selectedProduct == 2 || selectedProduct == 5);
    }

    function test_24_revertingSbtBlocksRealInvestDespiteLaterValidSbt() public {
        OODAUnavailableTierSBT unavailable = new OODAUnavailableTierSBT();
        OODAValidTierSBT valid = new OODAValidTierSBT();
        valid.mint(alice);
        address[] memory sbts = new address[](2);
        sbts[0] = address(unavailable);
        sbts[1] = address(valid);
        vm.prank(admin);
        investment.setAllowedByTierAddress(1, sbts);
        _register(1, 1, MATURITY, 1);

        usdt.mint(alice, UNIT);
        vm.prank(alice);
        usdt.approve(address(investment), UNIT);
        vm.expectRevert(bytes("SBT unavailable"));
        vm.prank(alice);
        investment.invest(1, 1);
    }
}
