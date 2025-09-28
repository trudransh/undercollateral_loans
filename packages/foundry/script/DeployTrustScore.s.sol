// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {TrustScore} from "../contracts/TrustScore.sol";

/**
 * @title DeployTrustScore
 * @notice Individual deployment script for TrustScore
 * @dev Requires TrustContract address as constructor parameter
 */
contract DeployTrustScore is Script {
    
    function run() external returns (address) {
        uint256 privateKey = vm.envOr("PRIVATE_KEY", uint256(0xb1db46dc1e869bfbb6a33ed21a36f0f9af954c5f7fcec7980044a7de756b14b4));
        
        // Read TrustContract address from environment or file
        address trustContractAddress = vm.envOr("TRUST_CONTRACT_ADDRESS", address(0));
        
        if (trustContractAddress == address(0)) {
            // Try to read from deployment file
            try vm.readFile("deployments/trust_contract_address.txt") returns (string memory content) {
                // Parse the content to extract address
                // For simplicity, assuming the file contains just the address
                console.log("Reading TrustContract address from file...");
            } catch {
                revert("TrustContract address not found. Please set TRUST_CONTRACT_ADDRESS env var or deploy TrustContract first");
            }
        }
        
        require(trustContractAddress != address(0), "Invalid TrustContract address");
        
        console.log("=== DEPLOYING TRUST SCORE ===");
        console.log("TrustContract address:", trustContractAddress);
        
        vm.startBroadcast(privateKey);
        
        TrustScore trustScore = new TrustScore(trustContractAddress);
        address contractAddress = address(trustScore);
        
        vm.stopBroadcast();
        
        console.log("TrustScore deployed at:", contractAddress);
        
        // Save to file
        string memory info = string.concat(
            "TRUST_SCORE=", vm.toString(contractAddress), "\n"
        );
        vm.writeFile("deployments/trust_score_address.txt", info);
        
        return contractAddress;
    }
}