// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IInvestment} from "bundle/investment/interfaces/IInvestment.sol";
import {Schema} from "bundle/investment/storage/Schema.sol";

/**
 * @title Investment Facade v0.1.0
 * @custom:version IInvestment:0.1.0
 */
contract InvestmentFacade is IInvestment {
    function registerProduct(Schema.RegisterProductArgs calldata args) external {}
    function invest(uint256 productId, uint256 unitCount) external {}
    function mintNFT(uint256 productId, uint256 unitCount, address investor) external {}
    function withdraw(uint256 productId, uint256 withdrawalAmount) external {}
    function deposit(uint256 productId, uint256 depositAmount) external {}
    function distributeYield(uint256 productId) external {}
    function maturity(uint256 productId) external {}
    function claimYield(uint256 productId, uint256 tokenId, uint256 distributionIndex) external {}
    function claimPrincipal(uint256 productId, uint256 tokenId) external {}
    function addAdmin(address _admin) external {}
    function deleteAdmin(address _admin) external {}
    function addMinter(address _minter) external {}
    function deleteMinter(address _minter) external {}
    function getProduct(uint256 _productId) external view returns (Schema.Product memory productInfo) {}
    function getAllProducts() external view returns (Schema.Product[] memory productsInfo) {}
    function getActiveProducts() external view returns (Schema.Product[] memory productsInfo) {}
    function getAdminList() external view returns (address[] memory adminList) {}
    function simulatePeriodYield(uint256 productId) external view returns (uint256[] memory) {}
    function simulateTotalYield(uint256 productId) external view returns (uint256) {}
    function getDistributionDates(uint256 productId) external view returns (uint256[] memory) {}
    function simulateIndividualPeriodYield(uint256 productId, uint256 tokenId)
        external
        view
        returns (uint256[] memory)
    {}
    function simulateIndividualTotalYield(uint256 productId, uint256 tokenId) external view returns (uint256) {}
    function setProductRequiredTier(uint256 productId, uint8 requiredTier) external {}
    function setAllowedByTierAddress(uint8 tier, address[] calldata sbts) external {}
    function getAllowedByTierAddress(uint8 tier) external view returns (address[] memory allowedAddresses) {}
    function setAllowedByTierId(uint8 tier, address sbt, uint256[] calldata ids) external {}
    function getAllowedByTierId(uint8 tier, address sbt) external view returns (uint256[] memory ids) {}
    function getUnclaimedYield(uint256 productId, uint256 tokenId, uint256 distributionIndex)
        external
        view
        returns (uint256 amount)
    {}
    function getUnclaimedPrincipal(uint256 productId, uint256 tokenId) external view returns (uint256 amount) {}
    function getClaimableYieldSlots(uint256 productId, uint256 tokenId)
        external
        view
        returns (Schema.ClaimableYieldSlot[] memory slots)
    {}
    function getClaimableForToken(uint256 productId, uint256 tokenId, address account)
        external
        view
        returns (Schema.TokenClaimableStatus memory status)
    {}
}
