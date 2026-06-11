// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {IInvestmentFunctions} from "bundle/investment/interfaces/IInvestmentFunctions.sol";
import {IInvestmentErrors} from "bundle/investment/interfaces/IInvestmentErrors.sol";
import {IInvestmentEvents} from "bundle/investment/interfaces/IInvestmentEvents.sol";

/**
 * @title Investment Interface v0.1.0
 * @custom:version schema:0.1.0
 * @custom:version functions:0.1.0
 * @custom:version errors:0.1.0
 * @custom:version events:0.1.0
 */
interface IInvestment is IInvestmentFunctions, IInvestmentErrors, IInvestmentEvents {}
