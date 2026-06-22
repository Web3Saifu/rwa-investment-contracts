// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {MCTest} from "@mc-devkit/Flattened.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {SetTier} from "bundle/investment/functions/onlyWhiteLists/SetTier.sol";
import {OnlyWhiteListsBase} from "bundle/investment/functions/onlyWhiteLists/OnlyWhiteListsBase.sol";
import {PurchasePermissionLib} from "bundle/investment/utils/PurchasePermissionLib.sol";
import {Storage} from "bundle/investment/storage/Storage.sol";

contract RevertingTierSBT {
    fallback() external {
        revert("SBT unavailable");
    }
}

contract ValidTierSBT is ERC721 {
    constructor() ERC721("Valid Tier", "TIER") {}

    function mint(address to) external {
        _mint(to, 1);
    }
}

contract PurchasePermissionHarness {
    function hasPermission(address user, uint8 tier) external view returns (bool) {
        return PurchasePermissionLib.hasPurchasePermission(user, tier);
    }
}

contract AUDITORRevertingTierSBTTest is MCTest {
    address internal constant INVESTOR = address(0xB0B);

    function setUp() public {
        _use(SetTier.setAllowedByTierAddress.selector, address(new SetTier()));
        _use(PurchasePermissionHarness.hasPermission.selector, address(new PurchasePermissionHarness()));
        Storage.WhiteListsState().admins.push(address(this));
    }

    function test_revertingSbtBlocksValidSbtLaterInTierList() public {
        RevertingTierSBT unavailable = new RevertingTierSBT();
        ValidTierSBT valid = new ValidTierSBT();
        valid.mint(INVESTOR);

        address[] memory sbts = new address[](2);
        sbts[0] = address(unavailable);
        sbts[1] = address(valid);
        SetTier(target).setAllowedByTierAddress(1, sbts);

        vm.expectRevert(bytes("SBT unavailable"));
        PurchasePermissionHarness(target).hasPermission(INVESTOR, 1);
    }
}
