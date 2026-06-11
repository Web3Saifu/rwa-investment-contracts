// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {MCTest} from "@mc-devkit/Flattened.sol";
import {Storage} from "bundle/investment/storage/Storage.sol";
import {Schema} from "bundle/investment/storage/Schema.sol";
import {RegisterProduct} from "bundle/investment/functions/onlyWhiteLists/RegisterProduct.sol";
import {IInvestmentErrors} from "bundle/investment/interfaces/IInvestmentErrors.sol";
import {DateTime} from "lib/chainlink-evm/contracts/src/v0.8/vendor/DateTime.sol";

/**
 * @title F-2026-16949 PoC Verification
 * @notice Verifies that registerProduct rejects products whose distribution
 *         schedule extends beyond maturityDate, preventing unexpected principal locking.
 */
contract F2026_16949_PoCVerification is MCTest {
    uint256 constant OFFERING_AMOUNT = 1_000_000_000_000;
    uint256 constant MIN_INVESTMENT = 250_000_000;
    uint256 constant OFFERING_END_DATE = 1737763200; // 2025-01-25 00:00:00 UTC
    uint256 constant OPERATION_STARTDATE = 1738368000; // 2025-02-01 00:00:00 UTC
    uint256 constant EXPECTED_YIELD = 500;
    string constant BASE_TOKEN_URI = "https://example.com/metadata/";

    address admin = address(0x1);

    function setUp() public {
        _use(RegisterProduct.registerProduct.selector, address(new RegisterProduct()));
        Storage.WhiteListsState().admins.push(admin);
    }

    /// @notice Audit scenario: distribution schedule overshoots maturityDate → revert
    ///         distributionStartDate=2025-06-01, interval=3mo, count=5
    ///         lastDistributionDate = 2025-06-01 + 3*4 = 2026-06-01
    ///         maturityDate = 2025-12-01 → 6 months overshoot → must revert
    function test_revert_whenDistributionScheduleExceedsMaturityDate() public {
        uint256 distributionStartDate = DateTime.toTimestamp(2025, 6, 1, 0, 0, 0);
        uint256 maturityDate = DateTime.toTimestamp(2025, 12, 1, 0, 0, 0);

        Schema.RegisterProductArgs memory badArgs = Schema.RegisterProductArgs({
            productId: 1,
            offeringAmount: OFFERING_AMOUNT,
            minInvestment: MIN_INVESTMENT,
            offeringEndDate: OFFERING_END_DATE,
            maturityDate: maturityDate,
            expectedYield: EXPECTED_YIELD,
            operationStartDate: OPERATION_STARTDATE,
            distributionStartDate: distributionStartDate,
            totalDistributionCount: 5,
            distributionInterval: 3,
            baseTokenURI: BASE_TOKEN_URI,
            requiredTier: 0
        });

        vm.prank(admin);
        vm.expectRevert(IInvestmentErrors.InvalidMaturityDate.selector);
        RegisterProduct(target).registerProduct(badArgs);
    }

    /// @notice Valid scenario: schedule fits within maturityDate → success
    ///         distributionStartDate=2025-06-01, interval=3mo, count=3
    ///         lastDistributionDate = 2025-06-01 + 3*2 = 2025-12-01
    ///         maturityDate = 2026-01-01 → OK
    function test_success_whenDistributionScheduleFitsMaturityDate() public {
        uint256 distributionStartDate = DateTime.toTimestamp(2025, 6, 1, 0, 0, 0);
        uint256 maturityDate = DateTime.toTimestamp(2026, 1, 1, 0, 0, 0);

        Schema.RegisterProductArgs memory goodArgs = Schema.RegisterProductArgs({
            productId: 2,
            offeringAmount: OFFERING_AMOUNT,
            minInvestment: MIN_INVESTMENT,
            offeringEndDate: OFFERING_END_DATE,
            maturityDate: maturityDate,
            expectedYield: EXPECTED_YIELD,
            operationStartDate: OPERATION_STARTDATE,
            distributionStartDate: distributionStartDate,
            totalDistributionCount: 3,
            distributionInterval: 3,
            baseTokenURI: BASE_TOKEN_URI,
            requiredTier: 0
        });

        vm.prank(admin);
        RegisterProduct(target).registerProduct(goodArgs);

        Schema.Product memory product = Storage.ProductsState().products[2];
        assertEq(product.productId, 2);
        assertEq(product.maturityDate, maturityDate);
        assertEq(product.totalDistributionCount, 3);
    }

    /// @notice Month-end mode: schedule overshoots due to month-end alignment → revert
    ///         distributionStartDate=2025-02-28 (month-end, >= operationStartDate 2025-02-01)
    ///         interval=1mo, count=11
    ///         lastDistributionDate = 2025-02-28 + 1*10 months = 2025-12-28 → month-end adjusted → 2025-12-31
    ///         maturityDate = 2025-12-30 → 1 day overshoot → must revert
    function test_revert_monthEnd_whenScheduleExceedsMaturityDate() public {
        uint256 distributionStartDate = DateTime.toTimestamp(2025, 2, 28, 0, 0, 0);
        uint256 maturityDate = DateTime.toTimestamp(2025, 12, 30, 0, 0, 0);

        Schema.RegisterProductArgs memory badArgs = Schema.RegisterProductArgs({
            productId: 3,
            offeringAmount: OFFERING_AMOUNT,
            minInvestment: MIN_INVESTMENT,
            offeringEndDate: OFFERING_END_DATE,
            maturityDate: maturityDate,
            expectedYield: EXPECTED_YIELD,
            operationStartDate: OPERATION_STARTDATE,
            distributionStartDate: distributionStartDate,
            totalDistributionCount: 11,
            distributionInterval: 1,
            baseTokenURI: BASE_TOKEN_URI,
            requiredTier: 0
        });

        vm.prank(admin);
        vm.expectRevert(IInvestmentErrors.InvalidMaturityDate.selector);
        RegisterProduct(target).registerProduct(badArgs);
    }

    receive() external payable {}
}
