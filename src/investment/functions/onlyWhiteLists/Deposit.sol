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
 * @title Deposit
 * @notice Contract for managing USDT deposits into product pools
 * @dev Inherits from OnlyWhiteListsBase to restrict deposits to admins only
 */
contract Deposit is ReentrancyGuard, OnlyWhiteListsBase {
    using SafeERC20 for IERC20;

    /**
     * @notice Deposits USDT into a specified product pool
     * @dev Only allows deposits if the product exists and is not matured
     * @param productId The ID of the product to deposit into
     * @param depositAmount The amount of USDT to deposit
     * @custom:throws ProductNotFound If the product does not exist
     * @custom:throws ZeroAmount If the deposit amount is zero
     * @custom:throws MaturedProduct If the product has matured
     * @custom:throws InsufficientFunds If the sender has insufficient USDT balance
     * @custom:throws InsufficientAllowance If the contract has insufficient allowance to transfer USDT
     * @custom:emit Deposited When the deposit is successful
     * @custom:emit ProductPoolRecovered When deposit clears isInsufficientBalance stall
     */
    function deposit(uint256 productId, uint256 depositAmount) external nonReentrant onlyWhiteLists {
        Schema.Product storage product = Storage.ProductsState().products[productId];

        if (product.productId == 0) revert IInvestmentErrors.ProductNotFound();
        if (depositAmount == 0) revert IInvestmentErrors.ZeroAmount();
        if (product.isMaturity) revert IInvestmentErrors.MaturedProduct();

        // USDT token
        IERC20 usdt = IERC20(Storage.ConfigState().USDT_ADDRESS);
        if (depositAmount > usdt.balanceOf(msg.sender)) {
            revert IInvestmentErrors.InsufficientFunds();
        }
        if (depositAmount > usdt.allowance(msg.sender, address(this))) {
            revert IInvestmentErrors.InsufficientAllowance();
        }

        // Update product state
        product.productPool += depositAmount;

        if (product.isInsufficientBalance) {
            product.isInsufficientBalance = false;
            emit IInvestmentEvents.ProductPoolRecovered(productId);
        }

        usdt.safeTransferFrom(msg.sender, address(this), depositAmount);

        emit IInvestmentEvents.Deposited(productId, msg.sender, depositAmount, product.productPool);
    }
}

// Testing
import {MCTest} from "@mc-devkit/Flattened.sol";
import {MockInvestmentERC20} from "test/investment/mocks/MockInvestmentERC20.sol";
import {InvestmentNFT} from "bundle/periphery/InvestmentNFT.sol";

/**
 * @title DepositTest
 * @notice Test contract for the Deposit function contract
 */
contract DepositTest is MCTest {
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

    uint256 constant DEPOSIT_AMOUNT = 1_000_000_000;

    // Test accounts
    address admin = address(0x1);
    address notAdmin = address(0x2);

    // Contract instances
    MockInvestmentERC20 usdt;
    InvestmentNFT nft;

    function setUp() public {
        // Setup mock USDT
        usdt = new MockInvestmentERC20();
        usdt.mint(admin, DEPOSIT_AMOUNT * 2);

        // Setup NFT
        nft = new InvestmentNFT("NFT", "NFT", PRODUCT_ID, "", address(0));

        // Setup Deposit contract
        _use(Deposit.deposit.selector, address(new Deposit()));

        // Register test product
        Schema.Product memory product = Schema.Product({
            productId: PRODUCT_ID,
            nftContract: address(nft),
            offeringAmount: OFFERING_AMOUNT,
            minInvestment: MIN_INVESTMENT,
            offeringEndDate: OFFERING_END_DATE,
            raisedAmount: 0,
            productPool: 0,
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
    }

    function test_deposit_success() public {
        uint256 depositAmount = DEPOSIT_AMOUNT;
        uint256 initialPool = Storage.ProductsState().products[PRODUCT_ID].productPool;

        vm.startPrank(admin);

        usdt.approve(address(this), depositAmount);

        vm.expectEmit(true, true, false, true);
        emit IInvestmentEvents.Deposited(PRODUCT_ID, admin, depositAmount, initialPool + depositAmount);

        Deposit(target).deposit(PRODUCT_ID, depositAmount);

        assertEq(usdt.balanceOf(address(this)), depositAmount);
        assertEq(Storage.ProductsState().products[PRODUCT_ID].productPool, initialPool + depositAmount);

        vm.stopPrank();
    }

    function testFuzz_deposit_success(uint256 depositAmount) public {
        vm.assume(depositAmount > 0);
        vm.assume(depositAmount <= usdt.balanceOf(admin));

        uint256 initialPool = Storage.ProductsState().products[PRODUCT_ID].productPool;

        vm.startPrank(admin);

        usdt.approve(address(this), depositAmount);

        vm.expectEmit(true, true, false, true);
        emit IInvestmentEvents.Deposited(PRODUCT_ID, admin, depositAmount, initialPool + depositAmount);

        Deposit(target).deposit(PRODUCT_ID, depositAmount);

        assertEq(usdt.balanceOf(address(this)), depositAmount);
        assertEq(Storage.ProductsState().products[PRODUCT_ID].productPool, initialPool + depositAmount);

        vm.stopPrank();
    }

    function test_deposit_revert_whenNotAdmin() public {
        uint256 depositAmount = DEPOSIT_AMOUNT;
        uint256 initialAdminBalance = usdt.balanceOf(admin);

        vm.startPrank(notAdmin);

        usdt.approve(address(this), depositAmount);

        vm.expectRevert(IInvestmentErrors.NotAdmin.selector);
        Deposit(target).deposit(PRODUCT_ID, depositAmount);

        assertEq(usdt.balanceOf(address(this)), 0);
        assertEq(Storage.ProductsState().products[PRODUCT_ID].productPool, 0);
        assertEq(usdt.balanceOf(admin), initialAdminBalance);

        vm.stopPrank();
    }

    function test_deposit_revert_whenProductNotFound() public {
        uint256 invalidProductId = 99;
        uint256 depositAmount = DEPOSIT_AMOUNT;
        uint256 initialAdminBalance = usdt.balanceOf(admin);

        vm.startPrank(admin);

        usdt.approve(address(this), depositAmount);

        vm.expectRevert(IInvestmentErrors.ProductNotFound.selector);
        Deposit(target).deposit(invalidProductId, depositAmount);

        assertEq(usdt.balanceOf(address(this)), 0);
        assertEq(Storage.ProductsState().products[invalidProductId].productPool, 0);
        assertEq(usdt.balanceOf(admin), initialAdminBalance);

        vm.stopPrank();
    }

    function test_deposit_revert_whenZeroAmount() public {
        vm.startPrank(admin);
        usdt.approve(address(this), DEPOSIT_AMOUNT);
        uint256 initialAdminBalance = usdt.balanceOf(admin);

        vm.expectRevert(IInvestmentErrors.ZeroAmount.selector);
        Deposit(target).deposit(PRODUCT_ID, 0);

        assertEq(usdt.balanceOf(address(this)), 0);
        assertEq(Storage.ProductsState().products[PRODUCT_ID].productPool, 0);
        assertEq(usdt.balanceOf(admin), initialAdminBalance);

        vm.stopPrank();
    }

    function test_deposit_revert_whenMaturedProduct() public {
        Storage.ProductsState().products[PRODUCT_ID].isMaturity = true;
        uint256 depositAmount = DEPOSIT_AMOUNT;
        uint256 initialAdminBalance = usdt.balanceOf(admin);

        vm.startPrank(admin);

        usdt.approve(address(this), depositAmount);

        vm.expectRevert(IInvestmentErrors.MaturedProduct.selector);
        Deposit(target).deposit(PRODUCT_ID, depositAmount);

        assertEq(usdt.balanceOf(address(this)), 0);
        assertEq(Storage.ProductsState().products[PRODUCT_ID].productPool, 0);
        assertEq(usdt.balanceOf(admin), initialAdminBalance);

        vm.stopPrank();
    }

    function test_deposit_revert_whenInsufficientBalance() public {
        uint256 depositAmount = usdt.balanceOf(admin) + 1;
        uint256 initialAdminBalance = usdt.balanceOf(admin);

        vm.startPrank(admin);
        usdt.approve(address(this), depositAmount);

        vm.expectRevert(IInvestmentErrors.InsufficientFunds.selector);
        Deposit(target).deposit(PRODUCT_ID, depositAmount);

        assertEq(usdt.balanceOf(address(this)), 0);
        assertEq(Storage.ProductsState().products[PRODUCT_ID].productPool, 0);
        assertEq(usdt.balanceOf(admin), initialAdminBalance);

        vm.stopPrank();
    }

    function test_deposit_revert_whenInsufficientAllowance() public {
        uint256 initialAdminBalance = usdt.balanceOf(admin);

        vm.startPrank(admin);

        vm.expectRevert(IInvestmentErrors.InsufficientAllowance.selector);
        Deposit(target).deposit(PRODUCT_ID, DEPOSIT_AMOUNT);

        assertEq(usdt.balanceOf(address(this)), 0);
        assertEq(Storage.ProductsState().products[PRODUCT_ID].productPool, 0);
        assertEq(usdt.balanceOf(admin), initialAdminBalance);

        vm.stopPrank();
    }

    receive() external payable {}
}
