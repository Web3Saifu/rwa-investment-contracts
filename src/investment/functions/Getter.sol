// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import "bundle/investment/interfaces/IInvestment.sol";
import {Schema} from "bundle/investment/storage/Schema.sol";
import {Storage} from "bundle/investment/storage/Storage.sol";
import {IInvestmentErrors} from "bundle/investment/interfaces/IInvestmentErrors.sol";
import {IInvestmentEvents} from "bundle/investment/interfaces/IInvestmentEvents.sol";
import {CalculateYieldLib} from "bundle/investment/utils/CalculateYieldLib.sol";
import {DistributionDateLib} from "bundle/investment/utils/DistributionDateLib.sol";

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IInvestmentNFT} from "bundle/periphery/interfaces/IInvestmentNFT.sol";

contract Getter {
    /**
     * @notice Returns the product information for the specified productId
     * @param _productId The ID of the product to retrieve
     * @return productInfo The product information structure
     */
    function getProduct(uint256 _productId) external view returns (Schema.Product memory productInfo) {
        productInfo = Storage.ProductsState().products[_productId];

        // If the product does not exist, productId remains 0
        if (productInfo.productId == 0) {
            revert IInvestmentErrors.ProductNotFound();
        }
        return productInfo;
    }

    /**
     * @notice Returns information for all products
     * @return productsInfo An array containing information for all products
     */
    function getAllProducts() external view returns (Schema.Product[] memory productsInfo) {
        uint256 productCount = Storage.ProductsState().productIdKeys.length;
        productsInfo = new Schema.Product[](productCount);
        for (uint256 i = 0; i < productCount; i++) {
            uint256 pid = Storage.ProductsState().productIdKeys[i];
            productsInfo[i] = Storage.ProductsState().products[pid];
        }
        return productsInfo;
    }

    /**
     * @notice Returns information for active (non-matured) products only
     * @return productsInfo An array containing information for active products
     */
    function getActiveProducts() external view returns (Schema.Product[] memory productsInfo) {
        uint256 count = Storage.ProductsState().activeProductIdKeys.length;
        productsInfo = new Schema.Product[](count);
        for (uint256 i = 0; i < count; i++) {
            uint256 pid = Storage.ProductsState().activeProductIdKeys[i];
            productsInfo[i] = Storage.ProductsState().products[pid];
        }
        return productsInfo;
    }

    /**
     * @notice Returns a list of administrator addresses
     * @return adminList An array of administrator addresses
     */
    function getAdminList() external view returns (address[] memory adminList) {
        adminList = Storage.WhiteListsState().admins;
        return adminList;
    }

    /**
     * @notice Returns NFT contract addresses registered for the given tier (used for eligibility via balanceOf)
     * @param tier Tier id (NONE = 0, BRONZE = 1, ...)
     * @return allowedAddresses Registered addresses for that tier (empty if unset)
     */
    function getAllowedByTierAddress(uint8 tier) external view returns (address[] memory allowedAddresses) {
        return Storage.TierRegistryState().allowedByTierAddress[tier];
    }

    /**
     * @notice Returns ERC1155 token ids registered for the given tier and SBT contract
     * @param tier Tier id (NONE = 0, BRONZE = 1, ...)
     * @param sbt SBT contract address (ERC1155 to be meaningful; ERC721 should return empty)
     * @return ids Registered token ids for that SBT under the tier (empty if unset)
     */
    function getAllowedByTierId(uint8 tier, address sbt) external view returns (uint256[] memory ids) {
        return Storage.TierRegistryState().allowedByTierId[tier][sbt];
    }

    /**
     * @notice Simulates yield for each distribution round (1st … totalDistributionCount), including per-period tolerance.
     * @return yields yields[k] = k-th distribution (0-based). Empty array if totalDistributionCount is 0.
     */
    function simulatePeriodYield(uint256 productId) external view returns (uint256[] memory yields) {
        Schema.Product storage product = Storage.ProductsState().products[productId];
        uint256 n = product.totalDistributionCount;
        if (n == 0) {
            return new uint256[](0);
        }

        yields = new uint256[](n);
        uint256 nftCount = IInvestmentNFT(product.nftContract).tokenIdCounter();
        uint256 tolerance = CalculateYieldLib.calculatePeriodTolerance(nftCount);

        uint256 firstPeriod = DistributionDateLib.calculateFirstDistributionPeriod(
            product.distributionStartDate, product.operationStartDate
        );
        yields[0] = CalculateYieldLib.calculatePeriodYield(product.raisedAmount, product.expectedYield, firstPeriod)
            + tolerance;

        for (uint256 i = 1; i < n; i++) {
            uint256 period = DistributionDateLib.calculateDistributionPeriod(
                product.distributionStartDate, product.distributionInterval, i, product.isMonthEnd
            );
            yields[i] =
                CalculateYieldLib.calculatePeriodYield(product.raisedAmount, product.expectedYield, period) + tolerance;
        }
    }

    /**
     * @notice Simulates the total yield for all investors (including the allowable error)
     * @return Total yield for all investors
     */
    function simulateTotalYield(uint256 productId) external view returns (uint256) {
        uint256 totalDistributionCount = Storage.ProductsState().products[productId].totalDistributionCount;
        uint256 nftCount = IInvestmentNFT(Storage.ProductsState().products[productId].nftContract).tokenIdCounter();
        uint256 tolerance = CalculateYieldLib.calculateTotalTolerance(nftCount, totalDistributionCount);
        // Calculate first period yield
        uint256 firstPeriod = DistributionDateLib.calculateFirstDistributionPeriod(
            Storage.ProductsState().products[productId].distributionStartDate,
            Storage.ProductsState().products[productId].operationStartDate
        );
        uint256 totalYield = CalculateYieldLib.calculatePeriodYield(
            Storage.ProductsState().products[productId].raisedAmount,
            Storage.ProductsState().products[productId].expectedYield,
            firstPeriod
        );

        // Calculate subsequent periods (2nd distribution onwards)
        for (uint256 i = 1; i < totalDistributionCount; i++) {
            uint256 period = DistributionDateLib.calculateDistributionPeriod(
                Storage.ProductsState().products[productId].distributionStartDate,
                Storage.ProductsState().products[productId].distributionInterval,
                i, // distributedCount for this period
                Storage.ProductsState().products[productId].isMonthEnd
            );
            totalYield += CalculateYieldLib.calculatePeriodYield(
                Storage.ProductsState().products[productId].raisedAmount,
                Storage.ProductsState().products[productId].expectedYield,
                period
            );
        }
        return totalYield + tolerance;
    }

    /**
     * @notice Returns scheduled distribution dates for each distribution round.
     * @param productId Product identifier
     * @return dates `dates.length == totalDistributionCount`. `dates[0]` is the 1st distribution date. Empty if `totalDistributionCount == 0`.
     */
    function getDistributionDates(uint256 productId) external view returns (uint256[] memory dates) {
        Schema.Product storage product = Storage.ProductsState().products[productId];
        if (product.productId == 0) {
            revert IInvestmentErrors.ProductNotFound();
        }
        uint256 n = product.totalDistributionCount;
        if (n == 0) {
            return new uint256[](0);
        }
        dates = new uint256[](n);
        for (uint256 k = 0; k < n; k++) {
            dates[k] = DistributionDateLib.calculateNextDistributionDate(
                product.distributionStartDate, product.distributionInterval, k, product.isMonthEnd
            );
        }
    }

    /**
     * @notice Simulates per-round yield for a single NFT (one row per distribution).
     * @param productId Product identifier
     * @param tokenId NFT token id under the product's NFT contract
     * @return yields `yields.length == totalDistributionCount`. `yields[0]` is the 1st distribution (index 0 = 1st). Empty if `totalDistributionCount == 0`.
     * @dev Uses the same base period yield as `DistributeYield` (no aggregate tolerance); individual share via `calculateIndividualPeriodYield`.
     */
    function simulateIndividualPeriodYield(uint256 productId, uint256 tokenId)
        external
        view
        returns (uint256[] memory yields)
    {
        return _simulateIndividualPeriodYields(productId, tokenId);
    }

    /**
     * @notice Sum of simulated per-round yields for a single NFT across all distributions.
     * @param productId Product identifier
     * @param tokenId NFT token id under the product's NFT contract
     * @return totalYield Same as the sum of all elements returned by `simulateIndividualPeriodYield(productId, tokenId)` for the same inputs.
     */
    function simulateIndividualTotalYield(uint256 productId, uint256 tokenId)
        external
        view
        returns (uint256 totalYield)
    {
        uint256[] memory yields = _simulateIndividualPeriodYields(productId, tokenId);
        for (uint256 i = 0; i < yields.length; i++) {
            totalYield += yields[i];
        }
    }

    function _simulateIndividualPeriodYields(uint256 productId, uint256 tokenId)
        private
        view
        returns (uint256[] memory yields)
    {
        Schema.Product storage product = Storage.ProductsState().products[productId];
        if (product.productId == 0) {
            revert IInvestmentErrors.ProductNotFound();
        }
        IInvestmentNFT nft = IInvestmentNFT(product.nftContract);
        uint256 investmentAmount = nft.getInvestmentAmount(tokenId);
        uint256 n = product.totalDistributionCount;
        if (n == 0) {
            return new uint256[](0);
        }
        yields = new uint256[](n);
        uint256 raised = product.raisedAmount;
        uint256 expY = product.expectedYield;

        uint256 firstPeriod = DistributionDateLib.calculateFirstDistributionPeriod(
            product.distributionStartDate, product.operationStartDate
        );
        uint256 py0 = CalculateYieldLib.calculatePeriodYield(raised, expY, firstPeriod);
        yields[0] = CalculateYieldLib.calculateIndividualPeriodYield(py0, investmentAmount, raised);

        for (uint256 i = 1; i < n; i++) {
            uint256 period = DistributionDateLib.calculateDistributionPeriod(
                product.distributionStartDate, product.distributionInterval, i, product.isMonthEnd
            );
            uint256 py = CalculateYieldLib.calculatePeriodYield(raised, expY, period);
            yields[i] = CalculateYieldLib.calculateIndividualPeriodYield(py, investmentAmount, raised);
        }
    }

    /**
     * @notice Returns escrowed yield for a token and distribution round
     */
    function getUnclaimedYield(uint256 productId, uint256 tokenId, uint256 distributionIndex)
        external
        view
        returns (uint256 amount)
    {
        return Storage.EscrowState().unclaimedYield[productId][tokenId][distributionIndex];
    }

    /**
     * @notice Returns escrowed principal for a token
     */
    function getUnclaimedPrincipal(uint256 productId, uint256 tokenId) external view returns (uint256 amount) {
        return Storage.EscrowState().unclaimedPrincipal[productId][tokenId];
    }

    /**
     * @notice Returns all claimable yield slots for a token, including in-progress distribution rounds (best-effort)
     * @dev Iterates up to min(distributedCount + 1, totalDistributionCount) so that escrow entries
     *      written during a multi-batch round are visible before the round completes.
     *      Callers should treat the highest index as best-effort when distributedTokenId != 0.
     */
    function getClaimableYieldSlots(uint256 productId, uint256 tokenId)
        external
        view
        returns (Schema.ClaimableYieldSlot[] memory slots)
    {
        Schema.Product storage product = Storage.ProductsState().products[productId];
        if (product.productId == 0) {
            revert IInvestmentErrors.ProductNotFound();
        }

        uint256 maxIndex = product.distributedCount + 1;
        if (maxIndex > product.totalDistributionCount) {
            maxIndex = product.totalDistributionCount;
        }
        uint256 count;
        Schema.$EscrowState storage escrow = Storage.EscrowState();
        for (uint256 i = 1; i <= maxIndex; i++) {
            if (escrow.unclaimedYield[productId][tokenId][i] > 0) {
                count++;
            }
        }

        slots = new Schema.ClaimableYieldSlot[](count);
        uint256 j;
        for (uint256 i = 1; i <= maxIndex; i++) {
            uint256 amount = escrow.unclaimedYield[productId][tokenId][i];
            if (amount > 0) {
                slots[j] = Schema.ClaimableYieldSlot({distributionIndex: i, amount: amount});
                j++;
            }
        }
    }

    /**
     * @notice Returns claimable balances and whether the account is the current NFT owner
     */
    function getClaimableForToken(uint256 productId, uint256 tokenId, address account)
        external
        view
        returns (Schema.TokenClaimableStatus memory status)
    {
        Schema.Product storage product = Storage.ProductsState().products[productId];
        if (product.productId == 0) {
            revert IInvestmentErrors.ProductNotFound();
        }

        status.unclaimedPrincipal = Storage.EscrowState().unclaimedPrincipal[productId][tokenId];
        status.yieldSlots = this.getClaimableYieldSlots(productId, tokenId);

        if (IInvestmentNFT(product.nftContract).getInvestmentAmount(tokenId) == 0) {
            status.isOwner = false;
            return status;
        }

        try IERC721(product.nftContract).ownerOf(tokenId) returns (address owner) {
            status.isOwner = owner == account;
        } catch {
            status.isOwner = false;
        }
    }
}

// Testing
import {MCTest} from "@mc-devkit/Flattened.sol";
import {InvestmentNFT} from "bundle/periphery/InvestmentNFT.sol";
import {DistributionDateLib} from "bundle/investment/utils/DistributionDateLib.sol";
import {MockInvestmentERC1155} from "test/investment/mocks/MockInvestmentERC1155.sol";

contract GetterTest is MCTest {
    address owner;
    address investmentContract; // Address of the investment contract (can be deleted if unused)

    function setUp() public {
        // Create test addresses
        owner = makeAddr("owner");

        Getter getterImpl = new Getter();

        // Link the function selectors of the Getter contract with the addresses (following the pattern of DepositTest)
        _use(Getter.getProduct.selector, address(getterImpl));
        _use(Getter.getAllProducts.selector, address(getterImpl));
        _use(Getter.getActiveProducts.selector, address(getterImpl));
        _use(Getter.getAdminList.selector, address(getterImpl));
        _use(Getter.getAllowedByTierAddress.selector, address(getterImpl));
        _use(Getter.getAllowedByTierId.selector, address(getterImpl));

        // Setup data
        vm.warp(1733995552);
    }

    /// @notice Normal test for getProduct
    function testGetProduct() public {
        uint256 productId = 1;

        // Prepare a test Product with new structure
        Schema.Product memory product = Schema.Product({
            productId: productId,
            nftContract: address(0x123),
            offeringAmount: 10000,
            minInvestment: 100,
            offeringEndDate: block.timestamp + 20000, // New field: offeringEndDate
            raisedAmount: 5000,
            productPool: 2000, // Renamed field: productPool
            maturityDate: block.timestamp + 10000, // Future date
            expectedYield: 1500, // New field: expectedYield
            operationStartDate: block.timestamp, // New field: operationStartDate
            distributionStartDate: block.timestamp, // Start from now
            totalDistributionCount: 5,
            distributionInterval: 3,
            distributedCount: 2,
            distributedYieldPerCount: 0, // New field: distributedYieldPerCount
            distributedTokenId: 10,
            totalReturnedAmount: 0,
            maturedTokenId: 0,
            requiredTier: 0,
            isMaturity: false,
            isInsufficientBalance: false,
            isMonthEnd: false
        });

        // Set getProduct into storage
        Storage.ProductsState().products[productId] = product;

        // Call the Getter contract's getProduct function
        Schema.Product memory returnedProduct = IInvestment(target).getProduct(productId);

        // Assertions to match the updated structure
        assertEq(returnedProduct.productId, product.productId, "Product ID mismatch");
        assertEq(returnedProduct.nftContract, product.nftContract, "NFT Contract mismatch");
        assertEq(returnedProduct.offeringAmount, product.offeringAmount, "Offering Amount mismatch");
        assertEq(returnedProduct.minInvestment, product.minInvestment, "Min Investment mismatch");
        assertEq(returnedProduct.offeringEndDate, product.offeringEndDate, "Offering End Date mismatch");
        assertEq(returnedProduct.raisedAmount, product.raisedAmount, "Raised Amount mismatch");
        assertEq(returnedProduct.productPool, product.productPool, "Product Pool mismatch");
        assertEq(returnedProduct.maturityDate, product.maturityDate, "Maturity Date mismatch");
        assertEq(returnedProduct.expectedYield, product.expectedYield, "Expected Yield mismatch");
        assertEq(returnedProduct.operationStartDate, product.operationStartDate, "Operation Start Date mismatch");
        assertEq(
            returnedProduct.distributionStartDate, product.distributionStartDate, "Distribution Start Date mismatch"
        );
        assertEq(
            returnedProduct.totalDistributionCount, product.totalDistributionCount, "Total Distribution Count mismatch"
        );
        assertEq(returnedProduct.distributionInterval, product.distributionInterval, "Distribution Interval mismatch");
        assertEq(returnedProduct.distributedCount, product.distributedCount, "Distributed Count mismatch");
        assertEq(
            returnedProduct.distributedYieldPerCount,
            product.distributedYieldPerCount,
            "Total Distributed Yield mismatch"
        );
        assertEq(returnedProduct.distributedTokenId, product.distributedTokenId, "Distributed Token ID mismatch");
        assertEq(returnedProduct.totalReturnedAmount, product.totalReturnedAmount, "Total Returned Amount mismatch");
        assertEq(returnedProduct.maturedTokenId, product.maturedTokenId, "Matured Token ID mismatch");
        assertEq(returnedProduct.requiredTier, product.requiredTier, "Required tier mismatch");
        assertEq(returnedProduct.isMaturity, product.isMaturity, "Is Maturity mismatch");
        assertEq(
            returnedProduct.isInsufficientBalance, product.isInsufficientBalance, "Is Insufficient Balance mismatch"
        );
    }

    /// @notice Normal test for getAllProducts
    function testGetAllProducts() public {
        Schema.Product[2] memory products;

        products[0] = Schema.Product({
            productId: 1,
            nftContract: address(0x111),
            offeringAmount: 5000,
            minInvestment: 50,
            offeringEndDate: block.timestamp + 10000, // New field: offeringEndDate
            raisedAmount: 2500,
            productPool: 1000, // Renamed field: productPool
            maturityDate: block.timestamp + 5000,
            expectedYield: 1200, // New field: expectedYield
            operationStartDate: block.timestamp - 1000, // New field: operationStartDate
            distributionStartDate: block.timestamp - 1000,
            totalDistributionCount: 5,
            distributionInterval: 1000,
            distributedCount: 1,
            distributedYieldPerCount: 0, // New field: distributedYieldPerCount
            distributedTokenId: 5,
            totalReturnedAmount: 0,
            maturedTokenId: 0,
            requiredTier: 0,
            isMaturity: false,
            isInsufficientBalance: false,
            isMonthEnd: false
        });

        products[1] = Schema.Product({
            productId: 2,
            nftContract: address(0x222),
            offeringAmount: 8000,
            minInvestment: 200,
            offeringEndDate: block.timestamp + 15000, // New field: offeringEndDate
            raisedAmount: 8000,
            productPool: 4000, // Renamed field: productPool
            maturityDate: block.timestamp - 1, // Already matured
            expectedYield: 1800, // New field: expectedYield
            operationStartDate: block.timestamp - 2000, // New field: operationStartDate
            distributionStartDate: block.timestamp - 2000,
            totalDistributionCount: 5,
            distributionInterval: 1000,
            distributedCount: 5,
            distributedYieldPerCount: 0, // New field: distributedYieldPerCount
            distributedTokenId: 10,
            totalReturnedAmount: 8000,
            maturedTokenId: 1,
            requiredTier: 0,
            isMaturity: true,
            isInsufficientBalance: false,
            isMonthEnd: false
        });

        // Set getAllProducts into storage
        Storage.ProductsState().products[1] = products[0];
        Storage.ProductsState().products[2] = products[1];
        // Set productIdKeys (if getAllProducts refers to productIdKeys)
        Storage.ProductsState().productIdKeys.push(1);
        Storage.ProductsState().productIdKeys.push(2);

        // Call the Getter contract's getAllProducts function
        Schema.Product[] memory returnedProducts = IInvestment(target).getAllProducts();

        // Assertions
        assertEq(returnedProducts.length, 2, "Products length mismatch");

        // First product
        assertEq(returnedProducts[0].productId, products[0].productId, "First product ID mismatch");
        assertEq(returnedProducts[0].nftContract, products[0].nftContract, "First product NFT Contract mismatch");
        assertEq(
            returnedProducts[0].offeringAmount, products[0].offeringAmount, "First product Offering Amount mismatch"
        );
        assertEq(returnedProducts[0].minInvestment, products[0].minInvestment, "First product Min Investment mismatch");
        assertEq(
            returnedProducts[0].offeringEndDate, products[0].offeringEndDate, "First product Offering End Date mismatch"
        );
        assertEq(returnedProducts[0].raisedAmount, products[0].raisedAmount, "First product Raised Amount mismatch");
        assertEq(returnedProducts[0].productPool, products[0].productPool, "First product Product Pool mismatch");
        assertEq(returnedProducts[0].maturityDate, products[0].maturityDate, "First product Maturity Date mismatch");
        assertEq(returnedProducts[0].expectedYield, products[0].expectedYield, "First product Expected Yield mismatch");
        assertEq(
            returnedProducts[0].operationStartDate,
            products[0].operationStartDate,
            "First product Operation Start Date mismatch"
        );
        assertEq(
            returnedProducts[0].distributionStartDate,
            products[0].distributionStartDate,
            "First product Distribution Start Date mismatch"
        );
        assertEq(
            returnedProducts[0].totalDistributionCount,
            products[0].totalDistributionCount,
            "First product Total Distribution Count mismatch"
        );
        assertEq(
            returnedProducts[0].distributionInterval,
            products[0].distributionInterval,
            "First product Distribution Interval mismatch"
        );
        assertEq(
            returnedProducts[0].distributedCount,
            products[0].distributedCount,
            "First product Distributed Count mismatch"
        );
        assertEq(
            returnedProducts[0].distributedYieldPerCount,
            products[0].distributedYieldPerCount,
            "First product Total Distributed Yield mismatch"
        );
        assertEq(
            returnedProducts[0].totalReturnedAmount,
            products[0].totalReturnedAmount,
            "First product Total Returned Amount mismatch"
        );
        assertEq(
            returnedProducts[0].distributedTokenId,
            products[0].distributedTokenId,
            "First product Distributed Token ID mismatch"
        );
        assertEq(
            returnedProducts[0].maturedTokenId, products[0].maturedTokenId, "First product Matured Token ID mismatch"
        );
        assertEq(returnedProducts[0].requiredTier, products[0].requiredTier, "First product Required tier mismatch");
        assertEq(returnedProducts[0].isMaturity, products[0].isMaturity, "First product Is Maturity mismatch");
        assertEq(
            returnedProducts[0].isInsufficientBalance,
            products[0].isInsufficientBalance,
            "First product Is Insufficient Balance mismatch"
        );

        // Second product
        assertEq(returnedProducts[1].productId, products[1].productId, "Second product ID mismatch");
        assertEq(returnedProducts[1].nftContract, products[1].nftContract, "Second product NFT Contract mismatch");
        assertEq(
            returnedProducts[1].offeringAmount, products[1].offeringAmount, "Second product Offering Amount mismatch"
        );
        assertEq(returnedProducts[1].minInvestment, products[1].minInvestment, "Second product Min Investment mismatch");
        assertEq(
            returnedProducts[1].offeringEndDate,
            products[1].offeringEndDate,
            "Second product Offering End Date mismatch"
        );
        assertEq(returnedProducts[1].raisedAmount, products[1].raisedAmount, "Second product Raised Amount mismatch");
        assertEq(returnedProducts[1].productPool, products[1].productPool, "Second product Product Pool mismatch");
        assertEq(returnedProducts[1].maturityDate, products[1].maturityDate, "Second product Maturity Date mismatch");
        assertEq(returnedProducts[1].expectedYield, products[1].expectedYield, "Second product Expected Yield mismatch");
        assertEq(
            returnedProducts[1].operationStartDate,
            products[1].operationStartDate,
            "Second product Operation Start Date mismatch"
        );
        assertEq(
            returnedProducts[1].distributionStartDate,
            products[1].distributionStartDate,
            "Second product Distribution Start Date mismatch"
        );
        assertEq(
            returnedProducts[1].totalDistributionCount,
            products[1].totalDistributionCount,
            "Second product Total Distribution Count mismatch"
        );
        assertEq(
            returnedProducts[1].distributionInterval,
            products[1].distributionInterval,
            "Second product Distribution Interval mismatch"
        );
        assertEq(
            returnedProducts[1].distributedCount,
            products[1].distributedCount,
            "Second product Distributed Count mismatch"
        );
        assertEq(
            returnedProducts[1].distributedYieldPerCount,
            products[1].distributedYieldPerCount,
            "Second product Total Distributed Yield mismatch"
        );
        assertEq(
            returnedProducts[1].distributedTokenId,
            products[1].distributedTokenId,
            "Second product Distributed Token ID mismatch"
        );
        assertEq(
            returnedProducts[1].totalReturnedAmount,
            products[1].totalReturnedAmount,
            "Second product Total Returned Amount mismatch"
        );
        assertEq(
            returnedProducts[1].maturedTokenId, products[1].maturedTokenId, "Second product Matured Token ID mismatch"
        );
        assertEq(returnedProducts[1].requiredTier, products[1].requiredTier, "Second product Required tier mismatch");
        assertEq(returnedProducts[1].isMaturity, products[1].isMaturity, "Second product Is Maturity mismatch");
        assertEq(
            returnedProducts[1].isInsufficientBalance,
            products[1].isInsufficientBalance,
            "Second product Is Insufficient Balance mismatch"
        );
    }

    /// @notice Normal test for getAdminList
    function testGetAdminList() public {
        address[2] memory admins;
        admins[0] = makeAddr("admin1");
        admins[1] = makeAddr("admin2");

        // Set adminList into storage
        Storage.WhiteListsState().admins.push(admins[0]);
        Storage.WhiteListsState().admins.push(admins[1]);

        // Call the Getter contract's getAdminList function
        address[] memory returned = IInvestment(target).getAdminList();

        // Assertions
        assertEq(returned.length, admins.length, "Admin list length mismatch");
        for (uint256 i = 0; i < returned.length; i++) {
            assertEq(returned[i], admins[i], string(abi.encodePacked("Admin ", vm.toString(i), " mismatch")));
        }
    }

    function testGetAllowedByTierId() public {
        uint8 tier = 1;
        MockInvestmentERC1155 token = new MockInvestmentERC1155();
        Storage.TierRegistryState().allowedByTierId[tier][address(token)].push(10);
        Storage.TierRegistryState().allowedByTierId[tier][address(token)].push(77);

        uint256[] memory ids = IInvestment(target).getAllowedByTierId(tier, address(token));
        assertEq(ids.length, 2, "AllowedByTierId length mismatch");
        assertEq(ids[0], 10, "AllowedByTierId[0] mismatch");
        assertEq(ids[1], 77, "AllowedByTierId[1] mismatch");
    }

    function testGetAllowedByTierId_Empty() public view {
        uint256[] memory ids = IInvestment(target).getAllowedByTierId(99, address(0xBEEF));
        assertEq(ids.length, 0, "AllowedByTierId should be empty");
    }

    function testGetAllowedByTierId_TierIsolation() public {
        MockInvestmentERC1155 token1 = new MockInvestmentERC1155();
        MockInvestmentERC1155 token2 = new MockInvestmentERC1155();
        Storage.TierRegistryState().allowedByTierId[1][address(token1)].push(10);
        Storage.TierRegistryState().allowedByTierId[1][address(token1)].push(77);

        uint256[] memory tier1 = IInvestment(target).getAllowedByTierId(1, address(token1));
        uint256[] memory tier2 = IInvestment(target).getAllowedByTierId(2, address(token1));
        uint256[] memory tier1OtherSbt = IInvestment(target).getAllowedByTierId(1, address(token2));
        assertEq(tier1.length, 2, "Tier1 length mismatch");
        assertEq(tier2.length, 0, "Tier2 should remain empty");
        assertEq(tier1OtherSbt.length, 0, "Other SBT under same tier should be empty");
    }

    /// @notice Test for getProduct with a non-existent productId
    function testGetProduct_NonExistentId() public {
        uint256 nonExistentId = 999999;

        vm.expectRevert(abi.encodeWithSelector(IInvestmentErrors.ProductNotFound.selector));
        IInvestment(target).getProduct(nonExistentId);
    }

    /// @notice Test getActiveProducts returns only non-matured products
    function testGetActiveProducts() public {
        Schema.Product memory activeProduct = Schema.Product({
            productId: 1,
            nftContract: address(0x111),
            offeringAmount: 5000,
            minInvestment: 50,
            offeringEndDate: block.timestamp + 10000,
            raisedAmount: 2500,
            productPool: 1000,
            maturityDate: block.timestamp + 5000,
            expectedYield: 1200,
            operationStartDate: block.timestamp - 1000,
            distributionStartDate: block.timestamp - 1000,
            totalDistributionCount: 5,
            distributionInterval: 1000,
            distributedCount: 1,
            distributedYieldPerCount: 0,
            distributedTokenId: 5,
            totalReturnedAmount: 0,
            maturedTokenId: 0,
            requiredTier: 0,
            isMaturity: false,
            isInsufficientBalance: false,
            isMonthEnd: false
        });

        Schema.Product memory maturedProduct = Schema.Product({
            productId: 2,
            nftContract: address(0x222),
            offeringAmount: 8000,
            minInvestment: 200,
            offeringEndDate: block.timestamp + 15000,
            raisedAmount: 8000,
            productPool: 0,
            maturityDate: block.timestamp - 1,
            expectedYield: 1800,
            operationStartDate: block.timestamp - 2000,
            distributionStartDate: block.timestamp - 2000,
            totalDistributionCount: 5,
            distributionInterval: 1000,
            distributedCount: 5,
            distributedYieldPerCount: 0,
            distributedTokenId: 10,
            totalReturnedAmount: 8000,
            maturedTokenId: 1,
            requiredTier: 0,
            isMaturity: true,
            isInsufficientBalance: false,
            isMonthEnd: false
        });

        Storage.ProductsState().products[1] = activeProduct;
        Storage.ProductsState().products[2] = maturedProduct;
        Storage.ProductsState().productIdKeys.push(1);
        Storage.ProductsState().productIdKeys.push(2);
        Storage.ProductsState().activeProductIdKeys.push(1);
        Storage.ProductsState().activeIndex[1] = 1;

        Schema.Product[] memory allProducts = Getter(target).getAllProducts();
        assertEq(allProducts.length, 2, "getAllProducts should return all products");

        Schema.Product[] memory activeProducts = Getter(target).getActiveProducts();
        assertEq(activeProducts.length, 1, "getActiveProducts should return only active products");
        assertEq(activeProducts[0].productId, 1, "Active product ID mismatch");
        assertFalse(activeProducts[0].isMaturity, "Active product should not be matured");
    }

    /// @notice Test getActiveProducts when empty
    function testGetActiveProducts_Empty() public view {
        Schema.Product[] memory activeProducts = Getter(target).getActiveProducts();
        assertEq(activeProducts.length, 0, "Active products should be empty");
    }

    /// @notice Test for getAllProducts when no products exist
    function testGetAllProducts_Empty() public {
        Schema.Product memory products;

        // Call the Getter contract's getAllProducts function
        Schema.Product[] memory returnedProducts = IInvestment(target).getAllProducts();

        // Assertions
        assertEq(returnedProducts.length, 0, "Products should be empty");
    }

    /// @notice Test for getAdminList when the list is empty
    function testGetAdminList_Empty() public {
        // Call the Getter contract's getAdminList function
        address[] memory adminList = IInvestment(target).getAdminList();

        // Assertions
        assertEq(adminList.length, 0, "Admin list should be empty");
    }

    // ===================== Fuzz Test =====================

    /// @notice Fuzz test for getProduct
    function testFuzz_GetProduct(uint256 productId) public {
        vm.assume(productId > 0 && productId < 1000);

        bool productExists = (productId % 2 == 0);
        if (productExists) {
            Schema.Product memory product = Schema.Product({
                productId: productId,
                nftContract: address(0x999),
                offeringAmount: 10000 + (productId * 10),
                minInvestment: 100 + (productId % 50),
                offeringEndDate: block.timestamp + (productId * 1000), // New field: offeringEndDate
                raisedAmount: 5000 + (productId * 5),
                productPool: 2500 + (productId * 2), // Renamed field: productPool
                maturityDate: block.timestamp + (productId * 1000),
                expectedYield: 500 + (productId * 50), // New field: expectedYield
                operationStartDate: block.timestamp - (productId * 100), // New field: operationStartDate
                distributionStartDate: block.timestamp - (productId * 100),
                totalDistributionCount: 5,
                distributionInterval: 1000,
                distributedCount: productId % 5,
                distributedYieldPerCount: 0, // New field: distributedYieldPerCount
                distributedTokenId: productId % 10,
                maturedTokenId: 0,
                totalReturnedAmount: 0,
                requiredTier: 0,
                isMaturity: (productId % 3 == 0),
                isInsufficientBalance: (productId % 3 == 0),
                isMonthEnd: false
            });

            // Set getProduct into storage
            Storage.ProductsState().products[productId] = product;

            // Call Getter contract's getProduct function
            Schema.Product memory returned = IInvestment(target).getProduct(productId);

            // Assertions
            assertEq(returned.productId, product.productId, "ID mismatch in fuzz");
            assertEq(returned.nftContract, product.nftContract, "NFT Contract mismatch in fuzz");
            assertEq(returned.offeringAmount, product.offeringAmount, "Offering Amount mismatch in fuzz");
            assertEq(returned.minInvestment, product.minInvestment, "Min Investment mismatch in fuzz");
            assertEq(returned.offeringEndDate, product.offeringEndDate, "Offering End Date mismatch in fuzz");
            assertEq(returned.raisedAmount, product.raisedAmount, "Raised Amount mismatch in fuzz");
            assertEq(returned.productPool, product.productPool, "Product Pool mismatch in fuzz");
            assertEq(returned.maturityDate, product.maturityDate, "Maturity Date mismatch in fuzz");
            assertEq(returned.expectedYield, product.expectedYield, "Expected Yield mismatch in fuzz");
            assertEq(returned.operationStartDate, product.operationStartDate, "Operation Start Date mismatch in fuzz");
            assertEq(
                returned.distributionStartDate,
                product.distributionStartDate,
                "Distribution Start Date mismatch in fuzz"
            );
            assertEq(
                returned.totalDistributionCount,
                product.totalDistributionCount,
                "Total Distribution Count mismatch in fuzz"
            );
            assertEq(
                returned.distributionInterval, product.distributionInterval, "Distribution Interval mismatch in fuzz"
            );
            assertEq(returned.distributedCount, product.distributedCount, "Distributed Count mismatch in fuzz");
            assertEq(
                returned.distributedYieldPerCount,
                product.distributedYieldPerCount,
                "Total Distributed Yield mismatch in fuzz"
            );
            assertEq(returned.distributedTokenId, product.distributedTokenId, "Distributed Token ID mismatch in fuzz");
            assertEq(
                returned.totalReturnedAmount, product.totalReturnedAmount, "Total Returned Amount mismatch in fuzz"
            );
            assertEq(returned.maturedTokenId, product.maturedTokenId, "Matured Token ID mismatch in fuzz");
            assertEq(returned.requiredTier, product.requiredTier, "Required tier mismatch in fuzz");
            assertEq(returned.isMaturity, product.isMaturity, "Is Maturity mismatch in fuzz");
            assertEq(
                returned.isInsufficientBalance,
                product.isInsufficientBalance,
                "Is Insufficient Balance mismatch in fuzz"
            );
        } else {
            // Call Getter contract's getProduct function and expect revert
            vm.expectRevert(abi.encodeWithSelector(IInvestmentErrors.ProductNotFound.selector));
            IInvestment(target).getProduct(productId);
        }
    }

    /// @notice Fuzz test for getAllProducts
    function testFuzz_GetAllProducts(uint8 count) public {
        vm.assume(count < 10);

        Schema.Product[] memory products = new Schema.Product[](count);
        for (uint256 i = 0; i < count; i++) {
            products[i] = Schema.Product({
                productId: i + 1,
                nftContract: address(uint160(0x1111 + i)),
                offeringAmount: 5000 + (i * 100),
                minInvestment: 100 + (i * 10),
                offeringEndDate: block.timestamp + (i * 1000), // New field: offeringEndDate
                raisedAmount: 2500 + (i * 50),
                productPool: 1000 + (i * 20), // Renamed field: productPool
                maturityDate: block.timestamp + (1000 * i),
                expectedYield: 1000 + (i * 100), // New field: expectedYield
                operationStartDate: block.timestamp - (100 * i), // New field: operationStartDate
                distributionStartDate: block.timestamp - (100 * i),
                totalDistributionCount: 5,
                distributionInterval: 1000,
                distributedCount: i,
                distributedYieldPerCount: 0, // New field: distributedYieldPerCount
                distributedTokenId: i * 2,
                totalReturnedAmount: 0,
                maturedTokenId: (i == count - 1 ? 1 : 0),
                requiredTier: 0,
                isMaturity: (i == count - 1), // Last product is matured
                isInsufficientBalance: (i == count - 1),
                isMonthEnd: false
            });
        }

        // Set getAllProducts into storage
        for (uint256 i = 0; i < count; i++) {
            Storage.ProductsState().products[i + 1] = products[i];
            // Set productIdKeys (if getAllProducts refers to productIdKeys)
            Storage.ProductsState().productIdKeys.push(i + 1);
        }

        // Call Getter contract's getAllProducts function
        Schema.Product[] memory returned = IInvestment(target).getAllProducts();

        // Assertions
        assertEq(returned.length, count, "Length mismatch in fuzz getAllProducts");
        for (uint256 i = 0; i < count; i++) {
            assertEq(
                returned[i].productId,
                products[i].productId,
                string(abi.encodePacked("Product ID mismatch at index ", vm.toString(i)))
            );
            assertEq(
                returned[i].nftContract,
                products[i].nftContract,
                string(abi.encodePacked("NFT Contract mismatch at index ", vm.toString(i)))
            );
            assertEq(
                returned[i].offeringAmount,
                products[i].offeringAmount,
                string(abi.encodePacked("Offering Amount mismatch at index ", vm.toString(i)))
            );
            assertEq(
                returned[i].minInvestment,
                products[i].minInvestment,
                string(abi.encodePacked("Min Investment mismatch at index ", vm.toString(i)))
            );
            assertEq(
                returned[i].offeringEndDate,
                products[i].offeringEndDate,
                string(abi.encodePacked("Offering End Date mismatch at index ", vm.toString(i)))
            );
            assertEq(
                returned[i].raisedAmount,
                products[i].raisedAmount,
                string(abi.encodePacked("Raised Amount mismatch at index ", vm.toString(i)))
            );
            assertEq(
                returned[i].productPool,
                products[i].productPool,
                string(abi.encodePacked("Product Pool mismatch at index ", vm.toString(i)))
            );
            assertEq(
                returned[i].expectedYield,
                products[i].expectedYield,
                string(abi.encodePacked("Expected Yield mismatch at index ", vm.toString(i)))
            );
            assertEq(
                returned[i].operationStartDate,
                products[i].operationStartDate,
                string(abi.encodePacked("Operation Start Date mismatch at index ", vm.toString(i)))
            );
            assertEq(
                returned[i].distributionStartDate,
                products[i].distributionStartDate,
                string(abi.encodePacked("Distribution Start Date mismatch at index ", vm.toString(i)))
            );
            assertEq(
                returned[i].totalDistributionCount,
                products[i].totalDistributionCount,
                string(abi.encodePacked("Total Distribution Count mismatch at index ", vm.toString(i)))
            );
            assertEq(
                returned[i].distributionInterval,
                products[i].distributionInterval,
                string(abi.encodePacked("Distribution Interval mismatch at index ", vm.toString(i)))
            );
            assertEq(
                returned[i].distributedCount,
                products[i].distributedCount,
                string(abi.encodePacked("Distributed Count mismatch at index ", vm.toString(i)))
            );
            assertEq(
                returned[i].distributedYieldPerCount,
                products[i].distributedYieldPerCount,
                string(abi.encodePacked("Total Distributed Yield mismatch at index ", vm.toString(i)))
            );
            assertEq(
                returned[i].distributedTokenId,
                products[i].distributedTokenId,
                string(abi.encodePacked("Distributed Token ID mismatch at index ", vm.toString(i)))
            );
            assertEq(
                returned[i].totalReturnedAmount,
                products[i].totalReturnedAmount,
                string(abi.encodePacked("Total Returned Amount mismatch at index ", vm.toString(i)))
            );
            assertEq(
                returned[i].maturedTokenId,
                products[i].maturedTokenId,
                string(abi.encodePacked("Matured Token ID mismatch at index ", vm.toString(i)))
            );
            assertEq(
                returned[i].requiredTier,
                products[i].requiredTier,
                string(abi.encodePacked("Required tier mismatch at index ", vm.toString(i)))
            );
            assertEq(
                returned[i].isMaturity,
                products[i].isMaturity,
                string(abi.encodePacked("Is Maturity mismatch at index ", vm.toString(i)))
            );
            assertEq(
                returned[i].isInsufficientBalance,
                products[i].isInsufficientBalance,
                string(abi.encodePacked("Is Insufficient Balance mismatch at index ", vm.toString(i)))
            );
        }
    }

    /// @notice Fuzz test for getAdminList
    function testFuzz_GetAdminList(uint8 count) public {
        vm.assume(count < 20);
        address[] memory admins = new address[](count);
        for (uint256 i = 0; i < count; i++) {
            admins[i] = makeAddr(string(abi.encodePacked("admin", vm.toString(i))));
        }
        // Set adminList into storage
        Storage.WhiteListsState().admins = admins;

        // Call Getter contract's getAdminList function
        address[] memory returned = IInvestment(target).getAdminList();

        // Assertions
        assertEq(returned.length, count, "Admin list length mismatch in fuzz");
        for (uint256 i = 0; i < count; i++) {
            assertEq(returned[i], admins[i], string(abi.encodePacked("Admin ", vm.toString(i), " mismatch in fuzz")));
        }
    }

    receive() external payable {}
}

// Simulate Testing
contract GetterSimulateYieldTest is MCTest {
    IInvestmentNFT nft;

    uint256 productId = 1;
    uint256 investorCount = 100;
    address investor = address(0x1);

    function setUp() public {
        // Setup NFT
        nft = new InvestmentNFT("NFT", "NFT", productId, "", address(0));

        // Setup Getter
        Getter getter = new Getter();
        _use(Getter.simulatePeriodYield.selector, address(getter));
        _use(Getter.simulateTotalYield.selector, address(getter));

        // // Register simulate yield test product
        Schema.Product memory product = Schema.Product({
            productId: productId,
            nftContract: address(nft),
            offeringAmount: 1_000_000_000_000, // 1_000_000USDT
            minInvestment: 100_000_000, // 100USDT
            offeringEndDate: block.timestamp,
            raisedAmount: 1_000_000_000_000,
            productPool: 0,
            maturityDate: block.timestamp + 365 days,
            expectedYield: 500, // 5%
            operationStartDate: block.timestamp + 10 days,
            distributionStartDate: block.timestamp + 20 days,
            totalDistributionCount: 4,
            distributionInterval: 3, // 3 months
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
        Storage.ProductsState().products[productId] = product;

        // Fixed block time
        vm.warp(1000000000);

        // Setup NFTs for investors
        uint256 investmentAmountPerUser = product.offeringAmount / investorCount;
        for (uint256 i = 0; i < investorCount; i++) {
            nft.mint(address(uint160(uint160(investor) + i)), investmentAmountPerUser);
        }
    }

    /// @dev Reference expected simulated yield per distribution from the first through totalDistributionCount (index 0 = first). Zero-length when totalDistributionCount is 0.
    function _referenceSimulatedYieldsAllDistributions(Schema.Product memory product, uint256 nftCount)
        internal
        pure
        returns (uint256[] memory yields)
    {
        uint256 n = product.totalDistributionCount;
        yields = new uint256[](n);
        if (n == 0) return yields;

        uint256 tolerance = CalculateYieldLib.calculatePeriodTolerance(nftCount);
        uint256 firstPeriod = DistributionDateLib.calculateFirstDistributionPeriod(
            product.distributionStartDate, product.operationStartDate
        );
        yields[0] = CalculateYieldLib.calculatePeriodYield(product.raisedAmount, product.expectedYield, firstPeriod)
            + tolerance;

        for (uint256 i = 1; i < n; i++) {
            uint256 period = DistributionDateLib.calculateDistributionPeriod(
                product.distributionStartDate, product.distributionInterval, i, product.isMonthEnd
            );
            yields[i] =
                CalculateYieldLib.calculatePeriodYield(product.raisedAmount, product.expectedYield, period) + tolerance;
        }
    }

    /// @notice Calls simulatePeriodYield once and asserts every distribution from setUp (four rounds).
    function test_simulatePeriodYield_fourDistributions() public view {
        Schema.Product memory product = Storage.ProductsState().products[productId];
        assertEq(product.totalDistributionCount, 4, "setUp: four distributions");

        uint256 nftCount = uint256(nft.tokenIdCounter());
        uint256[] memory expected = _referenceSimulatedYieldsAllDistributions(product, nftCount);

        uint256[] memory actual = Getter(target).simulatePeriodYield(productId);

        assertEq(actual.length, expected.length, "length vs reference");
        for (uint256 k = 0; k < expected.length; k++) {
            assertEq(actual[k], expected[k], "per-distribution yield mismatch");
        }
    }

    /// @notice Test simulatePeriodYield returns empty array when totalDistributionCount is 0
    function test_simulatePeriodYield_returnsEmpty_whenTotalDistributionCountIsZero() public {
        Schema.Product storage product = Storage.ProductsState().products[productId];
        product.totalDistributionCount = 0;

        uint256[] memory actual = Getter(target).simulatePeriodYield(productId);

        assertEq(actual.length, 0, "should return empty array when totalDistributionCount is 0");
    }

    function test_simulatePeriodYield_returnsOnlyFirstDistribution_whenTotalDistributionCountIsOne() public {
        Schema.Product storage product = Storage.ProductsState().products[productId];
        product.totalDistributionCount = 1;

        uint256 nftCount = uint256(nft.tokenIdCounter());
        uint256 tolerance = CalculateYieldLib.calculatePeriodTolerance(nftCount);

        uint256 firstPeriod = DistributionDateLib.calculateFirstDistributionPeriod(
            product.distributionStartDate, product.operationStartDate
        );
        uint256 expected = CalculateYieldLib.calculatePeriodYield(
            product.raisedAmount, product.expectedYield, firstPeriod
        ) + tolerance;

        uint256[] memory actual = Getter(target).simulatePeriodYield(productId);

        assertEq(actual.length, 1, "should return exactly one element when totalDistributionCount is 1");
        assertEq(actual[0], expected, "first element should be simulated yield for the 1st distribution");
    }

    /// @notice Test simulateTotalYield
    function test_simulateTotalYield_success() public view {
        Schema.Product memory product = Storage.ProductsState().products[productId];
        uint256 firstPeriod = DistributionDateLib.calculateFirstDistributionPeriod(
            product.distributionStartDate, product.operationStartDate
        );
        uint256 firstPeriodYield =
            CalculateYieldLib.calculatePeriodYield(product.raisedAmount, product.expectedYield, firstPeriod);

        uint256 subsequentYield = 0;
        for (uint256 i = 1; i < product.totalDistributionCount; i++) {
            uint256 period = DistributionDateLib.calculateDistributionPeriod(
                product.distributionStartDate, product.distributionInterval, i, product.isMonthEnd
            );
            subsequentYield += CalculateYieldLib.calculatePeriodYield(
                product.raisedAmount, product.expectedYield, period
            );
        }

        uint256 totalYield = firstPeriodYield + subsequentYield;
        uint256 nftCount = uint256(nft.tokenIdCounter());
        uint256 tolerance = CalculateYieldLib.calculateTotalTolerance(nftCount, product.totalDistributionCount);
        uint256 expected = totalYield + tolerance;

        uint256 actual = Getter(target).simulateTotalYield(productId);

        assertEq(actual, expected, "simulateTotalYield mismatch");
    }

    receive() external payable {}
}

/// @notice Tests for `getDistributionDates`, `simulateIndividualPeriodYield`, and `simulateIndividualTotalYield`.
contract GetterDistributionDatesAndIndividualTest is MCTest {
    InvestmentNFT internal nft;

    uint256 internal constant PRODUCT_ID = 1;
    /// @dev First minted token goes to this address when i=0 in setUp loop
    address internal baseHolder = address(0x1);

    function setUp() public {
        nft = new InvestmentNFT("NFT", "NFT", PRODUCT_ID, "", address(0));

        Getter getter = new Getter();
        _use(Getter.getDistributionDates.selector, address(getter));
        _use(Getter.simulateIndividualPeriodYield.selector, address(getter));
        _use(Getter.simulateIndividualTotalYield.selector, address(getter));

        Schema.Product memory product = Schema.Product({
            productId: PRODUCT_ID,
            nftContract: address(nft),
            offeringAmount: 1_000_000_000_000,
            minInvestment: 100_000_000,
            offeringEndDate: block.timestamp,
            raisedAmount: 1_000_000_000_000,
            productPool: 0,
            maturityDate: block.timestamp + 365 days,
            expectedYield: 500,
            operationStartDate: block.timestamp + 10 days,
            distributionStartDate: block.timestamp + 20 days,
            totalDistributionCount: 4,
            distributionInterval: 3,
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

        vm.warp(1_000_000_000);

        uint256 investorCount = 100;
        uint256 per = product.offeringAmount / investorCount;
        for (uint256 i = 0; i < investorCount; i++) {
            nft.mint(address(uint160(uint160(baseHolder) + i)), per);
        }
    }

    function _referenceDistributionDates(Schema.Product memory product) internal pure returns (uint256[] memory dates) {
        uint256 n = product.totalDistributionCount;
        dates = new uint256[](n);
        for (uint256 k = 0; k < n; k++) {
            dates[k] = DistributionDateLib.calculateNextDistributionDate(
                product.distributionStartDate, product.distributionInterval, k, product.isMonthEnd
            );
        }
    }

    function _referenceIndividualYields(Schema.Product memory product, uint256 investmentAmount)
        internal
        pure
        returns (uint256[] memory yields)
    {
        uint256 n = product.totalDistributionCount;
        yields = new uint256[](n);
        if (n == 0) return yields;

        uint256 raised = product.raisedAmount;
        uint256 expY = product.expectedYield;

        uint256 firstPeriod = DistributionDateLib.calculateFirstDistributionPeriod(
            product.distributionStartDate, product.operationStartDate
        );
        uint256 py0 = CalculateYieldLib.calculatePeriodYield(raised, expY, firstPeriod);
        yields[0] = CalculateYieldLib.calculateIndividualPeriodYield(py0, investmentAmount, raised);

        for (uint256 i = 1; i < n; i++) {
            uint256 period = DistributionDateLib.calculateDistributionPeriod(
                product.distributionStartDate, product.distributionInterval, i, product.isMonthEnd
            );
            uint256 py = CalculateYieldLib.calculatePeriodYield(raised, expY, period);
            yields[i] = CalculateYieldLib.calculateIndividualPeriodYield(py, investmentAmount, raised);
        }
    }

    function test_getDistributionDates_matchesLib_forFourRounds() public view {
        Schema.Product memory product = Storage.ProductsState().products[PRODUCT_ID];
        uint256[] memory expected = _referenceDistributionDates(product);
        uint256[] memory actual = Getter(target).getDistributionDates(PRODUCT_ID);

        assertEq(actual.length, expected.length, "length");
        assertEq(actual.length, 4, "four rounds");
        for (uint256 k = 0; k < expected.length; k++) {
            assertEq(actual[k], expected[k], "date mismatch");
        }
    }

    function test_getDistributionDates_empty_whenTotalDistributionCountZero() public {
        Schema.Product storage product = Storage.ProductsState().products[PRODUCT_ID];
        product.totalDistributionCount = 0;

        uint256[] memory actual = Getter(target).getDistributionDates(PRODUCT_ID);
        assertEq(actual.length, 0);
    }

    function test_getDistributionDates_reverts_whenProductMissing() public {
        vm.expectRevert(IInvestmentErrors.ProductNotFound.selector);
        Getter(target).getDistributionDates(999);
    }

    function test_simulateIndividualPeriodYield_matchesReference_token1() public view {
        Schema.Product memory product = Storage.ProductsState().products[PRODUCT_ID];
        uint256 tokenId = 1;
        uint256 invAmt = nft.getInvestmentAmount(tokenId);
        uint256[] memory expected = _referenceIndividualYields(product, invAmt);
        uint256[] memory actual = Getter(target).simulateIndividualPeriodYield(PRODUCT_ID, tokenId);

        assertEq(actual.length, product.totalDistributionCount, "length == totalDistributionCount");
        assertEq(actual.length, expected.length);
        for (uint256 i = 0; i < expected.length; i++) {
            assertEq(actual[i], expected[i], "yield element");
        }
    }

    function test_simulateIndividualTotalYield_equalsSumOfPeriodYields() public view {
        uint256 tokenId = 1;
        uint256[] memory periods = Getter(target).simulateIndividualPeriodYield(PRODUCT_ID, tokenId);
        uint256 sum;
        for (uint256 i = 0; i < periods.length; i++) {
            sum += periods[i];
        }
        uint256 total = Getter(target).simulateIndividualTotalYield(PRODUCT_ID, tokenId);
        assertEq(total, sum);
    }

    function test_simulateIndividual_emptyArrays_whenTotalDistributionCountZero() public {
        Schema.Product storage product = Storage.ProductsState().products[PRODUCT_ID];
        product.totalDistributionCount = 0;

        uint256[] memory yields = Getter(target).simulateIndividualPeriodYield(PRODUCT_ID, 1);
        assertEq(yields.length, 0);

        uint256 total = Getter(target).simulateIndividualTotalYield(PRODUCT_ID, 1);
        assertEq(total, 0);
    }

    function test_simulateIndividualPeriodYield_openData_notTokenOwnerAlsoReadable() public {
        address unrelatedCaller = address(0xdead);
        vm.prank(unrelatedCaller);
        uint256[] memory yields = Getter(target).simulateIndividualPeriodYield(PRODUCT_ID, 1);
        assertEq(yields.length, 4);
    }

    function test_simulateIndividual_reverts_ProductNotFound() public {
        vm.expectRevert(IInvestmentErrors.ProductNotFound.selector);
        Getter(target).simulateIndividualPeriodYield(999, 1);
    }

    /// @notice When `totalDistributionCount` is 1, individual simulation returns a single element.
    function test_simulateIndividualPeriodYield_returnsOnlyFirstDistribution_whenTotalDistributionCountIsOne() public {
        Schema.Product storage product = Storage.ProductsState().products[PRODUCT_ID];
        product.totalDistributionCount = 1;

        uint256 tokenId = 1;
        uint256 investmentAmount = nft.getInvestmentAmount(tokenId);
        Schema.Product memory snapshot = Storage.ProductsState().products[PRODUCT_ID];
        uint256[] memory expected = _referenceIndividualYields(snapshot, investmentAmount);

        uint256[] memory actual = Getter(target).simulateIndividualPeriodYield(PRODUCT_ID, tokenId);

        assertEq(actual.length, 1, "should return exactly one element when totalDistributionCount is 1");
        assertEq(actual.length, expected.length, "length mismatch");
        assertEq(actual[0], expected[0], "first distribution yield mismatch");
    }

    /// @notice When `totalDistributionCount` is 1, total yield equals `periods[0]`.
    function test_simulateIndividualTotalYield_equalsFirstDistribution_whenTotalDistributionCountIsOne() public {
        Schema.Product storage product = Storage.ProductsState().products[PRODUCT_ID];
        product.totalDistributionCount = 1;

        uint256 tokenId = 1;
        uint256 investmentAmount = nft.getInvestmentAmount(tokenId);
        Schema.Product memory snapshot = Storage.ProductsState().products[PRODUCT_ID];
        uint256[] memory expectedPeriods = _referenceIndividualYields(snapshot, investmentAmount);

        uint256 actual = Getter(target).simulateIndividualTotalYield(PRODUCT_ID, tokenId);

        assertEq(expectedPeriods.length, 1, "reference should contain exactly one element");
        assertEq(actual, expectedPeriods[0], "total yield should equal first distribution yield");
    }

    /// @notice `simulateIndividualTotalYield` reverts with `ProductNotFound` when the product does not exist.
    function test_simulateIndividualTotalYield_reverts_whenProductMissing() public {
        vm.expectRevert(IInvestmentErrors.ProductNotFound.selector);
        Getter(target).simulateIndividualTotalYield(999, 1);
    }

    receive() external payable {}
}
