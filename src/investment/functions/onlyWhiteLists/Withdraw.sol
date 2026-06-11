// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Storage} from "bundle/investment/storage/Storage.sol";
import {Schema} from "bundle/investment/storage/Schema.sol";
import {IInvestmentErrors} from "bundle/investment/interfaces/IInvestmentErrors.sol";
import {IInvestmentEvents} from "bundle/investment/interfaces/IInvestmentEvents.sol";
import {OnlyWhiteListsBase} from "bundle/investment/functions/onlyWhiteLists/OnlyWhiteListsBase.sol";

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Withdraw
 * @notice Contract for withdrawing USDT from product pools
 * @dev Inherits from OnlyWhiteListsBase, allowing only admin access
 */
contract Withdraw is ReentrancyGuard, OnlyWhiteListsBase {
    using SafeERC20 for IERC20;

    /**
     * @notice Withdraws USDT from a specified product pool
     * @dev Transfers the withdrawn USDT to the configured multisig wallet
     * @param productId The ID of the product to withdraw from
     * @param withdrawAmount The amount of USDT to withdraw (6 decimals)
     * @custom:throws ProductNotFound If the specified product does not exist
     * @custom:throws ZeroAmount If the withdrawal amount is zero
     * @custom:throws InsufficientProductPool If the product pool balance is insufficient
     * @custom:throws InsufficientFunds If the contract's USDT balance is insufficient
     * @custom:emits Withdrawn When the withdrawal is successful
     */
    function withdraw(uint256 productId, uint256 withdrawAmount) external nonReentrant onlyWhiteLists {
        Schema.Product storage product = Storage.ProductsState().products[productId];

        if (product.productId == 0) revert IInvestmentErrors.ProductNotFound();
        if (withdrawAmount == 0) revert IInvestmentErrors.ZeroAmount();
        if (withdrawAmount > product.productPool) {
            revert IInvestmentErrors.InsufficientProductPool();
        }

        // USDT token
        IERC20 usdt = IERC20(Storage.ConfigState().USDT_ADDRESS);
        if (withdrawAmount > usdt.balanceOf(address(this))) {
            revert IInvestmentErrors.InsufficientFunds();
        }

        // Update product state
        product.productPool -= withdrawAmount;

        usdt.safeTransfer(Storage.ConfigState().SAFE_MULTISIG_WALLET, withdrawAmount);

        emit IInvestmentEvents.Withdrawn(productId, msg.sender, withdrawAmount, product.productPool);
    }
}

// Testing
import {MCTest} from "@mc-devkit/Flattened.sol";
import {MockInvestmentERC20} from "test/investment/mocks/MockInvestmentERC20.sol";
import {InvestmentNFT} from "bundle/periphery/InvestmentNFT.sol";

/**
 * @title WithdrawTest
 * @notice Test contract for the Withdraw function contract
 */
contract WithdrawTest is MCTest {
    // Constants for test setup
    uint256 constant PRODUCT_ID = 1;
    uint256 constant OFFERING_AMOUNT = 1_000_000_000_000; // 1_000_000USD(1USD = 150JPY: 150_000_000JPY)
    uint256 constant MIN_INVESTMENT = 250_000_000; // 250USD(1USD = 150JPY: 37_500JPY)
    uint256 constant OFFERING_END_DATE = 1737763200; // 2025-01-25 00:00:00 UTC
    uint256 constant MATURITY_DATE = 1767225600; // 2026-01-01 00:00:00 UTC
    uint256 constant EXPECTED_YIELD = 500; // 5%
    uint256 constant OPERATION_STARTDATE = 1738368000; // 2025-02-01 00:00:00 UTC
    uint256 constant DISTRIBUTION_START_DATE = 1748736000; // 2025-06-01 00:00:00 UTC
    uint256 constant TOTAL_DISTRIBUTION_COUNT = 3;
    uint256 constant DISTRIBUTION_INTERVAL = 3; // 3 months

    uint256 constant WITHDRAW_AMOUNT = 500_000_000_000;

    // Test accounts
    address admin = address(0x1);
    address notAdmin = address(0x2);
    address safeWallet = address(0x3);

    // Contract instances
    MockInvestmentERC20 usdt;
    InvestmentNFT nft;

    function setUp() public {
        // Setup mock USDT
        usdt = new MockInvestmentERC20();
        usdt.mint(address(this), WITHDRAW_AMOUNT * 2);

        // Setup NFT
        nft = new InvestmentNFT("NFT", "NFT", PRODUCT_ID, "", address(0));

        // Setup Withdraw contract
        _use(Withdraw.withdraw.selector, address(new Withdraw()));

        // Register test product
        Schema.Product memory product = Schema.Product({
            productId: PRODUCT_ID,
            nftContract: address(nft),
            offeringAmount: OFFERING_AMOUNT,
            minInvestment: MIN_INVESTMENT,
            offeringEndDate: OFFERING_END_DATE,
            raisedAmount: 0,
            productPool: WITHDRAW_AMOUNT,
            maturityDate: MATURITY_DATE,
            expectedYield: EXPECTED_YIELD,
            operationStartDate: OPERATION_STARTDATE,
            distributionStartDate: DISTRIBUTION_START_DATE,
            totalDistributionCount: TOTAL_DISTRIBUTION_COUNT,
            distributionInterval: DISTRIBUTION_INTERVAL,
            distributedCount: 0,
            distributedYieldPerCount: 0,
            distributedTokenId: 0,
            totalReturnedAmount: 0,
            maturedTokenId: 0,
            requiredTier: 0,
            isMaturity: false,
            isInsufficientBalance: false,
            isMonthEnd: false
        });

        // Setup storage
        Storage.ProductsState().products[PRODUCT_ID] = product;
        Storage.ProductsState().productIdKeys.push(PRODUCT_ID);
        Storage.WhiteListsState().admins.push(admin);
        Storage.ConfigState().USDT_ADDRESS = address(usdt);
        Storage.ConfigState().SAFE_MULTISIG_WALLET = safeWallet;
    }

    function test_withdraw_success() public {
        uint256 withdrawAmount = WITHDRAW_AMOUNT;
        uint256 initialPool = Storage.ProductsState().products[PRODUCT_ID].productPool;

        vm.startPrank(admin);

        vm.expectEmit(true, true, false, true);
        emit IInvestmentEvents.Withdrawn(PRODUCT_ID, admin, withdrawAmount, initialPool - withdrawAmount);

        Withdraw(target).withdraw(PRODUCT_ID, withdrawAmount);

        assertEq(usdt.balanceOf(safeWallet), withdrawAmount);
        assertEq(Storage.ProductsState().products[PRODUCT_ID].productPool, initialPool - withdrawAmount);
        vm.stopPrank();
    }

    function testFuzz_withdraw_success(uint256 withdrawAmount) public {
        uint256 initialPool = Storage.ProductsState().products[PRODUCT_ID].productPool;
        vm.assume(withdrawAmount > 0);
        vm.assume(withdrawAmount <= initialPool);

        vm.startPrank(admin);

        vm.expectEmit(true, true, false, true);
        emit IInvestmentEvents.Withdrawn(PRODUCT_ID, admin, withdrawAmount, initialPool - withdrawAmount);

        Withdraw(target).withdraw(PRODUCT_ID, withdrawAmount);

        assertEq(usdt.balanceOf(safeWallet), withdrawAmount);
        assertEq(Storage.ProductsState().products[PRODUCT_ID].productPool, initialPool - withdrawAmount);
        vm.stopPrank();
    }

    function test_withdraw_revert_whenNotAdmin() public {
        uint256 withdrawAmount = WITHDRAW_AMOUNT;

        vm.startPrank(notAdmin);

        vm.expectRevert(IInvestmentErrors.NotAdmin.selector);
        Withdraw(target).withdraw(PRODUCT_ID, withdrawAmount);

        assertEq(usdt.balanceOf(safeWallet), 0);

        vm.stopPrank();
    }

    function test_withdraw_revert_whenProductNotFound() public {
        uint256 invalidProductId = 99;

        vm.startPrank(admin);

        vm.expectRevert(IInvestmentErrors.ProductNotFound.selector);
        Withdraw(target).withdraw(invalidProductId, WITHDRAW_AMOUNT);

        assertEq(usdt.balanceOf(safeWallet), 0);

        vm.stopPrank();
    }

    function test_withdraw_revert_whenZeroAmount() public {
        vm.startPrank(admin);

        vm.expectRevert(IInvestmentErrors.ZeroAmount.selector);
        Withdraw(target).withdraw(PRODUCT_ID, 0);

        assertEq(usdt.balanceOf(safeWallet), 0);

        vm.stopPrank();
    }

    function test_withdraw_revert_whenExceedsProductPool() public {
        uint256 initialPool = Storage.ProductsState().products[PRODUCT_ID].productPool;
        uint256 withdrawAmount = initialPool + 1;

        vm.startPrank(admin);

        vm.expectRevert(IInvestmentErrors.InsufficientProductPool.selector);
        Withdraw(target).withdraw(PRODUCT_ID, withdrawAmount);

        assertEq(Storage.ProductsState().products[PRODUCT_ID].productPool, initialPool);
        assertEq(usdt.balanceOf(safeWallet), 0);

        vm.stopPrank();
    }

    function test_withdraw_revert_whenInsufficientBalance() public {
        uint256 withdrawAmount = WITHDRAW_AMOUNT * 3; // More than contract balance
        Storage.ProductsState().products[PRODUCT_ID].productPool = withdrawAmount;

        vm.startPrank(admin);

        vm.expectRevert(IInvestmentErrors.InsufficientFunds.selector);
        Withdraw(target).withdraw(PRODUCT_ID, withdrawAmount);

        assertEq(usdt.balanceOf(safeWallet), 0);

        vm.stopPrank();
    }

    receive() external payable {}
}
