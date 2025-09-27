// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import { TrustContract } from "../contracts/TrustContract.sol";

/**
 * @title DeployTrustContract
 * @notice Deployment script for Trust Protocol Layer 1 - Trust Contracts
 * @dev Deploys TrustContract with proper configuration for MVP demo
 */
contract DeployTrustContract is Script {
    
    struct DeploymentConfig {
        address deployer;
        address owner;
        string network;
        bool verify;
    }

    struct DeploymentResult {
        address trustContract;
        uint256 deploymentBlock;
        uint256 gasUsed;
        bytes32 salt;
    }

    function run() external {
        DeploymentConfig memory config = getDeploymentConfig();
        
        console.log("=== Trust Protocol Layer 1 Deployment ===");
        console.log("Network:", config.network);
        console.log("Deployer:", config.deployer);
        console.log("Owner:", config.owner);
        console.log("Chain ID:", block.chainid);
        
        vm.startBroadcast(config.deployer);
        
        DeploymentResult memory result = deployTrustContract(config);
        
        vm.stopBroadcast();
        
        logDeploymentResults(config, result);
        saveDeploymentArtifacts(config, result);
        
        if (config.verify) {
            console.log("\nTo verify contract, run:");
            console.log("forge verify-contract", result.trustContract, "TrustContract");
        }
    }

    function deployTrustContract(DeploymentConfig memory config) internal returns (DeploymentResult memory) {
        console.log("\n--- Deploying TrustContract ---");
        
        uint256 startGas = gasleft();
        uint256 startBlock = block.number;
        
        // Use CREATE2 for deterministic address
        bytes32 salt = keccak256(abi.encodePacked("TrustProtocol_Layer1_", config.network, "_v1.0.0"));
        
        TrustContract trustContract = new TrustContract{salt: salt}(config.owner);
        
        uint256 gasUsed = startGas - gasleft();
        
        console.log("TrustContract deployed at:", address(trustContract));
        console.log("Owner set to:", config.owner);
        console.log("Gas used:", gasUsed);
        console.log("Salt:", vm.toString(salt));
        
        // Verify deployment
        require(address(trustContract) != address(0), "Deployment failed");
        require(trustContract.owner() == config.owner, "Owner not set correctly");
        
        return DeploymentResult({
            trustContract: address(trustContract),
            deploymentBlock: startBlock,
            gasUsed: gasUsed,
            salt: salt
        });
    }

    function getDeploymentConfig() internal view returns (DeploymentConfig memory) {
        uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0));
        require(deployerPrivateKey != 0, "PRIVATE_KEY environment variable not set");
        
        address deployer = vm.addr(deployerPrivateKey);
        address owner = vm.envOr("OWNER_ADDRESS", deployer);
        string memory network = vm.envOr("NETWORK", string("localhost"));
        bool verify = vm.envOr("VERIFY", false);
        
        return DeploymentConfig({
            deployer: deployer,
            owner: owner,
            network: network,
            verify: verify
        });
    }

    function logDeploymentResults(DeploymentConfig memory config, DeploymentResult memory result) internal pure {
        console.log("\n=== Deployment Complete ===");
        console.log("TrustContract Address:", result.trustContract);
        console.log("Deployment Block:", result.deploymentBlock);
        console.log("Gas Used:", result.gasUsed);
        console.log("Owner:", config.owner);
        
        console.log("\n--- Contract Configuration ---");
        console.log("DAILY_YIELD_BPS:", 100, "(1% per day)");
        
        console.log("\n--- Next Steps ---");
        console.log("1. Update frontend with new contract address");
        console.log("2. Test contract creation flow");
        console.log("3. Verify automatic yield accrual");
        console.log("4. Test defect/exit mechanisms");
        console.log("5. Deploy Layer 2 (Trust Scoring)");
    }

    function saveDeploymentArtifacts(DeploymentConfig memory config, DeploymentResult memory result) internal {
        // Create deployment info for Scaffold-ETH frontend
        string memory deploymentJson = string(abi.encodePacked(
            '{',
                '"chainId":', vm.toString(block.chainid), ',',
                '"name":"', config.network, '",',
                '"contracts":{',
                    '"TrustContract":{',
                        '"address":"', vm.toString(result.trustContract), '",',
                        '"abi":"TrustContract"',
                    '}',
                '},',
                '"timestamp":', vm.toString(block.timestamp), ',',
                '"block":', vm.toString(result.deploymentBlock), ',',
                '"gasUsed":', vm.toString(result.gasUsed),
            '}'
        ));
        
        string memory filename = string(abi.encodePacked(
            "deployments/",
            vm.toString(block.chainid),
            ".json"
        ));
        
        vm.writeFile(filename, deploymentJson);
        console.log("Deployment artifacts saved to:", filename);
    }
}