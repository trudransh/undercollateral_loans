// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import { TrustContract } from "../contracts/TrustContract.sol";

/**
 * @title Deploy
 * @notice Main deployment script for Scaffold-ETH 2
 * @dev Deploys TrustContract for the Trust Protocol
 */
contract Deploy is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0));
        if (deployerPrivateKey == 0) {
            console.log("PRIVATE_KEY not found, using default anvil account");
            deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        }

        address deployer = vm.addr(deployerPrivateKey);
        console.log("Deploying with account:", deployer);
        console.log("Account balance:", deployer.balance);

        vm.startBroadcast(deployer);

        // Deploy TrustContract with deployer as owner
        TrustContract trustContract = new TrustContract(deployer);
        console.log("TrustContract deployed at:", address(trustContract));

        vm.stopBroadcast();
    }
}