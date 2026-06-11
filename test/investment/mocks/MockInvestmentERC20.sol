// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {MockERC20} from "@mc-devkit/Flattened.sol";

/**
 * @title Mock ERC20 Contract
 * @dev This is a mock contract for testing purposes only. DO NOT use in production.
 * @notice Implements a simplified ERC20 token for test with USDT-like behavior
 */
contract MockInvestmentERC20 is MockERC20 {
    mapping(address => bool) public blocked;

    constructor() {
        initialize("USDT Test Token", "USDT", 6);
    }

    function setBlocked(address account, bool isBlocked) external {
        blocked[account] = isBlocked;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }

    /**
     * @dev Override approve function to mimic USDT's race condition protection
     * @notice To change the approve amount you first have to reduce the addresses' allowance to zero by calling `approve(spender, 0)` if it is not already 0
     * @param spender The address which will spend the funds
     * @param amount The amount of tokens to be spent
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        /// @dev Reflects USDT specifications: If the new amount is not 0 and the current amount is not 0, an error occurs.
        require(!((amount != 0) && (_allowance[msg.sender][spender] != 0)), "Set allowance to 0 first");

        _allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    /**
     * @dev Override transfer function to mimic USDT's behavior without return value
     * @param to The address to transfer to
     * @param amount The amount to be transferred
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        if (blocked[to]) {
            revert("MockInvestmentERC20: blocked recipient");
        }
        _balanceOf[msg.sender] = _sub(_balanceOf[msg.sender], amount);
        _balanceOf[to] = _add(_balanceOf[to], amount);

        emit Transfer(msg.sender, to, amount);

        /// @dev Assembly code for emulating USDT's no return value behavior
        //       While maintaining the return value for the compiler, ignore the return value when actually calling it.
        assembly {
            // Exit without setting a return value
            return(0, 0)
        }
    }

    /**
     * @dev Override transferFrom function to mimic USDT's behavior without return value
     * @param from The address to transfer from
     * @param to The address to transfer to
     * @param amount The amount to be transferred
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        uint256 allowed = _allowance[from][msg.sender];

        if (allowed != ~uint256(0)) _allowance[from][msg.sender] = _sub(allowed, amount);

        _balanceOf[from] = _sub(_balanceOf[from], amount);
        _balanceOf[to] = _add(_balanceOf[to], amount);

        emit Transfer(from, to, amount);

        /// @dev Assembly code for emulating USDT's no return value behavior
        //       While maintaining the return value for the compiler, ignore the return value when actually calling it.
        assembly {
            // Exit without setting a return value
            return(0, 0)
        }
    }
}
