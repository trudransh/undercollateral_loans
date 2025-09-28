// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {TrustContract} from "../contracts/TrustContract.sol";
import {TrustScore} from "../contracts/TrustScore.sol";
import {LendingPool} from "../contracts/LendingPool.sol";

/**
 * @title DeployTrustProtocol
 * @notice Complete deployment script for Trust Protocol on Celo Sepolia
 * @dev Deploys all contracts in the correct order with proper dependencies
 */
contract DeployTrustProtocol is Script {
    
    // Deployment addresses will be stored here
    address public trustContractAddress;
    address public trustScoreAddress;
    address public lendingPoolAddress;
    
    // Contract instances
    TrustContract public trustContract;
    TrustScore public trustScore;
    LendingPool public lendingPool;
    
    function run() external {
        // Read private key from environment or use provided key
        uint256 privateKey = vm.envOr("PRIVATE_KEY", uint256(0xb1db46dc1e869bfbb6a33ed21a36f0f9af954c5f7fcec7980044a7de756b14b4));
        address deployer = vm.addr(privateKey);
        
        console.log("=== TRUST PROTOCOL DEPLOYMENT ===");
        console.log("Deployer address:", deployer);
        console.log("Deployer balance:", deployer.balance);
        console.log("Chain ID:", block.chainid);
        
        // Start broadcasting transactions
        vm.startBroadcast(privateKey);
        
        // Step 1: Deploy TrustContract (no dependencies)
        console.log("\n1. Deploying TrustContract...");
        trustContract = new TrustContract();
        trustContractAddress = address(trustContract);
        console.log("TrustContract deployed at:", trustContractAddress);
        
        // Step 2: Deploy TrustScore (depends on TrustContract)
        console.log("\n2. Deploying TrustScore...");
        trustScore = new TrustScore(trustContractAddress);
        trustScoreAddress = address(trustScore);
        console.log("TrustScore deployed at:", trustScoreAddress);
        
        // Step 3: Deploy LendingPool (depends on both TrustContract and TrustScore)
        console.log("\n3. Deploying LendingPool...");
        lendingPool = new LendingPool(trustContractAddress, trustScoreAddress);
        lendingPoolAddress = address(lendingPool);
        console.log("LendingPool deployed at:", lendingPoolAddress);
        
        // Step 4: Configure contracts
        console.log("\n4. Configuring contracts...");
        
        // Authorize LendingPool as a lender in TrustContract
        trustContract.addAuthorizedLender(lendingPoolAddress);
        console.log("LendingPool authorized as lender in TrustContract");
        
        vm.stopBroadcast();
        
        // Step 5: Verification info
        console.log("=== DEPLOYMENT SUMMARY ===");
        console.log("TrustContract:", trustContractAddress);
        console.log("TrustScore:", trustScoreAddress);
        console.log("LendingPool:", lendingPoolAddress);
        console.log("=== VERIFICATION COMMANDS ===");
        console.log("Use verify_contracts.sh script for verification");
        
        // Save deployment addresses to file
        _saveDeploymentAddresses();
    }
    
    function _saveDeploymentAddresses() internal {
        string memory deploymentInfo = string.concat(
            "# Trust Protocol Deployment on Celo Sepolia\n",
            "TRUST_CONTRACT=", vm.toString(trustContractAddress), "\n",
            "TRUST_SCORE=", vm.toString(trustScoreAddress), "\n",
            "LENDING_POOL=", vm.toString(lendingPoolAddress), "\n",
            "CHAIN_ID=11142220\n",
            "EXPLORER=https://celo-sepolia.blockscout.com/\n"
        );
        
        vm.writeFile("deployments/celo_sepolia_addresses.txt", deploymentInfo);
        console.log("\nDeployment addresses saved to: deployments/celo_sepolia_addresses.txt");
    }
}