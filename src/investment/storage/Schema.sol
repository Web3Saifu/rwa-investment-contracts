// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

/**
 * @title Investment Schema v0.1.0
 */
library Schema {
    struct $ProductsState {
        mapping(uint256 productId => Product) products;
        uint256[] productIdKeys;
        uint256[] activeProductIdKeys;
        mapping(uint256 productId => uint256) activeIndex; // 1-indexed for O(1) swap-and-pop
    }

    struct Product {
        uint256 productId;
        address nftContract;
        uint256 offeringAmount;
        uint256 minInvestment;
        uint256 offeringEndDate;
        uint256 raisedAmount;
        uint256 productPool;
        uint256 maturityDate;
        uint256 expectedYield;
        uint256 operationStartDate;
        uint256 distributionStartDate;
        uint256 totalDistributionCount;
        uint256 distributionInterval;
        uint256 distributedCount;
        uint256 distributedYieldPerCount;
        uint256 distributedTokenId;
        uint256 totalReturnedAmount;
        uint256 maturedTokenId;
        uint8 requiredTier;
        bool isMaturity;
        bool isInsufficientBalance;
        bool isMonthEnd;
    }

    struct $TierRegistryState {
        mapping(uint8 => address[]) allowedByTierAddress;
        mapping(uint8 => mapping(address => uint256[])) allowedByTierId;
    }

    struct $WhiteListsState {
        address[] admins;
    }

    struct $MintersState {
        address[] minters;
    }

    struct $ConfigState {
        address USDT_ADDRESS;
        address SAFE_MULTISIG_WALLET;
    }

    struct $EscrowState {
        mapping(uint256 productId => mapping(uint256 tokenId => mapping(uint256 distributionIndex => uint256)))
            unclaimedYield;
        mapping(uint256 productId => mapping(uint256 tokenId => uint256)) unclaimedPrincipal;
    }

    /// @notice One unclaimed yield slot for a token
    struct ClaimableYieldSlot {
        uint256 distributionIndex;
        uint256 amount;
    }

    /// @notice Claimable balances for a token and account (view helper)
    struct TokenClaimableStatus {
        uint256 unclaimedPrincipal;
        ClaimableYieldSlot[] yieldSlots;
        bool isOwner;
    }

    struct RegisterProductArgs {
        uint256 productId;
        uint256 offeringAmount;
        uint256 minInvestment;
        uint256 offeringEndDate;
        uint256 maturityDate;
        uint256 expectedYield;
        uint256 operationStartDate;
        uint256 distributionStartDate;
        uint256 totalDistributionCount;
        uint256 distributionInterval;
        string baseTokenURI;
        uint8 requiredTier;
    }
}
