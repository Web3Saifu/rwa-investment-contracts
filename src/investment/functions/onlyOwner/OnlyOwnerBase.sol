// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Storage} from "bundle/investment/storage/Storage.sol";
import {IInvestmentErrors} from "bundle/investment/interfaces/IInvestmentErrors.sol";

abstract contract OnlyOwnerBase {
    modifier onlyOwner() {
        if (!(Storage.ConfigState().SAFE_MULTISIG_WALLET == msg.sender)) {
            revert IInvestmentErrors.NotOwner();
        }
        _;
    }
}

// Testing
import {MCTest} from "@mc-devkit/Flattened.sol";

/**
 * @title OnlyOwnerTester
 * @notice Mock contract for testing the OnlyOwnerBase
 */
contract OnlyOwnerTester is OnlyOwnerBase {
    function doSomething() public view onlyOwner returns (bool) {
        return true;
    }
}

/**
 * @title OnlyOwnerBase
 * @notice Test contract for the OnlyOwnerBase
 */
contract OnlyOwnerBaseTest is MCTest {
    address owner = address(0x1);
    address notOwner = address(0x2);

    function setUp() public {
        _use(OnlyOwnerTester.doSomething.selector, address(new OnlyOwnerTester()));
        Storage.ConfigState().SAFE_MULTISIG_WALLET = owner;
    }

    function test_onlyOwner_success() public {
        vm.prank(owner);
        bool testbool = OnlyOwnerTester(target).doSomething();
        assertTrue(testbool);
    }

    function test_onlyOwner_revert_notOwner() public {
        vm.prank(notOwner);
        vm.expectRevert(IInvestmentErrors.NotOwner.selector);
        OnlyOwnerTester(target).doSomething();
    }

    receive() external payable {}
}
