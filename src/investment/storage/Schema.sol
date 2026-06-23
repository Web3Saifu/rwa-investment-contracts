// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

/**
 * @title Investment Schema v0.1.0
 */
library Schema {//Data structure কেমন হবে
    struct $ProductsState {
        mapping(uint256 productId => Product) products;
        uint256[] productIdKeys;//এখন সব product IDs জানা গেল।
        uint256[] activeProductIdKeys;
        mapping(uint256 productId => uint256) activeIndex; // 1-indexed for O(1) swap-and-pop
    }

    struct Product {
        uint256 productId;
        address nftContract;
        uint256 offeringAmount;//offeringAmount = 1,000,000
        uint256 minInvestment;
        uint256 offeringEndDate;
        uint256 raisedAmount;//raisedAmount = 650,000
        uint256 productPool;//!
        uint256 maturityDate;
        uint256 expectedYield;
        uint256 operationStartDate;
        uint256 distributionStartDate;
        uint256 totalDistributionCount;//12 installments
        uint256 distributionInterval;
        uint256 distributedCount;
        uint256 distributedYieldPerCount;
        uint256 distributedTokenId;//!
        uint256 totalReturnedAmount;//Investors-দের মোট কত ফেরত দেওয়া হয়েছে।
        uint256 maturedTokenId;//!
        uint8 requiredTier;
        bool isMaturity;
        bool isInsufficientBalance;
        bool isMonthEnd;
    }

    struct $TierRegistryState {
        mapping(uint8 => address[]) allowedByTierAddress;//Tier Number => Address List
        mapping(uint8 => mapping(address => uint256[])) allowedByTierId;//Tier 2-এ Alice-এর IDs কী কী?
    }

    struct $WhiteListsState {
        address[] admins;
    }

    struct $MintersState {
        address[] minters;
    }

    struct $ConfigState {
        address USDT_ADDRESS;
        address SAFE_MULTISIG_WALLET;//Usually protocol funds are managed through this wallet.
    }

    struct $EscrowState {
        mapping(uint256 productId => mapping(uint256 tokenId => mapping(uint256 distributionIndex => uint256)))
            unclaimedYield;
            /*Product ID = 1
NFT Token ID = 100
Distribution Round = 3

500 USDT yield is still unclaimed.*/
        mapping(uint256 productId => mapping(uint256 tokenId => uint256)) unclaimedPrincipal;
    }

    /// @notice One unclaimed yield slot for a token
    struct ClaimableYieldSlot {
        uint256 distributionIndex;//Distribution #3
        uint256 amount;//Claimable Yield = 500
    }

    /// @notice Claimable balances for a token and account (view helper)
    struct TokenClaimableStatus {
        uint256 unclaimedPrincipal;
        ClaimableYieldSlot[] yieldSlots;//sots or Round
        bool isOwner;//Caller owns the NFT: Yes
    }

    struct RegisterProductArgs {
        uint256 productId;
        uint256 offeringAmount;//Maximum amount that can be raised.
        uint256 minInvestment;
        uint256 offeringEndDate;
        uint256 maturityDate;
        uint256 expectedYield;
        uint256 operationStartDate;
        uint256 distributionStartDate;
        uint256 totalDistributionCount;
        uint256 distributionInterval;
        string baseTokenURI;
        uint8 requiredTier;//hen only Tier 2 (or whatever the protocol defines) can participate.
    }
}
