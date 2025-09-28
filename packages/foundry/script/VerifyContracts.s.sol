// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

/**
 * @title VerifyContracts
 * @notice Script to verify all deployed contracts on Celo Sepolia
 */
contract VerifyContracts is Script {
    
    function run() external {
        // Read deployment addresses from environment
        address trustContractAddress = vm.envAddress("TRUST_CONTRACT_ADDRESS");
        address trustScoreAddress = vm.envAddress("TRUST_SCORE_ADDRESS");
        address lendingPoolAddress = vm.envAddress("LENDING_POOL_ADDRESS");
        
        console.log("=== VERIFYING CONTRACTS ON CELO SEPOLIA ===");
        console.log("TrustContract:", trustContractAddress);
        console.log("TrustScore:", trustScoreAddress);
        console.log("LendingPool:", lendingPoolAddress);
        
        // Generate verification commands
        console.log("=== VERIFICATION COMMANDS ===");
        console.log("TrustContract:", trustContractAddress);
        console.log("TrustScore:", trustScoreAddress);
        console.log("LendingPool:", lendingPoolAddress);
        console.log("Use verify_contracts.sh script for verification");
        
        // Save verification commands to file
        string memory verificationScript = string.concat(
            "#!/bin/bash\n",
            "# Trust Protocol Contract Verification on Celo Sepolia\n\n",
            "echo \"Verifying TrustContract...\"\n",
            "forge verify-contract \\\n",
            "  --chain celo_sepolia \\\n",
            "  --compiler-version 0.8.20 \\\n",
            "  ", vm.toString(trustContractAddress), " \\\n",
            "  contracts/TrustContract.sol:TrustContract\n\n",
            "echo \"Verifying TrustScore...\"\n",
            "forge verify-contract \\\n",
            "  --chain celo_sepolia \\\n",
            "  --compiler-version 0.8.20 \\\n",
            "  --constructor-args $(cast abi-encode \"constructor(address)\" ", vm.toString(trustContractAddress), ") \\\n",
            "  ", vm.toString(trustScoreAddress), " \\\n",
            "  contracts/TrustScore.sol:TrustScore\n\n",
            "echo \"Verifying LendingPool...\"\n",
            "forge verify-contract \\\n",
            "  --chain celo_sepolia \\\n",
            "  --compiler-version 0.8.20 \\\n",
            "  --constructor-args $(cast abi-encode \"constructor(address,address)\" ", vm.toString(trustContractAddress), " ", vm.toString(trustScoreAddress), ") \\\n",
            "  ", vm.toString(lendingPoolAddress), " \\\n",
            "  contracts/LendingPool.sol:LendingPool\n"
        );
        
        vm.writeFile("verify_contracts.sh", verificationScript);
        console.log("\nVerification script saved to: verify_contracts.sh");
        console.log("Make it executable with: chmod +x verify_contracts.sh");
    }
}