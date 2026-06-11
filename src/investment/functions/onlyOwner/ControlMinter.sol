// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Storage} from "bundle/investment/storage/Storage.sol";
import {IInvestmentErrors} from "bundle/investment/interfaces/IInvestmentErrors.sol";
import {IInvestmentEvents} from "bundle/investment/interfaces/IInvestmentEvents.sol";
import {OnlyOwnerBase} from "bundle/investment/functions/onlyOwner/OnlyOwnerBase.sol";

/**
 * @title ControlMinter
 * @notice Contract for controlling the minter list
 * @dev Minter list is managed by SAFE (onlyOwner)
 */
contract ControlMinter is OnlyOwnerBase {
    uint256 private constant MAX_MINTERS = 255;

    function addMinter(address _minter) external onlyOwner {
        if (_minter == address(0)) revert IInvestmentErrors.InvalidAddress();

        address[] memory minters = Storage.MintersState().minters;
        if (minters.length >= MAX_MINTERS) revert IInvestmentErrors.MinterLimitReached();

        for (uint256 i = 0; i < minters.length; i++) {
            if (minters[i] == _minter) revert IInvestmentErrors.AlreadyExistsMinter();
        }

        Storage.MintersState().minters.push(_minter);
        emit IInvestmentEvents.MinterAdded(_minter, msg.sender);
    }

    function deleteMinter(address _minter) external onlyOwner {
        address[] storage minters = Storage.MintersState().minters;
        uint256 length = minters.length;
        bool found = false;

        for (uint256 i = 0; i < length; i++) {
            if (minters[i] == _minter) {
                found = true;
                minters[i] = minters[length - 1];
                minters.pop();
                break;
            }
        }

        if (!found) revert IInvestmentErrors.NotExistsMinter();
        emit IInvestmentEvents.MinterRemoved(_minter, msg.sender);
    }
}

