// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title UsdtTransferLib
 * @notice Safe USDT transfer attempts for push-payment loops (catch revert and false return)
 */
library UsdtTransferLib {
    /**
     * @notice Attempts ERC20 transfer via low-level call (USDT may omit return data)
     * @param token ERC20 token address
     * @param to Recipient
     * @param amount Amount to transfer
     * @return success True if transfer succeeded
     */
    function tryTransfer(IERC20 token, address to, uint256 amount) internal returns (bool success) {
        (bool callSuccess, bytes memory data) =
            address(token).call(abi.encodeWithSelector(IERC20.transfer.selector, to, amount));
        if (!callSuccess) {
            return false;
        }
        if (data.length == 0) {
            return true;
        }
        return abi.decode(data, (bool));
    }
}
