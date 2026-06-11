// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {Storage} from "bundle/investment/storage/Storage.sol";

/**
 * @title PurchasePermissionLib
 * @notice Shared purchase-eligibility check for Invest (TierRegistry + ERC721/ERC1155 balance).
 * @dev Callers should use
 *      `if (!hasPurchasePermission(...)) revert IInvestmentErrors.NotEligible(requiredTier);`.
 */
library PurchasePermissionLib {
    /// @notice Skip membership check when the product's requiredTier is this value.
    uint8 internal constant NONE = 0;

    /**
     * @notice Whether `user` may invest for the product's `requiredTier`.
     * @param user Investor address (`msg.sender` in Invest).
     * @param requiredTier Minimum tier for the product (no check if NONE).
     * @return true if `requiredTier == NONE`, or if user holds any eligible token under `allowedByTierAddress[requiredTier]`.
     * @dev For "BRONZE or higher" products, ops may register Silver/Gold contract addresses on `allowedByTierAddress[BRONZE]` to express inclusion.
     */
    function hasPurchasePermission(address user, uint8 requiredTier) internal view returns (bool) {
        if (requiredTier == NONE) {
            return true;
        }

        address[] storage sbts = Storage.TierRegistryState().allowedByTierAddress[requiredTier];
        uint256 len = sbts.length;
        for (uint256 i = 0; i < len;) {
            address sbt = sbts[i];
            uint256[] storage ids = Storage.TierRegistryState().allowedByTierId[requiredTier][sbt];
            if (_hasPermissionByContract(user, sbt, ids)) {
                return true;
            }
            unchecked {
                ++i;
            }
        }
        return false;
    }

    function _hasPermissionByContract(address user, address sbt, uint256[] storage ids) private view returns (bool) {
        if (sbt == address(0) || sbt.code.length == 0) {
            return false;
        }
        if (IERC165(sbt).supportsInterface(type(IERC1155).interfaceId)) {
            return _hasAny1155Balance(user, sbt, ids);
        }
        if (IERC165(sbt).supportsInterface(type(IERC721).interfaceId)) {
            return IERC721(sbt).balanceOf(user) > 0;
        }
        return false;
    }

    function _hasAny1155Balance(address user, address sbt, uint256[] storage ids) private view returns (bool) {
        uint256 idsLen = ids.length;
        for (uint256 j = 0; j < idsLen;) {
            if (IERC1155(sbt).balanceOf(user, ids[j]) > 0) {
                return true;
            }
            unchecked {
                ++j;
            }
        }
        return false;
    }
}

// Testing: bundled MCTest unit smoke; coverage/fuzz can live in separate test files.
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {MCTest} from "@mc-devkit/Flattened.sol";
import {MockInvestmentERC1155} from "test/investment/mocks/MockInvestmentERC1155.sol";

contract PurchasePermissionLibTinySbt is ERC721 {
    uint256 private _nextId = 1;

    constructor() ERC721("PurchasePermissionTestSBT", "PPT") {}

    function mint(address to) external returns (uint256 id) {
        id = _nextId++;
        _mint(to, id);
    }
}

contract PurchasePermissionLibTest is MCTest {
    address internal user = address(0xBEEF);

    /// @dev Upper bound when clearing tier keys in tests (production tiers are arbitrary uint8).
    uint8 internal constant _TIER_CLEAR_MAX = 4;

    function setUp() public {
        for (uint8 t = 0; t <= _TIER_CLEAR_MAX; ++t) {
            address[] storage sbts = Storage.TierRegistryState().allowedByTierAddress[t];
            uint256 sbtsLen = sbts.length;
            for (uint256 i = 0; i < sbtsLen;) {
                delete Storage.TierRegistryState().allowedByTierId[t][sbts[i]];
                unchecked {
                    ++i;
                }
            }
            delete Storage.TierRegistryState().allowedByTierAddress[t];
        }
    }

    function test_hasPurchasePermission_none_returnsTrue() public view {
        assertTrue(PurchasePermissionLib.hasPurchasePermission(user, PurchasePermissionLib.NONE));
    }

    function test_hasPurchasePermission_bronze_emptyRegistry_returnsFalse() public view {
        assertFalse(PurchasePermissionLib.hasPurchasePermission(user, 1));
    }

    /// @dev SBT registered but user holds none → false (distinct from empty array).
    function test_hasPurchasePermission_bronze_registeredButUserDoesNotHold_returnsFalse() public {
        PurchasePermissionLibTinySbt sbt = new PurchasePermissionLibTinySbt();
        Storage.TierRegistryState().allowedByTierAddress[1].push(address(sbt));
        assertEq(sbt.balanceOf(user), 0);
        assertFalse(PurchasePermissionLib.hasPurchasePermission(user, 1));
    }

    function test_hasPurchasePermission_bronze_withRegisteredSbt_returnsTrue() public {
        PurchasePermissionLibTinySbt sbt = new PurchasePermissionLibTinySbt();
        Storage.TierRegistryState().allowedByTierAddress[1].push(address(sbt));
        sbt.mint(user);
        assertTrue(PurchasePermissionLib.hasPurchasePermission(user, 1));
    }

    /// @dev Among several registered SBTs, user only holds a middle one → true.
    function test_hasPurchasePermission_multipleRegistered_matchMiddle_returnsTrue() public {
        PurchasePermissionLibTinySbt first = new PurchasePermissionLibTinySbt();
        PurchasePermissionLibTinySbt middle = new PurchasePermissionLibTinySbt();
        PurchasePermissionLibTinySbt last = new PurchasePermissionLibTinySbt();
        Storage.TierRegistryState().allowedByTierAddress[1].push(address(first));
        Storage.TierRegistryState().allowedByTierAddress[1].push(address(middle));
        Storage.TierRegistryState().allowedByTierAddress[1].push(address(last));
        middle.mint(user);
        assertEq(first.balanceOf(user), 0);
        assertEq(last.balanceOf(user), 0);
        assertTrue(PurchasePermissionLib.hasPurchasePermission(user, 1));
    }

    /// @dev Among several registered SBTs, user only holds the last one → true.
    function test_hasPurchasePermission_multipleRegistered_matchLast_returnsTrue() public {
        PurchasePermissionLibTinySbt first = new PurchasePermissionLibTinySbt();
        PurchasePermissionLibTinySbt middle = new PurchasePermissionLibTinySbt();
        PurchasePermissionLibTinySbt last = new PurchasePermissionLibTinySbt();
        Storage.TierRegistryState().allowedByTierAddress[1].push(address(first));
        Storage.TierRegistryState().allowedByTierAddress[1].push(address(middle));
        Storage.TierRegistryState().allowedByTierAddress[1].push(address(last));
        last.mint(user);
        assertEq(first.balanceOf(user), 0);
        assertEq(middle.balanceOf(user), 0);
        assertTrue(PurchasePermissionLib.hasPurchasePermission(user, 1));
    }

    /// @dev address(0) at head/tail is skipped; holding any non-zero SBT counts → true.
    function test_hasPurchasePermission_zeroAddressEntries_skipped_validSbtStillCounts() public {
        PurchasePermissionLibTinySbt sbt = new PurchasePermissionLibTinySbt();
        Storage.TierRegistryState().allowedByTierAddress[1].push(address(0));
        Storage.TierRegistryState().allowedByTierAddress[1].push(address(sbt));
        Storage.TierRegistryState().allowedByTierAddress[1].push(address(0));
        sbt.mint(user);
        assertTrue(PurchasePermissionLib.hasPurchasePermission(user, 1));
    }

    /// @dev Even for requiredTier=BRONZE, if the BRONZE row only lists a Silver SBT, Silver balance suffices.
    function test_hasPurchasePermission_bronzeProduct_investorHoldsSilverSbt_viaBronzeRegistryRow() public {
        PurchasePermissionLibTinySbt silverSbt = new PurchasePermissionLibTinySbt();
        Storage.TierRegistryState().allowedByTierAddress[1].push(address(silverSbt));
        silverSbt.mint(user);
        assertTrue(PurchasePermissionLib.hasPurchasePermission(user, 1));
    }

    /// @dev Even for requiredTier=BRONZE, if the BRONZE row only lists a Gold SBT, Gold balance suffices.
    function test_hasPurchasePermission_bronzeProduct_investorHoldsGoldSbt_viaBronzeRegistryRow() public {
        PurchasePermissionLibTinySbt goldSbt = new PurchasePermissionLibTinySbt();
        Storage.TierRegistryState().allowedByTierAddress[1].push(address(goldSbt));
        goldSbt.mint(user);
        assertTrue(PurchasePermissionLib.hasPurchasePermission(user, 1));
    }

    /// @dev BRONZE row lists Bronze/Silver/Gold SBTs; user only holds Silver → allowed as inclusion.
    function test_hasPurchasePermission_bronzeProduct_registryListsMultipleTierSbts_userHoldsSilver() public {
        PurchasePermissionLibTinySbt bronzeSbt = new PurchasePermissionLibTinySbt();
        PurchasePermissionLibTinySbt silverSbt = new PurchasePermissionLibTinySbt();
        PurchasePermissionLibTinySbt goldSbt = new PurchasePermissionLibTinySbt();
        Storage.TierRegistryState().allowedByTierAddress[1].push(address(bronzeSbt));
        Storage.TierRegistryState().allowedByTierAddress[1].push(address(silverSbt));
        Storage.TierRegistryState().allowedByTierAddress[1].push(address(goldSbt));
        silverSbt.mint(user);
        assertEq(bronzeSbt.balanceOf(user), 0);
        assertEq(goldSbt.balanceOf(user), 0);
        assertTrue(PurchasePermissionLib.hasPurchasePermission(user, 1));
    }

    /// @dev BRONZE row lists Bronze/Silver/Gold SBTs; user only holds Gold → allowed as inclusion.
    function test_hasPurchasePermission_bronzeProduct_registryListsMultipleTierSbts_userHoldsGold() public {
        PurchasePermissionLibTinySbt bronzeSbt = new PurchasePermissionLibTinySbt();
        PurchasePermissionLibTinySbt silverSbt = new PurchasePermissionLibTinySbt();
        PurchasePermissionLibTinySbt goldSbt = new PurchasePermissionLibTinySbt();
        Storage.TierRegistryState().allowedByTierAddress[1].push(address(bronzeSbt));
        Storage.TierRegistryState().allowedByTierAddress[1].push(address(silverSbt));
        Storage.TierRegistryState().allowedByTierAddress[1].push(address(goldSbt));
        goldSbt.mint(user);
        assertEq(bronzeSbt.balanceOf(user), 0);
        assertEq(silverSbt.balanceOf(user), 0);
        assertTrue(PurchasePermissionLib.hasPurchasePermission(user, 1));
    }

    function test_hasPurchasePermission_erc1155_matchAnyId_returnsTrue() public {
        MockInvestmentERC1155 token = new MockInvestmentERC1155();
        Storage.TierRegistryState().allowedByTierAddress[1].push(address(token));
        Storage.TierRegistryState().allowedByTierId[1][address(token)].push(10);
        Storage.TierRegistryState().allowedByTierId[1][address(token)].push(77);

        token.mint(user, 77, 1);
        assertTrue(PurchasePermissionLib.hasPurchasePermission(user, 1));
    }

    function test_hasPurchasePermission_erc1155_noMatchingId_returnsFalse() public {
        MockInvestmentERC1155 token = new MockInvestmentERC1155();
        Storage.TierRegistryState().allowedByTierAddress[1].push(address(token));
        Storage.TierRegistryState().allowedByTierId[1][address(token)].push(10);
        Storage.TierRegistryState().allowedByTierId[1][address(token)].push(77);

        token.mint(user, 999, 1);
        assertFalse(PurchasePermissionLib.hasPurchasePermission(user, 1));
    }

    function test_hasPurchasePermission_erc1155_withEmptyIds_returnsFalse() public {
        MockInvestmentERC1155 token = new MockInvestmentERC1155();
        Storage.TierRegistryState().allowedByTierAddress[1].push(address(token));

        token.mint(user, 77, 1);
        assertFalse(PurchasePermissionLib.hasPurchasePermission(user, 1));
    }

    function test_hasPurchasePermission_mixed721And1155_with1155Match_returnsTrue() public {
        PurchasePermissionLibTinySbt sbt = new PurchasePermissionLibTinySbt();
        MockInvestmentERC1155 token1155 = new MockInvestmentERC1155();
        Storage.TierRegistryState().allowedByTierAddress[1].push(address(sbt));
        Storage.TierRegistryState().allowedByTierAddress[1].push(address(token1155));
        Storage.TierRegistryState().allowedByTierId[1][address(token1155)].push(10);
        Storage.TierRegistryState().allowedByTierId[1][address(token1155)].push(77);

        token1155.mint(user, 77, 1);
        assertEq(sbt.balanceOf(user), 0);
        assertTrue(PurchasePermissionLib.hasPurchasePermission(user, 1));
    }
}
