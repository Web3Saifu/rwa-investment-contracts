// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.28;

import {MCScript} from "@mc-devkit/Flattened.sol";
import {Automation} from "bundle/periphery/Automation.sol";

contract DeployAutomationScript is MCScript {
    function run() public startBroadcastWith("DEPLOYER_PRIV_KEY") {
        string memory _name = _chainIdConcat("INVESTMENT_PROXY_ADDR_");
        address investment = vm.envAddress(_name);
        address forwarder = vm.envAddress(_chainIdConcat("FORWARDER_ADDR_"));
        address _automation = address(new Automation(investment, forwarder));
        _saveAddrToEnv(_automation, "AUTOMATION_ADDR_");
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
