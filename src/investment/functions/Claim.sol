// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {Storage} from "bundle/investment/storage/Storage.sol";
import {Schema} from "bundle/investment/storage/Schema.sol";
import {IInvestmentErrors} from "bundle/investment/interfaces/IInvestmentErrors.sol";
import {IInvestmentEvents} from "bundle/investment/interfaces/IInvestmentEvents.sol";
import {UsdtTransferLib} from "bundle/investment/utils/UsdtTransferLib.sol";

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IInvestmentNFT} from "bundle/periphery/interfaces/IInvestmentNFT.sol";

/**
 * @title Claim
 * @notice Allows NFT owners to claim escrowed yield or principal after failed push transfers
 */
contract Claim is ReentrancyGuard {
    /**
     * @notice Claims escrowed yield for a distribution round
     * @param productId Product identifier
     * @param tokenId NFT token id
     * @param distributionIndex Distribution round index (1-based)
     */
    function claimYield(uint256 productId, uint256 tokenId, uint256 distributionIndex) external nonReentrant {
        Schema.Product storage product = Storage.ProductsState().products[productId];
        if (product.productId == 0) {
            revert IInvestmentErrors.ProductNotFound();
        }

        IInvestmentNFT nft = IInvestmentNFT(product.nftContract);
        if (nft.getInvestmentAmount(tokenId) == 0) {
            revert IInvestmentErrors.ProductNotFound();
        }
        if (IERC721(product.nftContract).ownerOf(tokenId) != msg.sender) {
            revert IInvestmentErrors.NotNFTOwner();
        }

        Schema.$EscrowState storage escrow = Storage.EscrowState();
        uint256 amount = escrow.unclaimedYield[productId][tokenId][distributionIndex];
        if (amount == 0) {
            revert IInvestmentErrors.NothingToClaim();
        }
        escrow.unclaimedYield[productId][tokenId][distributionIndex] = 0;

        IERC20 usdt = IERC20(Storage.ConfigState().USDT_ADDRESS);
        if (!UsdtTransferLib.tryTransfer(usdt, msg.sender, amount)) {
            escrow.unclaimedYield[productId][tokenId][distributionIndex] = amount;
            revert IInvestmentErrors.ClaimTransferFailed();
        }

        emit IInvestmentEvents.YieldReceived(productId, tokenId, msg.sender, amount);
        emit IInvestmentEvents.YieldClaimed(productId, tokenId, msg.sender, amount, distributionIndex);
    }

    /**
     * @notice Claims escrowed principal at maturity, sweeps any escrowed yield, and burns the NFT
     * @param productId Product identifier
     * @param tokenId NFT token id
     */
    function claimPrincipal(uint256 productId, uint256 tokenId) external nonReentrant {
        Schema.Product storage product = Storage.ProductsState().products[productId];
        if (product.productId == 0) {
            revert IInvestmentErrors.ProductNotFound();
        }
        if (!product.isMaturity) {
            revert IInvestmentErrors.ProductNotMatured();
        }

        IInvestmentNFT nft = IInvestmentNFT(product.nftContract);
        if (nft.getInvestmentAmount(tokenId) == 0) {
            revert IInvestmentErrors.ProductNotFound();
        }
        if (IERC721(product.nftContract).ownerOf(tokenId) != msg.sender) {
            revert IInvestmentErrors.NotNFTOwner();
        }

        Schema.$EscrowState storage escrow = Storage.EscrowState();
        uint256 principalAmount = escrow.unclaimedPrincipal[productId][tokenId];
        if (principalAmount == 0) {
            revert IInvestmentErrors.NothingToClaim();
        }

        uint256 totalUnclaimedYield = 0;
        for (uint256 j = 1; j <= product.distributedCount; j++) {
            totalUnclaimedYield += escrow.unclaimedYield[productId][tokenId][j];
        }

        uint256 totalAmount = principalAmount + totalUnclaimedYield;

        IERC20 usdt = IERC20(Storage.ConfigState().USDT_ADDRESS);
        if (!UsdtTransferLib.tryTransfer(usdt, msg.sender, totalAmount)) {
            revert IInvestmentErrors.ClaimTransferFailed();
        }

        escrow.unclaimedPrincipal[productId][tokenId] = 0;
        for (uint256 j = 1; j <= product.distributedCount; j++) {
            uint256 yieldAmount = escrow.unclaimedYield[productId][tokenId][j];
            if (yieldAmount > 0) {
                escrow.unclaimedYield[productId][tokenId][j] = 0;
                emit IInvestmentEvents.YieldReceived(productId, tokenId, msg.sender, yieldAmount);
                emit IInvestmentEvents.YieldClaimed(productId, tokenId, msg.sender, yieldAmount, j);
            }
        }

        nft.burn(tokenId);
        emit IInvestmentEvents.InvestmentReturned(productId, tokenId, msg.sender, principalAmount);
        emit IInvestmentEvents.PrincipalClaimed(productId, tokenId, msg.sender, principalAmount);
    }
}

// Testing
import {MCTest} from "@mc-devkit/Flattened.sol";
import {MockInvestmentERC20} from "test/investment/mocks/MockInvestmentERC20.sol";
import {InvestmentNFT} from "bundle/periphery/InvestmentNFT.sol";
import {DistributionDateLib} from "bundle/investment/utils/DistributionDateLib.sol";
import {CalculateYieldLib} from "bundle/investment/utils/CalculateYieldLib.sol";
import {DistributeYield} from "bundle/investment/functions/onlyWhiteLists/DistributeYield.sol";

contract ClaimTest is MCTest {
    uint256 constant PRODUCT_ID = 1;
    uint256 constant OFFERING_AMOUNT = 1_000_000_000_000;
    uint256 constant MIN_INVESTMENT = 250_000_000;
    uint256 constant OFFERING_END_DATE = 1737763200;
    uint256 constant MATURITY_DATE = 1767225600;
    uint256 constant EXPECTED_YIELD = 500;
    uint256 constant OPERATION_STARTDATE = 1738368000;
    uint256 constant DISTRIBUTION_START_DATE = 1748736000;
    uint256 constant TOTAL_DISTRIBUTION_COUNT = 3;
    uint256 constant DISTRIBUTION_INTERVAL = 3;

    address admin = address(0x1);
    address investor1 = address(0x3);
    address investor2 = address(0x4);

    MockInvestmentERC20 usdt;
    IInvestmentNFT nft;

    function setUp() public {
        usdt = new MockInvestmentERC20();
        nft = new InvestmentNFT("NFT", "NFT", PRODUCT_ID, "", address(0));

        _use(DistributeYield.distributeYield.selector, address(new DistributeYield()));
        _use(Claim.claimYield.selector, address(new Claim()));

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

        Storage.ProductsState().products[PRODUCT_ID] = product;
        Storage.ProductsState().productIdKeys.push(PRODUCT_ID);
        Storage.WhiteListsState().admins.push(admin);
        Storage.ConfigState().USDT_ADDRESS = address(usdt);
    }

    function test_claimYield_success_afterEscrow() public {
        uint256 investment1 = OFFERING_AMOUNT / 2;
        uint256 investment2 = OFFERING_AMOUNT / 2;
        uint256 firstPeriod =
            DistributionDateLib.calculateFirstDistributionPeriod(DISTRIBUTION_START_DATE, OPERATION_STARTDATE);

        Schema.Product storage product = Storage.ProductsState().products[PRODUCT_ID];
        product.raisedAmount = investment1 + investment2;
        nft.mint(investor1, investment1);
        nft.mint(investor2, investment2);

        uint256 periodYield =
            CalculateYieldLib.calculatePeriodYield(product.raisedAmount, product.expectedYield, firstPeriod);
        uint256 individualPeriodYield2 =
            CalculateYieldLib.calculateIndividualPeriodYield(periodYield, investment2, product.raisedAmount);
        uint256 tolerance = CalculateYieldLib.calculatePeriodTolerance(2);

        product.productPool = periodYield + tolerance;
        usdt.mint(address(this), periodYield + tolerance);
        usdt.setBlocked(investor2, true);

        vm.startPrank(admin);
        vm.warp(DISTRIBUTION_START_DATE);
        DistributeYield(target).distributeYield(PRODUCT_ID);
        vm.stopPrank();

        usdt.setBlocked(investor2, false);

        vm.prank(investor2);
        Claim(target).claimYield(PRODUCT_ID, 2, 1);

        assertEq(Storage.EscrowState().unclaimedYield[PRODUCT_ID][2][1], 0);
        assertEq(usdt.balanceOf(investor2), individualPeriodYield2);
    }

    function test_claimYield_reverts_whenTransferFails() public {
        uint256 investment1 = OFFERING_AMOUNT / 2;
        uint256 investment2 = OFFERING_AMOUNT / 2;
        uint256 firstPeriod =
            DistributionDateLib.calculateFirstDistributionPeriod(DISTRIBUTION_START_DATE, OPERATION_STARTDATE);

        Schema.Product storage product = Storage.ProductsState().products[PRODUCT_ID];
        product.raisedAmount = investment1 + investment2;
        nft.mint(investor1, investment1);
        nft.mint(investor2, investment2);

        uint256 periodYield =
            CalculateYieldLib.calculatePeriodYield(product.raisedAmount, product.expectedYield, firstPeriod);
        uint256 individualPeriodYield2 =
            CalculateYieldLib.calculateIndividualPeriodYield(periodYield, investment2, product.raisedAmount);
        uint256 tolerance = CalculateYieldLib.calculatePeriodTolerance(2);

        product.productPool = periodYield + tolerance;
        usdt.mint(address(this), periodYield + tolerance);
        usdt.setBlocked(investor2, true);

        vm.startPrank(admin);
        vm.warp(DISTRIBUTION_START_DATE);
        DistributeYield(target).distributeYield(PRODUCT_ID);
        vm.stopPrank();

        vm.prank(investor2);
        vm.expectRevert(IInvestmentErrors.ClaimTransferFailed.selector);
        Claim(target).claimYield(PRODUCT_ID, 2, 1);

        assertEq(Storage.EscrowState().unclaimedYield[PRODUCT_ID][2][1], individualPeriodYield2);
    }
}
