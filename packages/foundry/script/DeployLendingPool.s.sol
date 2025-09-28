// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {LendingPool} from "../contracts/LendingPool.sol";

/**
 * @title DeployLendingPool
 * @notice Individual deployment script for LendingPool
 * @dev Requires both TrustContract and TrustScore addresses as constructor parameters
 */
contract DeployLendingPool is Script {
    
    function run() external returns (address) {
        uint256 privateKey = vm.envOr("PRIVATE_KEY", uint256(0xb1db46dc1e869bfbb6a33ed21a36f0f9af954c5f7fcec7980044a7de756b14b4));
        
        // Read contract addresses from environment
        address trustContractAddress = vm.envOr("TRUST_CONTRACT_ADDRESS", address(0));
        address trustScoreAddress = vm.envOr("TRUST_SCORE_ADDRESS", address(0));
        
        require(trustContractAddress != address(0), "TrustContract address required");
        require(trustScoreAddress != address(0), "TrustScore address required");
        
        console.log("=== DEPLOYING LENDING POOL ===");
        console.log("TrustContract address:", trustContractAddress);
        console.log("TrustScore address:", trustScoreAddress);
        
        vm.startBroadcast(privateKey);
        
        LendingPool lendingPool = new LendingPool(trustContractAddress, trustScoreAddress);
        address contractAddress = address(lendingPool);
        
        vm.stopBroadcast();
        
        console.log("LendingPool deployed at:", contractAddress);
        
        // Save to file
        string memory info = string.concat(
            "LENDING_POOL=", vm.toString(contractAddress), "\n"
        );
        vm.writeFile("deployments/lending_pool_address.txt", info);
        
        return contractAddress;
    }
}