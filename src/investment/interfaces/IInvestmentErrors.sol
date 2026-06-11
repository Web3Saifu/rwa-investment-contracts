// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

/**
 * @title InvestmentErrors
 * @notice Error definitions for Investment
 * @custom:version 0.1.0
 */
interface IInvestmentErrors {
    // ======== General Errors ========
    /**
     * @notice Thrown when trying to initialize an already initialized proxy contract
     */
    error AlreadyInitialized();

    /**
     * @notice Thrown when calling a method before initialization
     */
    error NotInitialized();

    /**
     * @notice Thrown when an invalid address is provided
     */
    error InvalidAddress();

    /**
     * @notice Thrown when an address is not the owner
     */
    error NotOwner();

    // ======== Admin Errors ========
    /**
     * @notice Thrown when an address that is not registered as admin attempts admin operations
     */
    error NotAdmin();

    /**
     * @notice Thrown when attempting to add an address that is already registered as admin
     */
    error AlreadyExistsAdmin();

    /**
     * @notice Thrown when attempting to delete an address that is not registered as admin
     */
    error NotExistsAdmin();

    /**
     * @notice Thrown when attempting to add an admin beyond the maximum allowed count
     */
    error AdminLimitReached();

    // ======== Minter Errors ========
    /**
     * @notice Thrown when an address that is not registered as minter attempts mint operations
     */
    error NotMinter();

    /**
     * @notice Thrown when attempting to add an address that is already registered as minter
     */
    error AlreadyExistsMinter();

    /**
     * @notice Thrown when attempting to delete an address that is not registered as minter
     */
    error NotExistsMinter();

    /**
     * @notice Thrown when attempting to add a minter beyond the maximum allowed count
     */
    error MinterLimitReached();

    // ======== Investment Errors ========
    /**
     * @notice Thrown when attempting to register a product with an ID that already exists
     */
    error ProductAlreadyExists();

    /**
     * @notice Thrown when attempting to register a product with an invalid product ID
     */
    error InvalidProductId();

    /**
     * @notice Thrown when the offering amount is invalid
     */
    error InvalidOfferingAmount();

    /**
     * @notice Thrown when the minimum investment is invalid
     */
    error InvalidMinInvestment();

    /**
     * @notice Thrown when the offering amount is not exactly divisible by the minimum investment amount
     * @dev This error occurs when validating that the offering amount is a perfect multiple of minInvestment.
     *      The contract requires that the total offering can be divided into whole investment units(offeringAmount = unitCount * minInvestment)
     */
    error OfferingAmountNotDivisibleByMinInvestment();

    /**
     * @notice Thrown when the offering end date is invalid
     */
    error InvalidOfferingEndDate();

    /**
     * @notice Thrown when the maturity date is invalid
     */
    error InvalidMaturityDate();

    /**
     * @notice Thrown when the expected yield is invalid
     */
    error InvalidExpectedYield();

    /**
     * @notice Thrown when the operation start date is invalid
     */
    error InvalidOperationStartDate();

    /**
     * @notice Thrown when the distribution start date is invalid
     */
    error InvalidDistributionStartDate();

    /**
     * @notice Thrown when the total distribution count is invalid
     */
    error InvalidTotalDistributionCount();

    /**
     * @notice Thrown when the distribution interval is invalid
     */
    error InvalidDistributionInterval();

    /**
     * @notice Thrown when the distribution period is invalid
     */
    error InvalidDistributionPeriod();

    /**
     * @notice Thrown when attempting to access a non-existent product
     */
    error ProductNotFound();

    /**
     * @notice Thrown when an invalid address is provided
     */
    error ZeroAddress();

    /**
     * @notice Thrown when attempting to deposit zero amount
     */
    error ZeroAmount();

    /**
     * @notice Thrown when attempting to invest in a matured product
     */
    error MaturedProduct();

    /**
     * @notice Thrown when attempting to invest after the offering period ended
     */
    error OfferingPeriodEnded();

    /**
     * @notice Thrown when attempting to mint NFT after the operation start date
     */
    error OperationStartDatePassed();

    /**
     * @notice Thrown when attempting to invest more than the offering amount
     */
    error ExceedOfferingAmount();

    /**
     * @notice Thrown when there are insufficient funds for the requested operation
     */
    error InsufficientFunds();

    /**
     * @notice Thrown when there is insufficient allowance for the requested operation
     */
    error InsufficientAllowance();

    /**
     * @notice Thrown when the distribution is completed
     */
    error DistributionCompleted();

    /**
     * @notice Thrown when there is insufficient product pool for distribution
     */
    error InsufficientProductPool();

    /**
     * @notice Thrown when attempting to distribute yield before the distribution start date
     */
    error BeforeDistributionStartDate();

    /**
     * @notice Thrown when attempting to process maturity before the maturity date
     */
    error BeforeMaturityDate();

    /**
     * @notice Thrown when attempting to process maturity before the distribution is completed
     */
    error BeforeDistributionCompleted();

    /**
     * @notice Thrown when attempting to claim principal before the product has matured
     */
    error ProductNotMatured();

    // ======== Escrow / Claim Errors ========
    /**
     * @notice Thrown when caller is not the current owner of the NFT
     */
    error NotNFTOwner();

    /**
     * @notice Thrown when there is no escrowed amount to claim
     */
    error NothingToClaim();

    /**
     * @notice Thrown when escrow slot is already set for this distribution
     */
    error EscrowAlreadySet();

    /**
     * @notice Thrown when USDT transfer fails during claim (escrow restored)
     */
    error ClaimTransferFailed();

    // ======== Tier / Membership Errors ========
    /**
     * @notice Thrown when the investor does not hold an SBT that satisfies the product's required tier
     * @param requiredTier The minimum tier required for the product
     */
    error NotEligible(uint8 requiredTier);

    /**
     * @notice Thrown when registering a product with a tier that has no SBT contracts configured in the registry
     * @param tier The tier specified by the product
     */
    error TierNotConfigured(uint8 tier);

    // ======== Tier Registry (Admin config) Errors ========
    /// @notice Thrown when configuring tokenIds for an SBT that is not registered in the tier's allow-list.
    error TierSbtNotRegistered(uint8 tier, address sbt);

    /// @notice Thrown when an SBT address is zero or not a deployed contract (EOA/zero) in tier registry admin calls.
    error TierSbtNotContract(address sbt);

    /// @notice Thrown when configuring tokenIds for an SBT that is not ERC1155.
    error TierSbtNotErc1155(address sbt);

    /// @notice Thrown when an array argument contains duplicate entries (e.g. `setAllowedByTierAddress` sbts or `setAllowedByTierId` ids).
    error DuplicateEntry();
}
