// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

interface IAutomation {
    /**
     * @notice Types of actions
     */
    enum ActionType {
        DistributeYield,
        Maturity
    }

    /**
     * @notice Thrown when an address that is not registered as an forwarder attempts forwarder operations
     */
    error NotForwarder(address sender);
}
