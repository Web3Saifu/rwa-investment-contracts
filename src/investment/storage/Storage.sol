// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Schema} from "./Schema.sol";

/**
 * @title Investment Storage v0.1.0
 */
library Storage {
    /// @custom:storage-location erc7201:Investment.ProductsState
    bytes32 internal constant INVESTMENT_PRODUCTSSTATE =
        0xd5c706f940972e5c44335f7bfcf1630de2237ac8736082c3313562564dd6c700;

    /// @custom:storage-location erc7201:Investment.WhiteListsState
    bytes32 internal constant INVESTMENT_WHITELISTSSTATE =
        0xa12e659ff714063977623cc2284ff3b002e50f047a4b0fe5e80d5e3447a8a300;

    /// @custom:storage-location erc7201:Investment.MintersState
    bytes32 internal constant INVESTMENT_MINTERSSTATE =
        0x9f435bccd623dd15175790daf62591df52e2f6b0ad7c7c8c30df79218ba2df00;

    /// @custom:storage-location erc7201:Investment.ConfigState
    bytes32 internal constant INVESTMENT_CONFIGSTATE =
        0xd082f820a14a7e45b9904820cf06c9b749a1f5597519c6d4e155cf664e41ce00;

    /// @custom:storage-location erc7201:Investment.TierRegistryState
    bytes32 internal constant INVESTMENT_TIERREGISTRYSTATE =
        0xa069283513523a4d942f0ec5ca20db4acd6bacbc3b1aae027dc8c721c2f26f00;

    /// @custom:storage-location erc7201:Investment.EscrowState
    bytes32 internal constant INVESTMENT_ESCROWSTATE =
        0x0ff64865e25afcd5a01b77f898b765de756e9485fee3697065a12a6e2e455e00;

    function ProductsState() internal pure returns (Schema.$ProductsState storage ref) {
        bytes32 slot = INVESTMENT_PRODUCTSSTATE;
        assembly {
            ref.slot := slot//ref কে এই storage slot-এর সাথে connect করো।
        }
    }

    function WhiteListsState() internal pure returns (Schema.$WhiteListsState storage ref) {
        bytes32 slot = INVESTMENT_WHITELISTSSTATE;
        assembly {
            ref.slot := slot
        }
    }

    function MintersState() internal pure returns (Schema.$MintersState storage ref) {
        bytes32 slot = INVESTMENT_MINTERSSTATE;
        assembly {
            ref.slot := slot
        }
    }

    function ConfigState() internal pure returns (Schema.$ConfigState storage ref) {
        bytes32 slot = INVESTMENT_CONFIGSTATE;
        assembly {
            ref.slot := slot
        }
    }

    function TierRegistryState() internal pure returns (Schema.$TierRegistryState storage ref) {
        bytes32 slot = INVESTMENT_TIERREGISTRYSTATE;
        assembly {
            ref.slot := slot
        }
    }

    function EscrowState() internal pure returns (Schema.$EscrowState storage ref) {
        bytes32 slot = INVESTMENT_ESCROWSTATE;
        assembly {
            ref.slot := slot
        }
    }
}
