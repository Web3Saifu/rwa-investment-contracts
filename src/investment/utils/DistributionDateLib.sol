// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {DateTime} from "lib/chainlink-evm/contracts/src/v0.8/vendor/DateTime.sol";

/**
 * @title DistributionDateLib
 * @notice Library that centralizes date calculations for yield distribution dates
 */
library DistributionDateLib {
    /**
     * @notice Calculates the next yield distribution date
     * @dev Distribution dates are handled in day units, so time is normalized to 00:00:00
     * @param distributionStartDate First yield distribution date (timestamp)
     * @param distributionInterval Distribution interval (in months)
     * @param distributedCount Number of distributions already executed
     * @param isMonthEndFlag Whether distribution dates should be aligned to month-end
     * @return Next yield distribution date (timestamp)
     */
    function calculateNextDistributionDate(
        uint256 distributionStartDate,
        uint256 distributionInterval,
        uint256 distributedCount,
        bool isMonthEndFlag
    ) internal pure returns (uint256) {
        uint256 monthsToAdd = distributionInterval * distributedCount;
        uint256 nextDate = addMonths(distributionStartDate, monthsToAdd);
        nextDate = normalizeToMidnight(nextDate);

        // Align to month-end when month-end mode is enabled
        if (isMonthEndFlag) {
            nextDate = adjustToMonthEnd(nextDate);
        }

        return nextDate;
    }

    /**
     * @notice Normalizes the time portion of a timestamp to 00:00:00 (time is ignored in day-based calculations)
     * @param timestamp Timestamp to normalize
     * @return Timestamp at 00:00:00 on the same day
     */
    function normalizeToMidnight(uint256 timestamp) internal pure returns (uint256) {
        uint16 year = DateTime.getYear(timestamp);
        uint8 month = DateTime.getMonth(timestamp);
        uint8 day = DateTime.getDay(timestamp);
        return DateTime.toTimestamp(year, month, day, 0, 0, 0);
    }

    /**
     * @notice Determines whether the given timestamp is at month-end
     * @param timestamp Timestamp to evaluate
     * @return bool True if month-end, false otherwise
     */
    function isMonthEndDate(uint256 timestamp) internal pure returns (bool) {
        uint8 day = DateTime.getDay(timestamp);
        uint8 month = DateTime.getMonth(timestamp);
        uint16 year = DateTime.getYear(timestamp);
        uint8 maxDay = DateTime.getDaysInMonth(month, year);
        return day == maxDay;
    }

    /**
     * @notice Adjusts the given timestamp to month-end (00:00:00)
     */
    function adjustToMonthEnd(uint256 timestamp) internal pure returns (uint256) {
        uint16 year = DateTime.getYear(timestamp);
        uint8 month = DateTime.getMonth(timestamp);
        uint8 maxDay = DateTime.getDaysInMonth(month, year);
        return DateTime.toTimestamp(year, month, maxDay, 0, 0, 0);
    }

    /**
     * @notice Adds a number of months to the given timestamp
     * @dev If the day exceeds the maximum day in the target month, it is clamped to month-end
     */
    function addMonths(uint256 timestamp, uint256 monthsToAdd) internal pure returns (uint256) {
        // Extract original date and time components
        uint16 year = DateTime.getYear(timestamp);
        uint8 month = DateTime.getMonth(timestamp);
        uint8 day = DateTime.getDay(timestamp);
        uint8 hour = DateTime.getHour(timestamp);
        uint8 minute = DateTime.getMinute(timestamp);
        uint8 second = DateTime.getSecond(timestamp);

        // Efficiently carry over year/month
        uint256 totalMonths = uint256(month) - 1 + monthsToAdd; // 0-indexed
        year += uint16(totalMonths / 12);
        month = uint8((totalMonths % 12) + 1); // back to 1-12

        // Get max day in the target month and clamp if overflowed
        uint8 maxDayInMonth = DateTime.getDaysInMonth(month, year);
        if (day > maxDayInMonth) {
            day = maxDayInMonth;
        }

        return DateTime.toTimestamp(year, month, day, hour, minute, second);
    }

    /**
     * @notice Calculates the first distribution period (in seconds)
     * @param distributionStartDate First yield distribution date (timestamp)
     * @param operationStartDate Operation start date (timestamp)
     * @return First distribution period (seconds)
     */
    function calculateFirstDistributionPeriod(uint256 distributionStartDate, uint256 operationStartDate)
        internal
        pure
        returns (uint256)
    {
        return distributionStartDate - operationStartDate;
    }

    /**
     * @notice Calculates the distribution period (in seconds)
     * @dev Determines the correct previous distribution date based on distributedCount, then returns
     *      the difference in seconds from the current distribution date. This value is used as the
     *      period (seconds) passed to calculatePeriodYield.
     * @dev distributionInterval must be > 0. distributedCount must be >= 1.
     * @param distributionStartDate First yield distribution date (timestamp)
     * @param distributionInterval Distribution interval (in months)
     * @param distributedCount Number of distributions already executed (if >= 1, calculates from the second period onward)
     * @param isMonthEndFlag Whether distribution dates should be aligned to month-end
     * @return Distribution period (seconds)
     */
    function calculateDistributionPeriod(
        uint256 distributionStartDate,
        uint256 distributionInterval,
        uint256 distributedCount,
        bool isMonthEndFlag
    ) internal pure returns (uint256) {
        uint256 previousDistributionDate;
        if (distributedCount == 1) {
            // For 2nd distribution: previous date is the first distribution date, normalized to 00:00:00
            previousDistributionDate = normalizeToMidnight(distributionStartDate);
            if (isMonthEndFlag) {
                previousDistributionDate = adjustToMonthEnd(previousDistributionDate);
            }
        } else {
            // For 3rd distribution onwards: calculate previous distribution date using library
            previousDistributionDate = calculateNextDistributionDate(
                distributionStartDate, distributionInterval, distributedCount - 1, isMonthEndFlag
            );
        }
        uint256 currentDistributionDate = calculateNextDistributionDate(
            distributionStartDate, distributionInterval, distributedCount, isMonthEndFlag
        );
        return currentDistributionDate - previousDistributionDate;
    }
}

// Testing (test contract is placed in the same file)
import {MCTest} from "@mc-devkit/Flattened.sol";
import {DistributionDateLib} from "./DistributionDateLib.sol";

contract DistributionDateLibTest is MCTest {
    receive() external payable {}

    // --- addMonths ---
    function test_addMonths_jan31_to_feb28_nonLeap() public pure {
        uint256 jan31_2025 = DateTime.toTimestamp(2025, 1, 31, 0, 0, 0);
        uint256 feb28_2025 = DateTime.toTimestamp(2025, 2, 28, 0, 0, 0);
        assertEq(DistributionDateLib.addMonths(jan31_2025, 1), feb28_2025);
    }

    function test_addMonths_jan31_to_feb29_leap() public pure {
        uint256 jan31_2024 = DateTime.toTimestamp(2024, 1, 31, 0, 0, 0);
        uint256 feb29_2024 = DateTime.toTimestamp(2024, 2, 29, 0, 0, 0);
        assertEq(DistributionDateLib.addMonths(jan31_2024, 1), feb29_2024);
    }

    function test_addMonths_cross_year() public pure {
        uint256 dec31_2024 = DateTime.toTimestamp(2024, 12, 31, 0, 0, 0);
        uint256 jan31_2025 = DateTime.toTimestamp(2025, 1, 31, 0, 0, 0);
        assertEq(DistributionDateLib.addMonths(dec31_2024, 1), jan31_2025);
    }

    // --- normalizeToMidnight ---
    function test_normalizeToMidnight_strips_time_to_000000() public pure {
        uint256 withTime = DateTime.toTimestamp(2025, 6, 15, 12, 34, 56);
        uint256 expected = DateTime.toTimestamp(2025, 6, 15, 0, 0, 0);
        assertEq(DistributionDateLib.normalizeToMidnight(withTime), expected);
    }

    // --- adjustToMonthEnd ---
    function test_adjustToMonthEnd_sets_last_day_and_midnight() public pure {
        uint256 may15 = DateTime.toTimestamp(2025, 5, 15, 12, 34, 56);
        uint256 expected = DateTime.toTimestamp(2025, 5, 31, 0, 0, 0);
        assertEq(DistributionDateLib.adjustToMonthEnd(may15), expected);
    }

    // --- calculateNextDistributionDate ---
    function test_calcNext_noMonthEnd_keeps_same_day() public pure {
        uint256 start = DateTime.toTimestamp(2025, 1, 10, 15, 0, 0);
        // interval 2 months, count 1 => 2025-03-10 00:00:00
        uint256 expected = DateTime.toTimestamp(2025, 3, 10, 0, 0, 0);
        assertEq(DistributionDateLib.calculateNextDistributionDate(start, 2, 1, false), expected);
    }

    function test_calcNext_monthEnd_aligns_to_month_end() public pure {
        uint256 start = DateTime.toTimestamp(2025, 1, 31, 10, 0, 0);
        // interval 1 month, count 1 => 2025-02-28 (non-leap year) 00:00:00
        uint256 expected = DateTime.toTimestamp(2025, 2, 28, 0, 0, 0);
        assertEq(DistributionDateLib.calculateNextDistributionDate(start, 1, 1, true), expected);
    }

    function test_calcNext_monthEnd_leap_year() public pure {
        // Use the next leap year (2028)
        uint256 start = DateTime.toTimestamp(2028, 1, 31, 22, 0, 0);

        // interval 1 month, count 1 => 2028-02-29 00:00:00 (leap year)
        uint256 expected1 = DateTime.toTimestamp(2028, 2, 29, 0, 0, 0);
        assertEq(DistributionDateLib.calculateNextDistributionDate(start, 1, 1, true), expected1);

        // After leap-year calculation, verify that the next calculation is also correct
        // interval 1 month, count 2 => 2028-03-31 00:00:00 (post-leap-year calculation)
        uint256 expected2 = DateTime.toTimestamp(2028, 3, 31, 0, 0, 0);
        assertEq(DistributionDateLib.calculateNextDistributionDate(start, 1, 2, true), expected2);

        // Also verify the following month (calculation after crossing leap-year February)
        // interval 1 month, count 3 => 2028-04-30 00:00:00
        uint256 expected3 = DateTime.toTimestamp(2028, 4, 30, 0, 0, 0);
        assertEq(DistributionDateLib.calculateNextDistributionDate(start, 1, 3, true), expected3);
    }

    function test_calcNext_multiple_intervals() public pure {
        uint256 start = DateTime.toTimestamp(2025, 6, 30, 0, 0, 0);
        // interval 3 months, count 2 => +6 months => 2025-12-30 00:00:00
        uint256 expected = DateTime.toTimestamp(2025, 12, 30, 0, 0, 0);
        assertEq(DistributionDateLib.calculateNextDistributionDate(start, 3, 2, false), expected);
    }

    // --- calculateDistributionPeriod ---
    // Normal day pattern (isMonthEnd = false)
    function test_calculateDistributionPeriod_count1_normalDay() public pure {
        // N-1: start=2025-01-10 15:00, interval=1, count=1 -> Prev=2025-01-10 00:00, Curr=2025-02-10 00:00, delta=31 days
        uint256 start = DateTime.toTimestamp(2025, 1, 10, 15, 0, 0);
        uint256 period = DistributionDateLib.calculateDistributionPeriod(start, 1, 1, false);
        uint256 expected = DateTime.toTimestamp(2025, 2, 10, 0, 0, 0) - DateTime.toTimestamp(2025, 1, 10, 0, 0, 0);
        assertEq(period, expected);
    }

    function test_calculateDistributionPeriod_count2_normalDay() public pure {
        // N-2: start=2025-01-10 00:00, interval=1, count=2 -> Prev=2025-02-10, Curr=2025-03-10, delta=28 days
        uint256 start = DateTime.toTimestamp(2025, 1, 10, 0, 0, 0);
        uint256 period = DistributionDateLib.calculateDistributionPeriod(start, 1, 2, false);
        uint256 expected = DateTime.toTimestamp(2025, 3, 10, 0, 0, 0) - DateTime.toTimestamp(2025, 2, 10, 0, 0, 0);
        assertEq(period, expected);
    }

    function test_calculateDistributionPeriod_count3_normalDay() public pure {
        // N-3: start=2025-01-10 00:00, interval=1, count=3 -> Prev=2025-03-10, Curr=2025-04-10, delta=31 days
        uint256 start = DateTime.toTimestamp(2025, 1, 10, 0, 0, 0);
        uint256 period = DistributionDateLib.calculateDistributionPeriod(start, 1, 3, false);
        uint256 expected = DateTime.toTimestamp(2025, 4, 10, 0, 0, 0) - DateTime.toTimestamp(2025, 3, 10, 0, 0, 0);
        assertEq(period, expected);
    }

    // Month-end pattern (isMonthEnd = true)
    function test_calculateDistributionPeriod_count1_monthEnd() public pure {
        // M-1: start=2025-01-31 10:00, interval=1, count=1 -> Prev=2025-01-31 00:00, Curr=2025-02-28 00:00, delta=28 days
        uint256 start = DateTime.toTimestamp(2025, 1, 31, 10, 0, 0);
        uint256 period = DistributionDateLib.calculateDistributionPeriod(start, 1, 1, true);
        uint256 expected = DateTime.toTimestamp(2025, 2, 28, 0, 0, 0) - DateTime.toTimestamp(2025, 1, 31, 0, 0, 0);
        assertEq(period, expected);
    }

    function test_calculateDistributionPeriod_count2_monthEnd() public pure {
        // M-2: start=2025-01-31 00:00, interval=1, count=2 -> Prev=2025-02-28, Curr=2025-03-31, delta=31 days
        uint256 start = DateTime.toTimestamp(2025, 1, 31, 0, 0, 0);
        uint256 period = DistributionDateLib.calculateDistributionPeriod(start, 1, 2, true);
        uint256 expected = DateTime.toTimestamp(2025, 3, 31, 0, 0, 0) - DateTime.toTimestamp(2025, 2, 28, 0, 0, 0);
        assertEq(period, expected);
    }

    function test_calculateDistributionPeriod_count3_monthEnd() public pure {
        // M-3: start=2025-01-31 00:00, interval=1, count=3 -> Prev=2025-03-31, Curr=2025-04-30, delta=30 days
        uint256 start = DateTime.toTimestamp(2025, 1, 31, 0, 0, 0);
        uint256 period = DistributionDateLib.calculateDistributionPeriod(start, 1, 3, true);
        uint256 expected = DateTime.toTimestamp(2025, 4, 30, 0, 0, 0) - DateTime.toTimestamp(2025, 3, 31, 0, 0, 0);
        assertEq(period, expected);
    }

    // Leap year (isMonthEnd = true)
    function test_calculateDistributionPeriod_leapYear_monthEnd() public pure {
        // L-1: start=2028-01-31 22:00, interval=1, count=1 -> Prev=2028-01-31 00:00, Curr=2028-02-29 00:00, delta=29 days
        uint256 start = DateTime.toTimestamp(2028, 1, 31, 22, 0, 0);
        uint256 period = DistributionDateLib.calculateDistributionPeriod(start, 1, 1, true);
        uint256 expected = DateTime.toTimestamp(2028, 2, 29, 0, 0, 0) - DateTime.toTimestamp(2028, 1, 31, 0, 0, 0);
        assertEq(period, expected);
    }

    // interval != 1 (3 months)
    function test_calculateDistributionPeriod_interval3_count2() public pure {
        // I-1: start=2025-01-10 09:00, interval=3, count=2 -> Prev=2025-04-10, Curr=2025-07-10, delta=91 days (4/10 -> 7/10)
        uint256 start = DateTime.toTimestamp(2025, 1, 10, 9, 0, 0);
        uint256 period = DistributionDateLib.calculateDistributionPeriod(start, 3, 2, false);
        uint256 expected = DateTime.toTimestamp(2025, 7, 10, 0, 0, 0) - DateTime.toTimestamp(2025, 4, 10, 0, 0, 0);
        assertEq(period, expected);
    }
}
