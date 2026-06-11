// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Storage} from "bundle/investment/storage/Storage.sol";
import {IInvestmentErrors} from "bundle/investment/interfaces/IInvestmentErrors.sol";
import {IInvestmentEvents} from "bundle/investment/interfaces/IInvestmentEvents.sol";
import {OnlyOwnerBase} from "bundle/investment/functions/onlyOwner/OnlyOwnerBase.sol";

/**
 * @title ControlAdmin
 * @notice Contract for controling the admin list
 * @dev This contract is used to add or delete admins
 */
contract ControlAdmin is OnlyOwnerBase {
    uint256 private constant MAX_ADMINS = 255;

    /**
     * @notice Adds an admin to the WhiteListsState admin list
     * @dev Checks if the address already exists; if not, appends it to the admins array
     * @param _admin The address to be added as an admin
     */
    function addAdmin(address _admin) external onlyOwner {
        if (_admin == address(0)) revert IInvestmentErrors.InvalidAddress();

        // Check if the address already exists in WhiteListsState
        address[] memory admins = Storage.WhiteListsState().admins;
        if (admins.length >= MAX_ADMINS) {
            revert IInvestmentErrors.AdminLimitReached();
        }
        for (uint256 i = 0; i < admins.length; i++) {
            if (admins[i] == _admin) {
                revert IInvestmentErrors.AlreadyExistsAdmin();
            }
        }
        // If not found, append the address to the admins array in WhiteListsState
        Storage.WhiteListsState().admins.push(_admin);

        // Emit AdminAdded event
        emit IInvestmentEvents.AdminAdded(_admin, msg.sender);
    }

    /**
     * @notice Deletes an admin from the WhiteListsState admin list
     * @dev Searches the admins array for the specified address. If found, swap with the last element and pop
     * @param _admin The address to be removed from the admin list
     */
    function deleteAdmin(address _admin) external onlyOwner {
        // Search for the specified address in the admins array
        address[] storage admins = Storage.WhiteListsState().admins;
        bool found = false;
        uint256 length = admins.length;

        for (uint256 i = 0; i < length; i++) {
            if (admins[i] == _admin) {
                // If found, swap with the last element and pop
                found = true;
                admins[i] = admins[length - 1];
                admins.pop();
                break;
            }
        }

        // If not found in the admins array, revert with NotExistsAdmin error
        if (!found) {
            revert IInvestmentErrors.NotExistsAdmin();
        }

        // Emit AdminRemoved event
        emit IInvestmentEvents.AdminRemoved(_admin, msg.sender);
    }
}

// Testing
import {MCTest} from "@mc-devkit/Flattened.sol";
import {Storage as MCStorage} from "@mc-std/storage/Storage.sol";
import {IInvestment} from "bundle/investment/interfaces/IInvestment.sol";

/**
 * @title ControlAdminTest
 * @notice Test contract for controlAdmin functionality
 */
contract ControlAdminTest is MCTest {
    address internal owner;
    address internal nonOwner;
    address internal admin1;
    address internal admin2;
    address internal admin3;
    address internal admin4;

    /**
     * @notice Setup before each test
     * @dev Deploys controlAdmin and configures the environment
     */
    function setUp() public {
        owner = makeAddr("owner");
        nonOwner = makeAddr("nonOwner");
        admin1 = makeAddr("admin1");
        admin2 = makeAddr("admin2");
        admin3 = makeAddr("admin3");
        admin4 = makeAddr("admin4");

        ControlAdmin controlAdminImpl = new ControlAdmin();

        _use(ControlAdmin.addAdmin.selector, address(controlAdminImpl));
        _use(ControlAdmin.deleteAdmin.selector, address(controlAdminImpl));

        // Initialize the admin list
        Storage.WhiteListsState().admins = new address[](0);

        // Set the owner
        Storage.ConfigState().SAFE_MULTISIG_WALLET = owner;
    }

    function testAddAdmin() public {
        vm.expectEmit(true, true, false, false);
        emit IInvestmentEvents.AdminAdded(admin1, owner);
        vm.prank(owner);
        IInvestment(target).addAdmin(admin1);

        address[] memory admins = Storage.WhiteListsState().admins;
        assertEq(admins.length, 1);
        assertEq(admins[0], admin1);
    }

    function testDeleteAdmin() public {
        // First, add admins
        vm.startPrank(owner);
        IInvestment(target).addAdmin(admin1);
        IInvestment(target).addAdmin(admin2);
        IInvestment(target).addAdmin(admin3);
        IInvestment(target).addAdmin(admin4);
        vm.stopPrank();

        vm.expectEmit(true, true, false, false);
        emit IInvestmentEvents.AdminRemoved(admin2, owner);

        // Remove an admin
        vm.prank(owner);
        IInvestment(target).deleteAdmin(admin2);

        address[] memory admins = Storage.WhiteListsState().admins;
        assertEq(admins.length, 3);
        assertEq(admins[0], admin1);
        assertEq(admins[1], admin4);
        assertEq(admins[2], admin3);
    }

    function testAddAdminNotOwner() public {
        vm.startPrank(nonOwner);
        vm.expectRevert(abi.encodeWithSelector(IInvestmentErrors.NotOwner.selector));
        IInvestment(target).addAdmin(admin1);
        vm.stopPrank();
    }

    function testDeleteAdminNotOwner() public {
        // First, add an admin
        vm.startPrank(owner);
        IInvestment(target).addAdmin(admin1);
        vm.stopPrank();

        // Try to remove by nonOwner → should revert
        vm.startPrank(nonOwner);
        vm.expectRevert(abi.encodeWithSelector(IInvestmentErrors.NotOwner.selector));
        IInvestment(target).deleteAdmin(admin1);
        vm.stopPrank();
    }

    function testDeleteNonExistentAdmin() public {
        vm.startPrank(owner);
        vm.expectRevert(abi.encodeWithSelector(IInvestmentErrors.NotExistsAdmin.selector));
        IInvestment(target).deleteAdmin(admin1);
        vm.stopPrank();
    }

    function testAddAdminZeroAddress() public {
        vm.startPrank(owner);
        vm.expectRevert(abi.encodeWithSelector(IInvestmentErrors.InvalidAddress.selector));
        IInvestment(target).addAdmin(address(0));
        vm.stopPrank();
    }

    function testFuzzAddAdmin(address newAdmin) public {
        vm.assume(newAdmin != address(0));

        vm.expectEmit(true, true, false, false);
        emit IInvestmentEvents.AdminAdded(newAdmin, owner);

        vm.startPrank(owner);
        IInvestment(target).addAdmin(newAdmin);
        address[] memory admins = Storage.WhiteListsState().admins;
        assertEq(admins.length, 1);
        assertEq(admins[0], newAdmin);

        vm.stopPrank();
    }
}
