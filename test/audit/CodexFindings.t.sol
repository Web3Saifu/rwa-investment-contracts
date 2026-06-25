// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {CalculateYieldLib} from "bundle/investment/utils/CalculateYieldLib.sol";

contract CodexFindingsTest is Test {
    uint256 internal constant MIN_INVESTMENT = 250_000_000; // 250 USDT, 6 decimals

    function _periodTolerance(uint256 nftCount) internal pure returns (uint256) {
        if (nftCount % 50 == 0) {
            return nftCount + (nftCount / 50);
        }
        return nftCount + 1 + (nftCount / 50);
    }

    function _periodToleranceRemainder(uint256 distributedTokenId, uint256 periodTolerance)
        internal
        pure
        returns (uint256)
    {
        uint256 alreadyBatchCounted = distributedTokenId / 50;
        return periodTolerance - (50 * alreadyBatchCounted) + alreadyBatchCounted;
    }

    function test_realisticMonthlyMinimumConstructionStillUnderflowsPrecheck() external pure {
        uint256 nftCount = 55_051;
        uint256 processedTokenId = 55_050;
        uint256 expectedYield = 13; // 0.13% APY, inside the triage-stated intended range.
        uint256 period = 28 days; // monthly Jan 31 -> Feb 28 style period.
        uint256 raisedAmount = nftCount * MIN_INVESTMENT;

        uint256 periodYield = CalculateYieldLib.calculatePeriodYield(raisedAmount, expectedYield, period);
        uint256 individualYield =
            CalculateYieldLib.calculateIndividualPeriodYield(periodYield, MIN_INVESTMENT, raisedAmount);
        uint256 distributedYieldPerCount = processedTokenId * individualYield;
        uint256 toleranceRemainder = _periodToleranceRemainder(processedTokenId, _periodTolerance(nftCount));

        assertEq(periodYield, 1_372_504_384);
        assertEq(individualYield, 24_932);
        assertEq(distributedYieldPerCount, 1_372_506_600);
        assertEq(toleranceRemainder, 2_204);

        assertGt(distributedYieldPerCount, periodYield + toleranceRemainder);
    }
}
