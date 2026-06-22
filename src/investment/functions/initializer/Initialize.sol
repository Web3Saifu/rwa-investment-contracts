// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Storage} from "bundle/investment/storage/Storage.sol";
import {IInvestmentErrors} from "bundle/investment/interfaces/IInvestmentErrors.sol";
import {IInvestmentEvents} from "bundle/investment/interfaces/IInvestmentEvents.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * @title Initialize
 * @notice This contract handles the initialization process for Investment bundle
 * @dev Inherits from Initializable to ensure one-time initialization
 */
contract Initialize is Initializable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address[] calldata admins,
        address[] calldata minters,
        address usdtAddress,
        address safeMultisigWallet
    ) external initializer {
        // set admins
        for (uint256 i = 0; i < admins.length; i++) {
            if (admins[i] == address(0)) revert IInvestmentErrors.InvalidAddress();
            for (uint256 j = 0; j < i; j++) {
                if (admins[j] == admins[i]) revert IInvestmentErrors.AlreadyExistsAdmin();
            }
            Storage.WhiteListsState().admins.push(admins[i]);
            emit IInvestmentEvents.AdminAdded(admins[i], msg.sender);
        }

        // set minters
        for (uint256 i = 0; i < minters.length; i++) {
            if (minters[i] == address(0)) revert IInvestmentErrors.InvalidAddress();
            Storage.MintersState().minters.push(minters[i]);
            emit IInvestmentEvents.MinterAdded(minters[i], msg.sender);
        }

        if (usdtAddress == address(0)) revert IInvestmentErrors.InvalidAddress();
        if (safeMultisigWallet == address(0)) revert IInvestmentErrors.InvalidAddress();

        // set config
        Storage.ConfigState().USDT_ADDRESS = usdtAddress;
        Storage.ConfigState().SAFE_MULTISIG_WALLET = safeMultisigWallet;
    }
}


// Testing
import {MCTest} from "@mc-devkit/Flattened.sol";

/**
 * @title InitializeTest
 * @notice Test contract for the Initialize function contract
 */
contract InitializeTest is MCTest {
    address[] validAdmins = [address(0x1), address(0x2)];
    address[] invalidAdmins = [address(0x3), address(0)];
    address[] validMinters = [address(0x11), address(0x12)];
    address[] invalidMinters = [address(0x13), address(0)];
    address usdtAddress = address(0x4);
    address safeMultisigWallet = address(0x5);

    function setUp() public {
        _use(Initialize.initialize.selector, address(new Initialize()));
    }

    function test_initialize_success() public {
        Initialize(target).initialize(validAdmins, validMinters, usdtAddress, safeMultisigWallet);

        address[] memory admins = Storage.WhiteListsState().admins;
        assertEq(admins.length, validAdmins.length);
        assertEq(admins[0], validAdmins[0]);
        assertEq(admins[1], validAdmins[1]);
        address[] memory minters = Storage.MintersState().minters;
        assertEq(minters.length, validMinters.length);
        assertEq(minters[0], validMinters[0]);
        assertEq(minters[1], validMinters[1]);
        assertEq(Storage.ConfigState().USDT_ADDRESS, usdtAddress);
        assertEq(Storage.ConfigState().SAFE_MULTISIG_WALLET, safeMultisigWallet);
    }

    function test_initialize_revert_withZeroAddress() public {
        vm.expectRevert(abi.encodeWithSelector(IInvestmentErrors.InvalidAddress.selector));
        Initialize(target).initialize(invalidAdmins, validMinters, usdtAddress, safeMultisigWallet);
    }

    function test_initialize_revert_withZeroMinter() public {
        vm.expectRevert(abi.encodeWithSelector(IInvestmentErrors.InvalidAddress.selector));
        Initialize(target).initialize(validAdmins, invalidMinters, usdtAddress, safeMultisigWallet);
    }

    function test_initialize_revert_duplicateAdmin() public {
        address[] memory duplicateAdmins = new address[](3);
        duplicateAdmins[0] = address(0x1);
        duplicateAdmins[1] = address(0x2);
        duplicateAdmins[2] = address(0x1);
        vm.expectRevert(abi.encodeWithSelector(IInvestmentErrors.AlreadyExistsAdmin.selector));
        Initialize(target).initialize(duplicateAdmins, validMinters, usdtAddress, safeMultisigWallet);
    }

    function test_initialize_revert_withZeroUsdtAddress() public {
        vm.expectRevert(abi.encodeWithSelector(IInvestmentErrors.InvalidAddress.selector));
        Initialize(target).initialize(validAdmins, validMinters, address(0), safeMultisigWallet);
    }

    function test_initialize_revert_withZeroSafeMultisigWallet() public {
        vm.expectRevert(abi.encodeWithSelector(IInvestmentErrors.InvalidAddress.selector));
        Initialize(target).initialize(validAdmins, validMinters, usdtAddress, address(0));
    }

    function test_initialize_revert_cannotReinitialize() public {
        Initialize(target).initialize(validAdmins, validMinters, usdtAddress, safeMultisigWallet);

        vm.expectRevert();
        Initialize(target).initialize(validAdmins, validMinters, usdtAddress, safeMultisigWallet);
    }

    function test_initialize_revert_directCallToImplementation() public {
        Initialize impl = new Initialize();
        vm.expectRevert();
        impl.initialize(validAdmins, validMinters, usdtAddress, safeMultisigWallet);
    }

    receive() external payable {}
}
