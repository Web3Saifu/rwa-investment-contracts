// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {MCTest} from "@mc-devkit/Flattened.sol";
import {RegisterProduct} from "bundle/investment/functions/onlyWhiteLists/RegisterProduct.sol";
import {DistributionDateLib} from "bundle/investment/utils/DistributionDateLib.sol";
import {Schema} from "bundle/investment/storage/Schema.sol";
import {Storage} from "bundle/investment/storage/Storage.sol";

contract AUDITORNormalizedScheduleBypassTest is MCTest {
    function setUp() public {
        _use(RegisterProduct.registerProduct.selector, address(new RegisterProduct()));
        Storage.WhiteListsState().admins.push(address(this));
        vm.warp(1_735_603_200); // 2024-12-31 00:00:00 UTC
    }

    function test_registrationAllowsMaturityBeforeOperationAndDistribution() public {
        uint256 day = 1_735_689_600; // 2025-01-01 00:00:00 UTC
        Schema.RegisterProductArgs memory args = Schema.RegisterProductArgs({
            productId: 1,
            offeringAmount: 1_000_000e6,
            minInvestment: 1_000e6,
            offeringEndDate: day + 30 minutes,
            maturityDate: day + 1 hours,
            expectedYield: 500,
            operationStartDate: day + 22 hours,
            distributionStartDate: day + 23 hours,
            totalDistributionCount: 1,
            distributionInterval: 0,
            baseTokenURI: "ipfs://audit",
            requiredTier: 0
        });

        RegisterProduct(target).registerProduct(args);

        Schema.Product memory product = Storage.ProductsState().products[1];
        uint256 effectiveDistributionDate = DistributionDateLib.calculateNextDistributionDate(
            product.distributionStartDate, product.distributionInterval, 0, product.isMonthEnd
        );

        assertLt(product.maturityDate, product.operationStartDate);
        assertLt(product.maturityDate, product.distributionStartDate);
        assertLe(effectiveDistributionDate, product.maturityDate);
    }
}
