// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {MCDevKit} from "@mc-devkit/Flattened.sol";
// Interface
import {InvestmentFacade} from "bundle/investment/interfaces/InvestmentFacade.sol";
// Functions
import {Initialize} from "bundle/investment/functions/initializer/Initialize.sol";
import {RegisterProduct} from "bundle/investment/functions/onlyWhiteLists/RegisterProduct.sol";
import {Invest} from "bundle/investment/functions/Invest.sol";
import {MintNFT} from "bundle/investment/functions/onlyMinters/MintNFT.sol";
import {Withdraw} from "bundle/investment/functions/onlyWhiteLists/Withdraw.sol";
import {Deposit} from "bundle/investment/functions/onlyWhiteLists/Deposit.sol";
import {DistributeYield} from "bundle/investment/functions/onlyWhiteLists/DistributeYield.sol";
import {Maturity} from "bundle/investment/functions/onlyWhiteLists/Maturity.sol";
import {SetTier} from "bundle/investment/functions/onlyWhiteLists/SetTier.sol";
import {ControlAdmin} from "bundle/investment/functions/onlyOwner/ControlAdmin.sol";
import {ControlMinter} from "bundle/investment/functions/onlyOwner/ControlMinter.sol";
import {Claim} from "bundle/investment/functions/Claim.sol";
import {Getter} from "bundle/investment/functions/Getter.sol";

/**
 * @title InvestmentDeployer
 * @dev Library for deploying and initializing Investment contracts
 */
library InvestmentDeployer {
    string internal constant BUNDLE_NAME = "Investment";

    /**
     * @dev Deploys the Investment contractenvAddress
     * @param mc MCDevKit storage reference
     * @return investment Address of the deployed Investment proxy contract
     */
    function deployInvestment(
        MCDevKit storage mc,
        address[] memory admins,
        address[] memory minters,
        address usdtAddress,
        address safeMultisigWallet
    ) internal returns (address investment) {
        mc.init(BUNDLE_NAME);
        _useMainFunctions(mc);
        _useClaimFunctions(mc);
        _useSetTierFunctions(mc);
        _useControlAdminFunctions(mc);
        _useControlMinterFunctions(mc);
        _useGetterFunctions(mc);
        mc.useFacade(address(new InvestmentFacade()));
        return mc.deploy(abi.encodeCall(Initialize.initialize, (admins, minters, usdtAddress, safeMultisigWallet)))
            .toProxyAddress();
    }

    //=============================
    //      Helper Functions
    //=============================

    function _useMainFunctions(MCDevKit storage mc) internal {
        mc.use("Initialize", Initialize.initialize.selector, address(new Initialize()));
        mc.use("RegisterProduct", RegisterProduct.registerProduct.selector, address(new RegisterProduct()));
        mc.use("Invest", Invest.invest.selector, address(new Invest()));
        mc.use("MintNFT", MintNFT.mintNFT.selector, address(new MintNFT()));
        mc.use("Withdraw", Withdraw.withdraw.selector, address(new Withdraw()));
        mc.use("Deposit", Deposit.deposit.selector, address(new Deposit()));
        mc.use("DistributeYield", DistributeYield.distributeYield.selector, address(new DistributeYield()));
        mc.use("Maturity", Maturity.maturity.selector, address(new Maturity()));
    }

    function _useClaimFunctions(MCDevKit storage mc) internal {
        address claim = address(new Claim());
        mc.use("claimYield", Claim.claimYield.selector, claim);
        mc.use("claimPrincipal", Claim.claimPrincipal.selector, claim);
    }

    function _useSetTierFunctions(MCDevKit storage mc) internal {
        address setTier = address(new SetTier());
        mc.use("setProductRequiredTier", SetTier.setProductRequiredTier.selector, setTier);
        mc.use("setAllowedByTierAddress", SetTier.setAllowedByTierAddress.selector, setTier);
        mc.use("setAllowedByTierId", SetTier.setAllowedByTierId.selector, setTier);
    }

    function _useControlAdminFunctions(MCDevKit storage mc) internal {
        address controlAdmin = address(new ControlAdmin());
        mc.use("addAdmin", ControlAdmin.addAdmin.selector, controlAdmin);
        mc.use("deleteAdmin", ControlAdmin.deleteAdmin.selector, controlAdmin);
    }

    function _useControlMinterFunctions(MCDevKit storage mc) internal {
        address controlMinter = address(new ControlMinter());
        mc.use("addMinter", ControlMinter.addMinter.selector, controlMinter);
        mc.use("deleteMinter", ControlMinter.deleteMinter.selector, controlMinter);
    }

    function _useGetterFunctions(MCDevKit storage mc) internal {
        address getter = address(new Getter());
        mc.use("getProduct", Getter.getProduct.selector, getter);
        mc.use("getAllProducts", Getter.getAllProducts.selector, getter);
        mc.use("getActiveProducts", Getter.getActiveProducts.selector, getter);
        mc.use("getAdminList", Getter.getAdminList.selector, getter);
        mc.use("simulatePeriodYield", Getter.simulatePeriodYield.selector, getter);
        mc.use("simulateTotalYield", Getter.simulateTotalYield.selector, getter);
        mc.use("getDistributionDates", Getter.getDistributionDates.selector, getter);
        mc.use("simulateIndividualPeriodYield", Getter.simulateIndividualPeriodYield.selector, getter);
        mc.use("simulateIndividualTotalYield", Getter.simulateIndividualTotalYield.selector, getter);
        mc.use("getAllowedByTierAddress", Getter.getAllowedByTierAddress.selector, getter);
        mc.use("getAllowedByTierId", Getter.getAllowedByTierId.selector, getter);
        mc.use("getUnclaimedYield", Getter.getUnclaimedYield.selector, getter);
        mc.use("getUnclaimedPrincipal", Getter.getUnclaimedPrincipal.selector, getter);
        mc.use("getClaimableYieldSlots", Getter.getClaimableYieldSlots.selector, getter);
        mc.use("getClaimableForToken", Getter.getClaimableForToken.selector, getter);
    }
}
