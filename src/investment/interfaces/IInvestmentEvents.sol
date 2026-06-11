// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

/**
 * @title InvestmentEvents
 * @dev Event definitions for Investment
 * @custom:version 0.1.0
 */
interface IInvestmentEvents {
    // ======== Product Events ========
    /**
     * @notice Emitted when a new investment product is registered
     * @param productId Unique identifier for the product
     * @param offeringAmount Total amount being offered for investment
     * @param minInvestment Minimum investment amount required
     * @param offeringEndDate Date when the offering ends
     * @param maturityDate Date when the product reaches maturity
     * @param expectedYield Expected yield pertenk
     * @param operationStartDate Date when the operation starts
     * @param distributionStartDate Date when yield distribution begins
     * @param totalDistributionCount Total number of yield distributions planned
     * @param distributionInterval Time interval between distributions in seconds
     * @param nftContractAddress Address of the NFT contract representing investment units
     * @param requiredTier Minimum tier required to invest (0 = none)
     * @param isMonthEnd Whether distribution dates follow month-end scheduling
     */
    event ProductRegistered(
        uint256 indexed productId,
        uint256 offeringAmount,
        uint256 minInvestment,
        uint256 offeringEndDate,
        uint256 maturityDate,
        uint256 expectedYield,
        uint256 operationStartDate,
        uint256 distributionStartDate,
        uint256 totalDistributionCount,
        uint256 distributionInterval,
        address nftContractAddress,
        uint8 requiredTier,
        bool isMonthEnd
    );

    /**
     * @notice Emitted when admin deposit clears the insufficient-balance stall
     * @param productId ID of the product
     */
    event ProductPoolRecovered(uint256 indexed productId);

    /**
     * @notice Emitted when an admin updates a product's required tier
     * @param productId ID of the product
     * @param previousRequiredTier Tier before the update
     * @param newRequiredTier Tier after the update
     */
    event ProductRequiredTierUpdated(uint256 indexed productId, uint8 previousRequiredTier, uint8 newRequiredTier);

    // ======== Investment Events ========
    /**
     * @notice Emitted when an investment is made in a product
     * @param productId ID of the product being invested in
     * @param investor Address of the investor
     * @param unitCount Number of investment units purchased
     * @param investmentAmount Total amount invested
     * @param tokenId ID of the NFT issued for this investment
     */
    event Invested(
        uint256 indexed productId,
        address indexed investor,
        uint256 unitCount,
        uint256 investmentAmount,
        uint256 tokenId
    );

    // ======== Admin Events ========
    /**
     * @notice Emitted when an admin withdraws funds
     * @param productId ID of the product being withdrawn from
     * @param admin Address of the admin making the withdrawal
     * @param amount Amount withdrawn
     * @param productPool Updated product pool after withdrawal
     */
    event Withdrawn(uint256 indexed productId, address indexed admin, uint256 amount, uint256 productPool);

    /**
     * @notice Emitted when an admin deposits yield
     * @param productId ID of the product receiving the deposit
     * @param admin Address of the admin making the deposit
     * @param amount Amount deposited
     * @param productPool Updated product pool after deposit
     */
    event Deposited(uint256 indexed productId, address indexed admin, uint256 amount, uint256 productPool);

    // ======== Distribution Events ========
    /**
     * @notice Emitted when yield is distributed to token holders
     * @param productId ID of the product for which yield is distributed
     * @param distributionCount Current distribution number
     * @param startTokenId First token ID processed in this distribution
     * @param endTokenId Last token ID processed in this distribution
     * @param distributedAmount Total amount of yield distributed in this batch
     */
    event YieldDistributed(
        uint256 indexed productId,
        uint256 distributionCount,
        uint256 startTokenId,
        uint256 endTokenId,
        uint256 distributedAmount
    );

    /**
     * @notice Emitted when an individual token holder receives yield
     * @param productId ID of the product
     * @param tokenId ID of the NFT receiving yield
     * @param recipient Address receiving the yield
     * @param amount Amount of yield received
     */
    event YieldReceived(uint256 indexed productId, uint256 indexed tokenId, address indexed recipient, uint256 amount);

    /**
     * @notice Emitted when yield transfer to holder fails and amount is escrowed
     * @param productId ID of the product
     * @param tokenId ID of the NFT
     * @param recipient Address that failed to receive (owner at distribution time)
     * @param amount Amount escrowed
     * @param distributionIndex Distribution round index (1-based)
     */
    event YieldTransferFailed(
        uint256 indexed productId,
        uint256 indexed tokenId,
        address indexed recipient,
        uint256 amount,
        uint256 distributionIndex
    );

    /**
     * @notice Emitted when escrowed yield is claimed by the current NFT owner
     */
    event YieldClaimed(
        uint256 indexed productId,
        uint256 indexed tokenId,
        address indexed recipient,
        uint256 amount,
        uint256 distributionIndex
    );

    /**
     * @notice distribution InsufficientProductPool
     * @param productId ID of the product
     */
    event InsufficientProductPoolForDistribution(uint256 indexed productId);

    // ======== Maturity Events ========
    /**
     * @notice Emitted when a product reaches maturity and processing begins
     * @param productId ID of the matured product
     * @param startTokenId First token ID processed in maturity
     * @param endTokenId Last token ID processed in maturity
     * @param returnedAmount Total amount of return to investors from this batch processing
     */
    event ProductMatured(uint256 indexed productId, uint256 startTokenId, uint256 endTokenId, uint256 returnedAmount);

    /**
     * @notice Emitted when principal is returned to an investor at maturity
     * @param productId ID of the product
     * @param tokenId ID of the NFT being processed
     * @param investor Address receiving the returned investment
     * @param amount Amount returned to the investor
     */
    event InvestmentReturned(
        uint256 indexed productId, uint256 indexed tokenId, address indexed investor, uint256 amount
    );

    /**
     * @notice Emitted when principal transfer at maturity fails and amount is escrowed
     */
    event PrincipalTransferFailed(
        uint256 indexed productId, uint256 indexed tokenId, address indexed recipient, uint256 amount
    );

    /**
     * @notice Emitted when escrowed principal is claimed by the current NFT owner
     */
    event PrincipalClaimed(
        uint256 indexed productId, uint256 indexed tokenId, address indexed recipient, uint256 amount
    );

    /**
     * @notice maturity InsufficientProductPool
     * @param productId ID of the product
     */
    event InsufficientProductPoolForMaturity(uint256 indexed productId);

    // ======== Tier Registry Events ========
    /**
     * @notice Emitted when allowed SBT contracts for a tier are replaced
     * @param tier Tier id (NONE=0, BRONZE=1, ...)
     * @param sbts New list of SBT contract addresses for that tier
     */
    event TierAllowedByTierAddressUpdated(uint8 indexed tier, address[] sbts);
    /**
     * @notice Emitted when ERC1155 token ids for a tier are replaced for a given SBT contract
     * @param tier Tier id (NONE=0, BRONZE=1, ...)
     * @param sbt SBT contract address (must be ERC1155 for ids to be meaningful)
     * @param ids New list of token ids for that SBT under the tier
     */
    event TierAllowedByTierIdUpdated(uint8 indexed tier, address indexed sbt, uint256[] ids);

    // ======== Admin Management Events ========
    /**
     * @notice Emitted when a new admin is added
     * @param account Address of the newly added admin
     * @param addedBy Address of the admin who performed the addition
     */
    event AdminAdded(address indexed account, address indexed addedBy);

    /**
     * @notice Emitted when an admin is removed
     * @param account Address of the removed admin
     * @param removedBy Address of the admin who performed the removal
     */
    event AdminRemoved(address indexed account, address indexed removedBy);

    // ======== Minter Management Events ========
    /**
     * @notice Emitted when a new minter is added
     * @param account Address of the newly added minter
     * @param addedBy Address of the account who performed the addition
     */
    event MinterAdded(address indexed account, address indexed addedBy);

    /**
     * @notice Emitted when a minter is removed
     * @param account Address of the removed minter
     * @param removedBy Address of the account who performed the removal
     */
    event MinterRemoved(address indexed account, address indexed removedBy);
}
