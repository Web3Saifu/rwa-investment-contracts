// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {MCTest} from "@mc-devkit/Flattened.sol";
import {Initialize} from "bundle/investment/functions/initializer/Initialize.sol";
import {ControlMinter} from "bundle/investment/functions/onlyOwner/ControlMinter.sol";
import {OnlyMintersBase} from "bundle/investment/functions/onlyMinters/OnlyMintersBase.sol";
import {Storage} from "bundle/investment/storage/Storage.sol";

contract MinterAuthorizationHarness is OnlyMintersBase {
    function restrictedAction() external view onlyMinters returns (bool) {
        return true;
    }
}

contract AUDITORDuplicateInitialMinterTest is MCTest {
    address internal constant MINTER = address(0xBEEF);

    function setUp() public {
        _use(Initialize.initialize.selector, address(new Initialize()));
        _use(ControlMinter.deleteMinter.selector, address(new ControlMinter()));
        _use(MinterAuthorizationHarness.restrictedAction.selector, address(new MinterAuthorizationHarness()));
    }

    function test_duplicateInitialMinterSurvivesRevocation() public {
        address[] memory admins = new address[](1);
        admins[0] = address(0xA11CE);

        address[] memory minters = new address[](2);
        minters[0] = MINTER;
        minters[1] = MINTER;

        Initialize(target).initialize(admins, minters, address(0x1234), address(this));
        ControlMinter(target).deleteMinter(MINTER);

        address[] memory remaining = Storage.MintersState().minters;
        assertEq(remaining.length, 1);
        assertEq(remaining[0], MINTER);

        vm.prank(MINTER);
        assertTrue(MinterAuthorizationHarness(target).restrictedAction());
    }
}
