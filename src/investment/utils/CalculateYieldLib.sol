// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

/**
 * @title CalculateYieldLib
 * @notice A library that provides common calculations used in investment products
 * @dev To improve the accuracy of yield calculations, rounding is implemented using CALC_SCALE
 */
library CalculateYieldLib {
    /// @notice Basis Points (100% = 10,000)
    uint256 constant BPS = 10000;

    /// @notice Constant (365 days) that expresses the number of days in a year in seconds
    uint256 constant YEAR_IN_DAYS = 365 days;

    /// @notice Scale factor (1e10) for improved calculation accuracy
    uint256 constant CALC_SCALE = 1e10;

    /// @notice Constant for rounding (CALC_SCALE / 2)
    uint256 constant HALF_CALC_SCALE = CALC_SCALE / 2; // 1e10 / 2 = 5e9 = 0.5

    /// @notice Maximum batch size
    uint256 constant MAX_BATCH_SIZE = 50;

    /**
     * @notice Calculate the overall yield (periodYield) during the given period
     *         Original expression: periodYield = (((raisedAmount * expectedYield) / 365) * period)
     * @dev Transforming the equation to improve overflow prevention and calculation accuracy.
     *      Rounding is implemented by adding the CALC_SCALE extension and HALF_CALC_SCALE in the following formula.
     *      Since the expectedYield is on a scale of 10000, it is converted to the correct ratio when calculating.
     *      !!!!!!!!!! Tolerance ±1 !!!!!!!!!!
     *      1. First, multiply raisedAmount, expectedYield, period, and CALC_SCALE
     *      2. Divide by YEAR_IN_DAYS * BPS
     *      3. Add HALF_CALC_SCALE (equivalent to 0.5), and finally divide by CALC_SCALE
     * @param raisedAmount Total investment amount collected for the product
     * @param expectedYield Expected yield (BPS scale: 100% = 10000)
     * @param period Investment period in seconds (e.g., 90 days = 7,776,000 seconds)
     * @return Overall yield (rounded to the nearest tenth) for a given period after calculations
     */
    function calculatePeriodYield(uint256 raisedAmount, uint256 expectedYield, uint256 period)
        internal
        pure
        returns (uint256)
    {
        uint256 periodYieldCalcScale =
            (raisedAmount * expectedYield * period * CALC_SCALE) / (YEAR_IN_DAYS * BPS) + HALF_CALC_SCALE;
        return periodYieldCalcScale / CALC_SCALE;
    }

    /**
     * @notice Calculate the period yield received by individual investors
     *         Original expression: individualPeriodYield = periodYield * (investmentAmount / raisedAmount)
     * @dev Transforming the equation to improve overflow prevention and calculation accuracy.
     *      Rounding is implemented by adding the CALC_SCALE extension and HALF_CALC_SCALE in the following formula.
     *      !!!!!!!!!! Tolerance ±1 !!!!!!!!!!
     *      1. First, multiply periodYield, investmentAmount, and CALC_SCALE
     *      2. Divide by raisedAmount
     *      3. Add HALF_CALC_SCALE (equivalent to 0.5), and finally divide by CALC_SCALE
     * @param periodYield Overall period yield (value obtained with calculatePeriodYield)
     * @param investmentAmount Amount invested by individual investors
     * @param raisedAmount Total investment amount collected for the product
     * @return The yield (rounded to the nearest whole number) for a given period received by individual investors
     */
    function calculateIndividualPeriodYield(uint256 periodYield, uint256 investmentAmount, uint256 raisedAmount)
        internal
        pure
        returns (uint256)
    {
        uint256 individualPeriodYieldCalcScale =
            (periodYield * investmentAmount * CALC_SCALE) / raisedAmount + HALF_CALC_SCALE;
        return individualPeriodYieldCalcScale / CALC_SCALE;
    }

    /**
     * @notice Calculate the tolerance for the period
     *         Tolerance is the number of nfts plus the number of batches
     * @param nftCount The number of NFTs in the product
     * @return The tolerance for the period
     */
    function calculatePeriodTolerance(uint256 nftCount) internal pure returns (uint256) {
        if (nftCount % MAX_BATCH_SIZE == 0) {
            return nftCount + (nftCount / MAX_BATCH_SIZE);
        } else {
            return nftCount + 1 + (nftCount / MAX_BATCH_SIZE);
        }
    }

    /**
     * @notice Calculate the remainder of the period tolerance
     * @param distributedTokenId The tokenId of the distributed
     * @param periodTolerance The tolerance for the period
     * @return The remainder of the period tolerance
     */
    function calculatePeriodToleranceRemainder(uint256 distributedTokenId, uint256 periodTolerance)
        internal
        pure
        returns (uint256)
    {
        uint256 alreadyBatchCounted = (distributedTokenId / MAX_BATCH_SIZE);
        return periodTolerance - (MAX_BATCH_SIZE * alreadyBatchCounted) + alreadyBatchCounted;
    }

    /**
     * @notice Calculate the total tolerance for the period
     *         Tolerance is the number of nfts plus the number of batches
     * @param nftCount The number of NFTs in the product
     * @param totalDistributionCount The total number of distributions
     * @return The total tolerance for the period
     */
    function calculateTotalTolerance(uint256 nftCount, uint256 totalDistributionCount) internal pure returns (uint256) {
        if (nftCount % MAX_BATCH_SIZE == 0) {
            return (nftCount + (nftCount / MAX_BATCH_SIZE)) * totalDistributionCount;
        } else {
            return (nftCount + 1 + (nftCount / MAX_BATCH_SIZE)) * totalDistributionCount;
        }
    }
}

// Testing
import {MCTest} from "@mc-devkit/Flattened.sol";
import {console} from "forge-std/console.sol";

contract CalculateYieldLibTest is MCTest {
    uint256 public constant MAX_RAISED_AMOUNT = 1_000_000_000_000_000; // 1_000_000_000USD(1USD = 150JPY: 150_000_000_000JPY)
    uint256 public constant MAX_EXPECTED_YIELD = 5000; // 50%
    uint256 public constant MAX_PERIOD = 3650 days; // 10 years

    //==========================
    //  Calculation accuracy
    //==========================

    /**
     * @notice A realistic case
     */
    function test_calculateYield_success() external pure {
        uint256 raisedAmount = 1_000_000_000_000; // 1_000_000USD(1USD = 150JPY: 150_000_000JPY)
        uint256 expectedYield = 500; // 5%
        uint256 period = 90 days;
        uint256 investmentAmount = 1_000_000_000; // 1_000USD(1USD = 150JPY: 150_000JPY)

        // Calculate periodYield using a calculator
        // periodYield = (((raisedAmount * expectedYield) / 365) * period)
        // periodYield = (((1_000_000_000_000 * 0.05) / 365) * 90)
        // periodYield = 12_328_767_123.28767 = 12_328_767_123
        uint256 calculatorValuePeriodYield = 12_328_767_123;
        uint256 periodYield = CalculateYieldLib.calculatePeriodYield(raisedAmount, expectedYield, period);
        console.log("periodYield", periodYield);
        assertEq(periodYield, calculatorValuePeriodYield, "missmatch");

        // Calculate individualPeriodYield using a calculator
        // individualPeriodYield = periodYield * (investmentAmount / raisedAmount)
        // individualPeriodYield = 12_328_767_123 * (1_000_000_000 / 1_000_000_000_000)
        // individualPeriodYield = 12_328_767.123 = 12_328_767
        uint256 calculatorValueIndividualPeriodYield = 12_328_767;
        uint256 individualPeriodYield =
            CalculateYieldLib.calculateIndividualPeriodYield(periodYield, investmentAmount, raisedAmount);
        console.log("individualPeriodYield", individualPeriodYield);
        assertEq(individualPeriodYield, calculatorValueIndividualPeriodYield, "missmatch");
    }

    /**
     * @notice Fuzz test to see if the distributed yield is correct
     * @dev The total of multiple investmentAmounts is randomly calculated and regarded as the raisedAmount.
     *      Check that the combined yield for individual investors does not differ greatly from the periodYield.
     *      (A little error due to rounding is OK)
     */
    function testFuzz_calculateDistributedYields_success(
        uint256 fuzzNumOfInvestors,
        uint256 fuzzinvestmentAmount,
        uint256 fuzzExpectedYield,
        uint256 fuzzPeriod
    ) external pure {
        uint256 numOfInvestors = bound(fuzzNumOfInvestors, 1, 1000);
        uint256 expectedYield = bound(fuzzExpectedYield, 1, MAX_EXPECTED_YIELD);
        uint256 period = bound(fuzzPeriod, 1, MAX_PERIOD);

        uint256 raisedAmount = 0;
        uint256[] memory investments = new uint256[](numOfInvestors);
        for (uint256 i = 0; i < numOfInvestors; i++) {
            uint256 investmentAmount =
                bound(uint256(keccak256(abi.encode(i, fuzzinvestmentAmount))), 300_000_000, 10_000_000_000);
            investments[i] = investmentAmount;
            raisedAmount += investmentAmount;
        }

        uint256 periodYield = CalculateYieldLib.calculatePeriodYield(raisedAmount, expectedYield, period);

        uint256 distributed = 0;
        for (uint256 i = 0; i < numOfInvestors; i++) {
            uint256 individualPeriodYield =
                CalculateYieldLib.calculateIndividualPeriodYield(periodYield, investments[i], raisedAmount);
            distributed += individualPeriodYield;
        }

        // Allow for the maximum error that occurs for each investor (1 per investor)
        uint256 tolerance = numOfInvestors;
        if (distributed > periodYield) {
            console.log("distributed - periodYield", distributed - periodYield);
            assertLe(distributed - periodYield, tolerance, "Aggregated yields exceed total yield too much");
        } else {
            console.log("periodYield - distributed", periodYield - distributed);
            assertLe(periodYield - distributed, tolerance, "Aggregated yields too far below total yield");
        }
    }

    function test_calculatePeriodTolerance_success() external pure {
        uint256 nftCount100 = 100;
        uint256 nftCountOverMaxBatchSize = 57;
        uint256 nftCountUnderMaxBatchSize = 14;

        uint256 periodTolerance100 = CalculateYieldLib.calculatePeriodTolerance(nftCount100);
        uint256 periodToleranceOverMaxBatchSize = CalculateYieldLib.calculatePeriodTolerance(nftCountOverMaxBatchSize);
        uint256 periodToleranceUnderMaxBatchSize = CalculateYieldLib.calculatePeriodTolerance(nftCountUnderMaxBatchSize);

        // nftCount + (nftCount / MAX_BATCH_SIZE) = 100 + (100 / MAX_BATCH_SIZE) = 102
        assertEq(periodTolerance100, 102, "missmatch");

        // nftCount + 1 + (nftCount / MAX_BATCH_SIZE) = 57 + 1 + (57 / MAX_BATCH_SIZE) = 59
        assertEq(periodToleranceOverMaxBatchSize, 59, "missmatch");

        // nftCount + 1 + (nftCount / MAX_BATCH_SIZE) = 14 + 1 + (14 / MAX_BATCH_SIZE) = 15
        assertEq(periodToleranceUnderMaxBatchSize, 15, "missmatch");
    }

    function test_calculatePeriodToleranceRemainder_success() external pure {
        uint256 distributedTokenId0 = 0;
        uint256 distributedTokenId50 = 50;

        uint256 nftCount100 = 100;
        uint256 nftCountOverMaxBatchSize = 57;
        uint256 nftCountUnderMaxBatchSize = 14;

        uint256 periodTolerance100 = CalculateYieldLib.calculatePeriodTolerance(nftCount100); // 102
        uint256 periodToleranceOverMaxBatchSize = CalculateYieldLib.calculatePeriodTolerance(nftCountOverMaxBatchSize); // 59
        uint256 periodToleranceUnderMaxBatchSize = CalculateYieldLib.calculatePeriodTolerance(nftCountUnderMaxBatchSize); // 15

        // alreadyBatchCounted = (distributedTokenId / MAX_BATCH_SIZE) = (0 / MAX_BATCH_SIZE) = 0
        // periodToleranceRemainder100 periodTolerance - (MAX_BATCH_SIZE * alreadyBatchCounted) + alreadyBatchCounted = 102 - (50 * 0) + 0 = 102
        uint256 periodToleranceRemainder100_distributedTokenId0 =
            CalculateYieldLib.calculatePeriodToleranceRemainder(distributedTokenId0, periodTolerance100);
        assertEq(periodToleranceRemainder100_distributedTokenId0, 102, "missmatch");

        // alreadyBatchCounted = (distributedTokenId / MAX_BATCH_SIZE) = (50 / MAX_BATCH_SIZE) = 1
        // periodToleranceRemainder100_ distributedTokenId50 = periodTolerance - (MAX_BATCH_SIZE * alreadyBatchCounted) + alreadyBatchCounted = 102 - (50 * 1) + 1 = 53
        uint256 periodToleranceRemainder100_distributedTokenId50 =
            CalculateYieldLib.calculatePeriodToleranceRemainder(distributedTokenId50, periodTolerance100);
        assertEq(periodToleranceRemainder100_distributedTokenId50, 53, "missmatch");

        // alreadyBatchCounted = (distributedTokenId / MAX_BATCH_SIZE) = (0 / MAX_BATCH_SIZE) = 0
        // periodToleranceRemainderOverMaxBatchSize_distributedTokenId0 = periodTolerance - (MAX_BATCH_SIZE * alreadyBatchCounted) + alreadyBatchCounted = 59 - (50 * 0) + 0 = 59
        uint256 periodToleranceRemainderOverMaxBatchSize_distributedTokenId0 =
            CalculateYieldLib.calculatePeriodToleranceRemainder(distributedTokenId0, periodToleranceOverMaxBatchSize);
        assertEq(periodToleranceRemainderOverMaxBatchSize_distributedTokenId0, 59, "missmatch");

        // alreadyBatchCounted = (distributedTokenId / MAX_BATCH_SIZE) = (50 / MAX_BATCH_SIZE) = 1
        // periodToleranceRemainderOverMaxBatchSize_distributedTokenId50 = periodTolerance - (MAX_BATCH_SIZE * alreadyBatchCounted) + alreadyBatchCounted = 59 - (50 * 1) + 1 = 10
        uint256 periodToleranceRemainderOverMaxBatchSize_distributedTokenId50 =
            CalculateYieldLib.calculatePeriodToleranceRemainder(distributedTokenId50, periodToleranceOverMaxBatchSize);
        assertEq(periodToleranceRemainderOverMaxBatchSize_distributedTokenId50, 10, "missmatch");

        // alreadyBatchCounted = (distributedTokenId / MAX_BATCH_SIZE) = (0 / MAX_BATCH_SIZE) = 0
        // periodToleranceRemainderUnderMaxBatchSize_distributedTokenId0 = periodTolerance - (MAX_BATCH_SIZE * alreadyBatchCounted) + alreadyBatchCounted = 15 - (50 * 0) + 0 = 15
        uint256 periodToleranceRemainderUnderMaxBatchSize_distributedTokenId0 =
            CalculateYieldLib.calculatePeriodToleranceRemainder(distributedTokenId0, periodToleranceUnderMaxBatchSize);
        assertEq(periodToleranceRemainderUnderMaxBatchSize_distributedTokenId0, 15, "missmatch");
    }

    function test_calculateTotalTolerance_success() external pure {
        uint256 nftCount100 = 100;
        uint256 nftCountOverMaxBatchSize = 57;
        uint256 nftCountUnderMaxBatchSize = 14;

        uint256 totalDistributionCount = 4;

        uint256 totalTolerance100 = CalculateYieldLib.calculateTotalTolerance(nftCount100, totalDistributionCount);
        uint256 totalToleranceOverMaxBatchSize =
            CalculateYieldLib.calculateTotalTolerance(nftCountOverMaxBatchSize, totalDistributionCount);
        uint256 totalToleranceUnderMaxBatchSize =
            CalculateYieldLib.calculateTotalTolerance(nftCountUnderMaxBatchSize, totalDistributionCount);

        // (nftCount + (nftCount / MAX_BATCH_SIZE)) * totalDistributionCount = (100 + (100 / MAX_BATCH_SIZE)) * 4 = 102 * 4 = 408
        assertEq(totalTolerance100, 408, "missmatch");

        // (nftCount + 1 + (nftCount / MAX_BATCH_SIZE)) * totalDistributionCount = (57 + 1 + (57 / MAX_BATCH_SIZE)) * 4 = 59 * 4 = 236
        assertEq(totalToleranceOverMaxBatchSize, 236, "missmatch");

        // (nftCount + 1 + (nftCount / MAX_BATCH_SIZE)) * totalDistributionCount = (14 + 1 + (14 / MAX_BATCH_SIZE)) * 4 = 15 * 4 = 60
        assertEq(totalToleranceUnderMaxBatchSize, 60, "missmatch");
    }

    //========================
    //      Edge Cases
    //========================

    /**
     * @notice Test to see if the calculation is correct at the minimum value
     */
    function test_calculateYield_success_minValues() external pure {
        uint256 raisedAmount = 1_000_000; //1USD
        uint256 expectedYield = 1; //0.01%
        uint256 period = 1 days;
        uint256 investmentAmount = 1_000_000; //1USD

        // Calculate periodYield using a calculator
        // periodYield = (((raisedAmount * expectedYield) / 365) * period)
        // periodYield = (((1_000_000 * 0.0001) / 365) * 1)
        // periodYield = 0.273973 = 0
        uint256 calculatorValuePeriodYield = 0;
        uint256 periodYield = CalculateYieldLib.calculatePeriodYield(raisedAmount, expectedYield, period);
        console.log("periodYield", periodYield);
        assertEq(periodYield, calculatorValuePeriodYield, "missmatch");

        // Calculate individualPeriodYield using a calculator
        // individualPeriodYield = periodYield * (investmentAmount / raisedAmount)
        // individualPeriodYield = 0 * (1_000_000 / 1_000_000)
        // individualPeriodYield = 0
        uint256 calculatorValueIndividualPeriodYield = 0;
        uint256 individualPeriodYield =
            CalculateYieldLib.calculateIndividualPeriodYield(periodYield, investmentAmount, raisedAmount);
        console.log("individualPeriodYield", individualPeriodYield);
        assertEq(individualPeriodYield, calculatorValueIndividualPeriodYield, "missmatch");
    }

    /**
     * @notice Test to see if the calculation is correct at the maximum value
     */
    function test_calculateYield_success_maxValues() external pure {
        uint256 investmentAmount = MAX_RAISED_AMOUNT / 2;

        // Calculate periodYield using a calculator
        // periodYield = (((raisedAmount * expectedYield) / 365) * period)
        // periodYield = (((1_000_000_000_000_000 * 0.5) / 365) * 3650)
        // periodYield = 5_000_000_000_000_000
        uint256 calculatorValuePeriodYield = 5_000_000_000_000_000;
        uint256 periodYield = CalculateYieldLib.calculatePeriodYield(MAX_RAISED_AMOUNT, MAX_EXPECTED_YIELD, MAX_PERIOD);
        console.log("periodYield", periodYield);
        assertTrue(periodYield == calculatorValuePeriodYield, "missmatch");

        // Calculate individualPeriodYield using a calculator
        // individualPeriodYield = periodYield * (investmentAmount / raisedAmount)
        // individualPeriodYield = 5_000_000_000_000_000 * (500_000_000_000_000 / 1_000_000_000_000_000)
        // individualPeriodYield = 2_500_000_000_000_000
        uint256 calculatorValueIndividualPeriodYield = 2_500_000_000_000_000;
        uint256 individualPeriodYield =
            CalculateYieldLib.calculateIndividualPeriodYield(periodYield, investmentAmount, MAX_RAISED_AMOUNT);
        console.log("individualPeriodYield", individualPeriodYield);
        assertEq(individualPeriodYield, calculatorValueIndividualPeriodYield, "missmatch");
    }

    /**
     * @notice Test to see if the calculation is correct at a complex value
     */
    function test_calculateYield_success_complexValues() external pure {
        uint256 raisedAmount = 4_375_992_563_558;
        uint256 expectedYield = 4531;
        uint256 period = 2459 days;
        uint256 investmentAmount = 1_477_824_134_927;

        // Calculate periodYield using a calculator
        // periodYield = (((raisedAmount * expectedYield) / 365) * period)
        // periodYield = (((4_375_992_563_558 * 0.4531) / 365) * 2459)
        // periodYield = 13_357_841_986_076.307 = 13_357_841_986_076
        uint256 calculatorValuePeriodYield = 13_357_841_986_076;
        uint256 periodYield = CalculateYieldLib.calculatePeriodYield(raisedAmount, expectedYield, period);
        console.log("periodYield", periodYield);
        assertTrue(periodYield == calculatorValuePeriodYield, "missmatch");

        // Calculate individualPeriodYield using a calculator
        // individualPeriodYield = periodYield * (investmentAmount / raisedAmount)
        // individualPeriodYield = 13_357_841_986_076 * (1_477_824_134_927 / 4_375_992_563_558)
        // individualPeriodYield = 4_511_100_279_730.326 = 4_511_100_279_730
        uint256 calculatorValueIndividualPeriodYield = 4_511_100_279_730;
        uint256 individualPeriodYield =
            CalculateYieldLib.calculateIndividualPeriodYield(periodYield, investmentAmount, raisedAmount);
        console.log("individualPeriodYield", individualPeriodYield);
        assertEq(individualPeriodYield, calculatorValueIndividualPeriodYield, "missmatch");
    }

    //=========================
    //      Overflow Tests
    //=========================

    /**
     * @notice Test to see if it overflows at the maximum value
     */
    function test_calculateYield_success_noOverflow() external pure {
        // periodYield
        uint256 periodYield = CalculateYieldLib.calculatePeriodYield(MAX_RAISED_AMOUNT, MAX_EXPECTED_YIELD, MAX_PERIOD);
        assertTrue(periodYield < type(uint256).max, "overflow");

        // individualPeriodYield
        uint256 individualPeriodYield =
            CalculateYieldLib.calculateIndividualPeriodYield(periodYield, MAX_RAISED_AMOUNT, MAX_RAISED_AMOUNT);
        assertTrue(individualPeriodYield < type(uint256).max, "overflow");
    }

    /**
     * @notice Fuzz test to see if it overflows at the maximum value
     */
    function testFuzz_calculateYield_success_noOverflow(
        uint256 fuzzRaisedAmount,
        uint256 fuzzExpectedYield,
        uint256 fuzzPeriod,
        uint256 fuzzInvestmentAmount
    ) external pure {
        uint256 raisedAmount = bound(fuzzRaisedAmount, 1, MAX_RAISED_AMOUNT);
        uint256 expectedYield = bound(fuzzExpectedYield, 1, MAX_EXPECTED_YIELD);
        uint256 period = bound(fuzzPeriod, 1, MAX_PERIOD);
        uint256 investmentAmount = bound(fuzzInvestmentAmount, 0, raisedAmount);

        // periodYield
        uint256 periodYield = CalculateYieldLib.calculatePeriodYield(raisedAmount, expectedYield, period);
        assertTrue(periodYield < type(uint256).max, "overflow");
        assertTrue(periodYield >= 0, "result should not be negative (impossible in uint256)");

        // individualPeriodYield
        uint256 individualPeriodYield =
            CalculateYieldLib.calculateIndividualPeriodYield(periodYield, investmentAmount, raisedAmount);
        assertTrue(individualPeriodYield < type(uint256).max, "overflow occurred in fuzz test");
        assertTrue(individualPeriodYield >= 0, "result should not be negative (impossible in uint256)");
    }

    receive() external payable {}
}
