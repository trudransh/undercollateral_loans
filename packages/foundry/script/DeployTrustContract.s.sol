// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {TrustContract} from "../contracts/TrustContract.sol";

/**
 * @title DeployTrustContract
 * @notice Individual deployment script for TrustContract only
 */
contract DeployTrustContract is Script {
    
    function run() external returns (address) {
        uint256 privateKey = vm.envOr("PRIVATE_KEY", uint256(0xb1db46dc1e869bfbb6a33ed21a36f0f9af954c5f7fcec7980044a7de756b14b4));
        address deployer = vm.addr(privateKey);
        
        console.log("=== DEPLOYING TRUST CONTRACT ===");
        console.log("Deployer:", deployer);
        console.log("Balance:", deployer.balance);
        
        vm.startBroadcast(privateKey);
        
        TrustContract trustContract = new TrustContract();
        address contractAddress = address(trustContract);
        
        vm.stopBroadcast();
        
        console.log("TrustContract deployed at:", contractAddress);
        console.log("Gas used for deployment");
        
        // Save to file
        string memory info = string.concat(
            "TRUST_CONTRACT=", vm.toString(contractAddress), "\n"
        );
        vm.writeFile("deployments/trust_contract_address.txt", info);
        
        return contractAddress;
    }
}