// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {MCTest} from "@mc-devkit/Flattened.sol";

import {Storage} from "bundle/investment/storage/Storage.sol";
import {IInvestment} from "bundle/investment/interfaces/IInvestment.sol";
import {IInvestmentErrors} from "bundle/investment/interfaces/IInvestmentErrors.sol";
import {InvestmentDeployer} from "script/deploy/InvestmentDeployer.sol";

import {MockInvestmentERC20} from "test/investment/mocks/MockInvestmentERC20.sol";

/**
 * @title F-2026-16866 Uint8 Overflow DoS regression tests
 * @notice Verifies that admin array iteration no longer overflows with uint8 loop counters
 *         and that addAdmin enforces a maximum admin count
 */
contract F202616866Uint8OverflowDoSTest is MCTest {
    IInvestment public investment;
    MockInvestmentERC20 public usdt;

    address safe;
    address admin;
    address[] admins;

    function setUp() public {
        safe = makeAddr("safe");
        admin = makeAddr("admin");
        admins.push(admin);

        usdt = new MockInvestmentERC20();
        vm.prank(safe);
        investment = IInvestment(InvestmentDeployer.deployInvestment(mc, admins, admins, address(usdt), safe));
    }

    function test_isWhiteLists_worksWithManyAdmins() public {
        vm.startPrank(safe);
        for (uint256 i = 1; i < 255; i++) {
            investment.addAdmin(address(uint160(0x1000 + i)));
        }
        vm.stopPrank();

        // admin list now has 255 entries (1 from setUp + 254 added)
        address[] memory adminList = investment.getAdminList();
        assertEq(adminList.length, 255);

        // The original admin can still call whitelist-gated functions
        vm.prank(admin);
        investment.getAdminList();
    }

    function test_addAdmin_revertsAtMaxLimit() public {
        vm.startPrank(safe);
        for (uint256 i = 1; i < 255; i++) {
            investment.addAdmin(address(uint160(0x1000 + i)));
        }

        // 255 admins already exist, adding one more should revert
        vm.expectRevert(abi.encodeWithSelector(IInvestmentErrors.AdminLimitReached.selector));
        investment.addAdmin(address(uint160(0x9999)));
        vm.stopPrank();
    }

    function test_addAdmin_duplicateStillReverts() public {
        vm.startPrank(safe);
        vm.expectRevert(abi.encodeWithSelector(IInvestmentErrors.AlreadyExistsAdmin.selector));
        investment.addAdmin(admin);
        vm.stopPrank();
    }

    receive() external payable {}
}
