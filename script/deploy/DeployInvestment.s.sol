// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {MCScript} from "@mc-devkit/Flattened.sol";
import {Dictionary} from "@ucs.mc/dictionary/Dictionary.sol";
import {InvestmentDeployer} from "./InvestmentDeployer.sol";

contract DeployInvestmentScript is MCScript {
    function run() public startBroadcastWith("DEPLOYER_PRIV_KEY") {
        address[] memory admins = vm.envAddress("ADMINS_ADDR", ",");
        address[] memory minters = vm.envAddress("MINTERS_ADDR", ",");
        address usdtAddress = vm.envAddress(_chainIdConcat("USDT_ADDR_"));
        address safeMultisigWallet = vm.envAddress(_chainIdConcat("SAFE_MULTISIG_WALLET_ADDR_"));
        address _investment = InvestmentDeployer.deployInvestment(mc, admins, minters, usdtAddress, safeMultisigWallet);
        _saveAddrToEnv(_investment, "INVESTMENT_PROXY_ADDR_");

        // change Dictionary Owner
        Dictionary(mc.toDictionaryAddress()).transferOwnership(safeMultisigWallet);
    }

    //=============================
    //      Helper Functions
    //=============================

    /// @notice Concatenates chain ID to environment variable key
    /// @param envKeyBase Base environment variable key to concatenate with
    /// @return string The concatenated environment variable key with chain ID
    /// @dev Uses assembly to get the chain ID
    function _chainIdConcat(string memory envKeyBase) internal view returns (string memory) {
        uint256 _chainId;
        assembly {
            _chainId := chainid()
        }
        string memory _chainIdString = vm.toString(_chainId);

        return string.concat(envKeyBase, _chainIdString);
    }
}
