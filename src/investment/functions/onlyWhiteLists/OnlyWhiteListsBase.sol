// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Storage} from "bundle/investment/storage/Storage.sol";
import {IInvestmentErrors} from "bundle/investment/interfaces/IInvestmentErrors.sol";

abstract contract OnlyWhiteListsBase {
    modifier onlyWhiteLists() {
        if (!_isWhiteLists()) {
            revert IInvestmentErrors.NotAdmin();
        }
        _;
    }

    function _isWhiteLists() internal view returns (bool) {
        address[] memory admins = Storage.WhiteListsState().admins;
        for (uint256 i = 0; i < admins.length; i++) {
            if (admins[i] == msg.sender) {
                return true;
            }
        }
        return false;
    }
}

// Testing
import {MCTest} from "@mc-devkit/Flattened.sol";

/**
 * @title OnlyWhiteListTester
 * @notice Mock contract for testing the OnlyWhiteListsBase
 */
contract OnlyWhiteListsTester is OnlyWhiteListsBase {
    function doSomething() public view onlyWhiteLists returns (bool) {
        return true;
    }
}

/**
 * @title OnlyWhiteListsBase
 * @notice Test contract for the OnlyWhiteListsBase
 */
contract OnlyWhiteListsBaseTest is MCTest {
    address admin = address(0x1);
    address notAdmin = address(0x2);

    function setUp() public {
        _use(OnlyWhiteListsTester.doSomething.selector, address(new OnlyWhiteListsTester()));
        Storage.WhiteListsState().admins.push(admin);
    }

    function test_onlyWhiteLists_success() public {
        vm.prank(admin);
        bool testbool = OnlyWhiteListsTester(target).doSomething();
        assertTrue(testbool);
    }

    function test_onlyWhiteLists_revert_notAdmin() public {
        vm.prank(notAdmin);
        vm.expectRevert(IInvestmentErrors.NotAdmin.selector);
        OnlyWhiteListsTester(target).doSomething();
    }

    receive() external payable {}
}
