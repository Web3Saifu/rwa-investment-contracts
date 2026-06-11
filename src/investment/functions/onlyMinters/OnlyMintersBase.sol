// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Storage} from "bundle/investment/storage/Storage.sol";
import {IInvestmentErrors} from "bundle/investment/interfaces/IInvestmentErrors.sol";

abstract contract OnlyMintersBase {
    modifier onlyMinters() {
        if (!_isMinter()) {
            revert IInvestmentErrors.NotMinter();
        }
        _;
    }

    function _isMinter() internal view returns (bool) {
        address[] memory minters = Storage.MintersState().minters;
        for (uint256 i = 0; i < minters.length; i++) {
            if (minters[i] == msg.sender) {
                return true;
            }
        }
        return false;
    }
}

