// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Schema} from "bundle/investment/storage/Schema.sol";
import {Storage} from "bundle/investment/storage/Storage.sol";
import {IInvestmentEvents} from "bundle/investment/interfaces/IInvestmentEvents.sol";
import {IInvestmentErrors} from "bundle/investment/interfaces/IInvestmentErrors.sol";
import {OnlyWhiteListsBase} from "bundle/investment/functions/onlyWhiteLists/OnlyWhiteListsBase.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title SetTier
 * @notice Tier registry configuration and per-product requiredTier updates (admins only).
 */
contract SetTier is OnlyWhiteListsBase {
    function setAllowedByTierAddress(uint8 tier, address[] calldata sbts) external onlyWhiteLists {
        uint256 len = sbts.length;
        for (uint256 i = 0; i < len;) {
            address sbt = sbts[i];
            if (sbt == address(0) || sbt.code.length == 0) {
                revert IInvestmentErrors.TierSbtNotContract(sbt);
            }
            for (uint256 j = 0; j < i;) {
                if (sbts[j] == sbt) {
                    revert IInvestmentErrors.DuplicateEntry();
                }
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }

        // Clear tokenId bindings for SBTs that are removed from this tier.
        address[] storage prev = Storage.TierRegistryState().allowedByTierAddress[tier];
        uint256 prevLen = prev.length;
        for (uint256 i = 0; i < prevLen;) {
            address oldSbt = prev[i];
            if (!_containsCalldata(sbts, oldSbt)) {
                delete Storage.TierRegistryState().allowedByTierId[tier][oldSbt];
            }
            unchecked {
                ++i;
            }
        }

        Storage.TierRegistryState().allowedByTierAddress[tier] = sbts;
        emit IInvestmentEvents.TierAllowedByTierAddressUpdated(tier, sbts);
    }

    function setAllowedByTierId(uint8 tier, address sbt, uint256[] calldata ids) external onlyWhiteLists {
        // Must be registered under the tier.
        if (!_contains(Storage.TierRegistryState().allowedByTierAddress[tier], sbt)) {
            revert IInvestmentErrors.TierSbtNotRegistered(tier, sbt);
        }
        // ids are only meaningful for ERC1155.
        if (sbt == address(0) || sbt.code.length == 0) {
            revert IInvestmentErrors.TierSbtNotContract(sbt);
        }
        if (!IERC165(sbt).supportsInterface(type(IERC1155).interfaceId)) {
            revert IInvestmentErrors.TierSbtNotErc1155(sbt);
        }

        uint256 idsLen = ids.length;
        for (uint256 i = 0; i < idsLen;) {
            uint256 id = ids[i];
            for (uint256 j = 0; j < i;) {
                if (ids[j] == id) {
                    revert IInvestmentErrors.DuplicateEntry();
                }
                unchecked {
                    ++j;
                }
            }
            unchecked {
                ++i;
            }
        }

        Storage.TierRegistryState().allowedByTierId[tier][sbt] = ids;
        emit IInvestmentEvents.TierAllowedByTierIdUpdated(tier, sbt, ids);
    }

    /**
     * @notice Updates the required tier for an existing product
     * @param productId ID of the product to update
     * @param requiredTier New minimum tier (0 = none)
     * @custom:throws ProductNotFound if the product does not exist
     * @custom:throws TierNotConfigured if requiredTier is non-zero but has no SBT contracts in the registry
     */
    function setProductRequiredTier(uint256 productId, uint8 requiredTier) external onlyWhiteLists {
        Schema.Product storage product = Storage.ProductsState().products[productId];
        if (product.productId == 0) {
            revert IInvestmentErrors.ProductNotFound();
        }
        if (requiredTier != 0 && Storage.TierRegistryState().allowedByTierAddress[requiredTier].length == 0) {
            revert IInvestmentErrors.TierNotConfigured(requiredTier);
        }

        uint8 previousRequiredTier = product.requiredTier;
        if (previousRequiredTier == requiredTier) {
            return;
        }

        product.requiredTier = requiredTier;
        emit IInvestmentEvents.ProductRequiredTierUpdated(productId, previousRequiredTier, requiredTier);
    }

    function _containsCalldata(address[] calldata list, address value) private pure returns (bool) {
        uint256 len = list.length;
        for (uint256 i = 0; i < len;) {
            if (list[i] == value) {
                return true;
            }
            unchecked {
                ++i;
            }
        }
        return false;
    }

    function _contains(address[] storage list, address value) private view returns (bool) {
        uint256 len = list.length;
        for (uint256 i = 0; i < len;) {
            if (list[i] == value) {
                return true;
            }
            unchecked {
                ++i;
            }
        }
        return false;
    }
}

// Testing
import {MCTest} from "@mc-devkit/Flattened.sol";
import {Schema} from "bundle/investment/storage/Schema.sol";
import {IInvestmentErrors} from "bundle/investment/interfaces/IInvestmentErrors.sol";
import {IInvestmentEvents} from "bundle/investment/interfaces/IInvestmentEvents.sol";
import {IInvestment} from "bundle/investment/interfaces/IInvestment.sol";
import {Getter} from "bundle/investment/functions/Getter.sol";
import {MockInvestmentERC1155} from "test/investment/mocks/MockInvestmentERC1155.sol";
import {MockTierSBT} from "test/investment/mocks/MockTierSBT.sol";

contract SetTierTest is MCTest {
    address admin = address(0x1);
    address notAdmin = address(0x2);

    function setUp() public {
        _use(SetTier.setAllowedByTierAddress.selector, address(new SetTier()));
        _use(SetTier.setAllowedByTierId.selector, address(new SetTier()));
        _use(SetTier.setProductRequiredTier.selector, address(new SetTier()));
        _use(Getter.getAllowedByTierAddress.selector, address(new Getter()));
        _use(Getter.getAllowedByTierId.selector, address(new Getter()));
        Storage.WhiteListsState().admins.push(admin);
    }

    function test_setAllowedByTierAddress_success_and_get() public {
        address sbt1 = address(new MockTierSBT("SetTierTest1", "ST1"));
        address sbt2 = address(new MockTierSBT("SetTierTest2", "ST2"));
        address[] memory sbts = new address[](2);
        sbts[0] = sbt1;
        sbts[1] = sbt2;
        uint8 tier = 1;

        vm.prank(admin);
        vm.expectEmit(true, false, false, true);
        emit IInvestmentEvents.TierAllowedByTierAddressUpdated(tier, sbts);
        SetTier(target).setAllowedByTierAddress(tier, sbts);

        address[] memory stored = IInvestment(target).getAllowedByTierAddress(tier);
        assertEq(stored.length, 2);
        assertEq(stored[0], sbt1);
        assertEq(stored[1], sbt2);
    }

    function test_setAllowedByTierAddress_replacesPrevious() public {
        address[] memory first = new address[](1);
        first[0] = address(new MockTierSBT("SetTierReplace1", "SR1"));
        address[] memory second = new address[](1);
        second[0] = address(new MockTierSBT("SetTierReplace2", "SR2"));
        uint8 tier = 2;

        vm.startPrank(admin);
        SetTier(target).setAllowedByTierAddress(tier, first);
        SetTier(target).setAllowedByTierAddress(tier, second);
        vm.stopPrank();

        address[] memory stored = IInvestment(target).getAllowedByTierAddress(tier);
        assertEq(stored.length, 1);
        assertEq(stored[0], second[0]);
    }

    function test_getAllowedByTierAddress_emptyWhenUnset() public view {
        address[] memory stored = IInvestment(target).getAllowedByTierAddress(99);
        assertEq(stored.length, 0);
    }

    function test_setAllowedByTierAddress_revert_whenNotAdmin() public {
        address[] memory sbts = new address[](0);
        vm.prank(notAdmin);
        vm.expectRevert(IInvestmentErrors.NotAdmin.selector);
        SetTier(target).setAllowedByTierAddress(1, sbts);
    }

    function test_setAllowedByTierAddress_revert_whenZeroAddress() public {
        address[] memory sbts = new address[](1);
        sbts[0] = address(0);

        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(IInvestmentErrors.TierSbtNotContract.selector, address(0)));
        SetTier(target).setAllowedByTierAddress(1, sbts);
    }

    function test_setAllowedByTierAddress_revert_whenNotContract() public {
        address[] memory sbts = new address[](1);
        sbts[0] = notAdmin;

        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(IInvestmentErrors.TierSbtNotContract.selector, notAdmin));
        SetTier(target).setAllowedByTierAddress(1, sbts);
    }

    function test_setAllowedByTierAddress_revert_whenDuplicate() public {
        MockInvestmentERC1155 token = new MockInvestmentERC1155();
        address dup = address(token);
        address[] memory sbts = new address[](2);
        sbts[0] = dup;
        sbts[1] = dup;

        vm.prank(admin);
        vm.expectRevert(IInvestmentErrors.DuplicateEntry.selector);
        SetTier(target).setAllowedByTierAddress(1, sbts);
    }

    function test_setAllowedByTierAddress_success_canClearWithEmptyArray() public {
        address[] memory first = new address[](2);
        first[0] = address(new MockTierSBT("SetTierClear1", "SC1"));
        first[1] = address(new MockInvestmentERC1155());
        address[] memory empty = new address[](0);
        uint8 tier = 1;

        vm.startPrank(admin);
        SetTier(target).setAllowedByTierAddress(tier, first);
        SetTier(target).setAllowedByTierAddress(tier, empty);
        vm.stopPrank();

        address[] memory stored = IInvestment(target).getAllowedByTierAddress(tier);
        assertEq(stored.length, 0);
    }

    function test_setAllowedByTierAddress_keepsAllowedByTierId() public {
        uint8 tier = 1;
        MockInvestmentERC1155 token = new MockInvestmentERC1155();
        uint256[] memory ids = new uint256[](2);
        ids[0] = 10;
        ids[1] = 77;

        vm.startPrank(admin);
        address[] memory first = new address[](1);
        first[0] = address(token);
        SetTier(target).setAllowedByTierAddress(tier, first);
        SetTier(target).setAllowedByTierId(tier, address(token), ids);

        // Replace address list but keep the same ERC1155 in it: ids should remain.
        address[] memory second = new address[](2);
        second[0] = address(token);
        second[1] = address(new MockTierSBT("SetTierTestErc721", "ST721"));
        SetTier(target).setAllowedByTierAddress(tier, second);
        vm.stopPrank();

        uint256[] memory storedIds = IInvestment(target).getAllowedByTierId(tier, address(token));
        assertEq(storedIds.length, 2);
        assertEq(storedIds[0], 10);
        assertEq(storedIds[1], 77);
    }

    function test_setAllowedByTierId_success_and_get() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 10;
        ids[1] = 77;
        uint8 tier = 1;

        // Register ERC1155 mock under the tier.
        MockInvestmentERC1155 token = new MockInvestmentERC1155();
        address[] memory sbts = new address[](1);
        sbts[0] = address(token);

        vm.startPrank(admin);
        SetTier(target).setAllowedByTierAddress(tier, sbts);
        vm.expectEmit(true, true, false, true);
        emit IInvestmentEvents.TierAllowedByTierIdUpdated(tier, address(token), ids);
        SetTier(target).setAllowedByTierId(tier, address(token), ids);
        vm.stopPrank();

        uint256[] memory stored = IInvestment(target).getAllowedByTierId(tier, address(token));
        assertEq(stored.length, 2);
        assertEq(stored[0], 10);
        assertEq(stored[1], 77);
    }

    function test_setAllowedByTierId_replacesPrevious() public {
        uint256[] memory first = new uint256[](2);
        first[0] = 10;
        first[1] = 77;
        uint256[] memory second = new uint256[](1);
        second[0] = 5;
        uint8 tier = 2;

        MockInvestmentERC1155 token = new MockInvestmentERC1155();
        address[] memory sbts = new address[](1);
        sbts[0] = address(token);

        vm.startPrank(admin);
        SetTier(target).setAllowedByTierAddress(tier, sbts);
        SetTier(target).setAllowedByTierId(tier, address(token), first);
        SetTier(target).setAllowedByTierId(tier, address(token), second);
        vm.stopPrank();

        uint256[] memory stored = IInvestment(target).getAllowedByTierId(tier, address(token));
        assertEq(stored.length, 1);
        assertEq(stored[0], 5);
    }

    function test_setAllowedByTierId_revert_whenNotAdmin() public {
        uint256[] memory ids = new uint256[](1);
        ids[0] = 5;
        vm.prank(notAdmin);
        vm.expectRevert(IInvestmentErrors.NotAdmin.selector);
        SetTier(target).setAllowedByTierId(1, address(0x1234), ids);
    }

    function test_setAllowedByTierAddress_clearsIdsForRemovedSbts() public {
        uint8 tier = 1;
        MockInvestmentERC1155 token = new MockInvestmentERC1155();
        uint256[] memory ids = new uint256[](1);
        ids[0] = 77;

        vm.startPrank(admin);
        address[] memory first = new address[](1);
        first[0] = address(token);
        SetTier(target).setAllowedByTierAddress(tier, first);
        SetTier(target).setAllowedByTierId(tier, address(token), ids);

        // Remove token from the list -> ids should be cleared.
        address[] memory empty = new address[](0);
        SetTier(target).setAllowedByTierAddress(tier, empty);
        vm.stopPrank();

        uint256[] memory stored = IInvestment(target).getAllowedByTierId(tier, address(token));
        assertEq(stored.length, 0);
    }

    function test_setAllowedByTierId_revert_whenSbtNotRegistered() public {
        uint8 tier = 1;
        MockInvestmentERC1155 token = new MockInvestmentERC1155();
        uint256[] memory ids = new uint256[](1);
        ids[0] = 77;

        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(IInvestmentErrors.TierSbtNotRegistered.selector, tier, address(token)));
        SetTier(target).setAllowedByTierId(tier, address(token), ids);
    }

    function test_setAllowedByTierId_revert_whenNotErc1155() public {
        uint8 tier = 1;
        address erc721 = address(new MockTierSBT("SetTierTestErc721", "ST721"));
        uint256[] memory ids = new uint256[](1);
        ids[0] = 77;

        vm.startPrank(admin);
        address[] memory sbts = new address[](1);
        sbts[0] = erc721;
        SetTier(target).setAllowedByTierAddress(tier, sbts);

        vm.expectRevert(abi.encodeWithSelector(IInvestmentErrors.TierSbtNotErc1155.selector, erc721));
        SetTier(target).setAllowedByTierId(tier, erc721, ids);
        vm.stopPrank();
    }

    function test_setAllowedByTierId_revert_whenDuplicateId() public {
        uint8 tier = 1;
        MockInvestmentERC1155 token = new MockInvestmentERC1155();
        uint256[] memory ids = new uint256[](2);
        ids[0] = 10;
        ids[1] = 10;

        vm.startPrank(admin);
        address[] memory sbts = new address[](1);
        sbts[0] = address(token);
        SetTier(target).setAllowedByTierAddress(tier, sbts);

        vm.expectRevert(IInvestmentErrors.DuplicateEntry.selector);
        SetTier(target).setAllowedByTierId(tier, address(token), ids);
        vm.stopPrank();
    }

    function _seedProduct(uint256 productId, uint8 requiredTier, bool isMaturity) internal {
        Schema.Product storage product = Storage.ProductsState().products[productId];
        product.productId = productId;
        product.requiredTier = requiredTier;
        product.isMaturity = isMaturity;
    }

    function _registerTierSbt(uint8 tier) internal returns (address sbt) {
        sbt = address(new MockTierSBT("SetTierProduct", "STP"));
        address[] memory sbts = new address[](1);
        sbts[0] = sbt;
        vm.prank(admin);
        SetTier(target).setAllowedByTierAddress(tier, sbts);
    }

    function test_setProductRequiredTier_success() public {
        uint256 productId = 100;
        uint8 tier = 1;
        _seedProduct(productId, 0, false);
        _registerTierSbt(tier);

        vm.prank(admin);
        vm.expectEmit(true, false, false, true);
        emit IInvestmentEvents.ProductRequiredTierUpdated(productId, 0, tier);
        SetTier(target).setProductRequiredTier(productId, tier);

        assertEq(Storage.ProductsState().products[productId].requiredTier, tier);
    }

    function test_setProductRequiredTier_success_changeTier() public {
        uint256 productId = 101;
        uint8 tier1 = 1;
        uint8 tier2 = 2;
        _seedProduct(productId, tier1, false);
        _registerTierSbt(tier1);
        _registerTierSbt(tier2);

        vm.startPrank(admin);
        SetTier(target).setProductRequiredTier(productId, tier2);
        vm.stopPrank();

        assertEq(Storage.ProductsState().products[productId].requiredTier, tier2);
    }

    function test_setProductRequiredTier_success_whenMatured() public {
        uint256 productId = 102;
        uint8 tier = 1;
        _seedProduct(productId, 0, true);
        _registerTierSbt(tier);

        vm.prank(admin);
        vm.expectEmit(true, false, false, true);
        emit IInvestmentEvents.ProductRequiredTierUpdated(productId, 0, tier);
        SetTier(target).setProductRequiredTier(productId, tier);

        Schema.Product storage product = Storage.ProductsState().products[productId];
        assertTrue(product.isMaturity);
        assertEq(product.requiredTier, tier);
    }

    function test_setProductRequiredTier_noop_whenUnchanged() public {
        uint256 productId = 103;
        uint8 tier = 1;
        _seedProduct(productId, tier, false);
        _registerTierSbt(tier);

        vm.prank(admin);
        SetTier(target).setProductRequiredTier(productId, tier);

        assertEq(Storage.ProductsState().products[productId].requiredTier, tier);
    }

    function test_setProductRequiredTier_revert_whenProductNotFound() public {
        vm.prank(admin);
        vm.expectRevert(IInvestmentErrors.ProductNotFound.selector);
        SetTier(target).setProductRequiredTier(999, 1);
    }

    function test_setProductRequiredTier_revert_whenTierNotConfigured() public {
        uint256 productId = 104;
        _seedProduct(productId, 0, false);

        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(IInvestmentErrors.TierNotConfigured.selector, uint8(3)));
        SetTier(target).setProductRequiredTier(productId, 3);
    }

    function test_setProductRequiredTier_revert_whenNotAdmin() public {
        _seedProduct(105, 0, false);

        vm.prank(notAdmin);
        vm.expectRevert(IInvestmentErrors.NotAdmin.selector);
        SetTier(target).setProductRequiredTier(105, 1);
    }

    function test_setAllowedByTierId_success_whenZeroId() public {
        uint8 tier = 1;
        MockInvestmentERC1155 token = new MockInvestmentERC1155();
        uint256[] memory ids = new uint256[](1);
        ids[0] = 0;

        vm.startPrank(admin);
        address[] memory sbts = new address[](1);
        sbts[0] = address(token);
        SetTier(target).setAllowedByTierAddress(tier, sbts);
        SetTier(target).setAllowedByTierId(tier, address(token), ids);
        vm.stopPrank();

        uint256[] memory stored = IInvestment(target).getAllowedByTierId(tier, address(token));
        assertEq(stored.length, 1);
        assertEq(stored[0], 0);
    }

    receive() external payable {}
}
