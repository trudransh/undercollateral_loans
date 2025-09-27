// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console2 as console} from "forge-std/console2.sol";
import {TrustContract} from "../contracts/TrustContract.sol";
import {TrustScore} from "../contracts/TrustScore.sol";
import {LendingPool} from "../contracts/LendingPool.sol";

contract DeployCeloSepolia is Script {
    struct Deployed {
        address trustContract;
        address trustScore;
        address lendingPool;
        bytes32 authTx;
    }

    function run() external returns (Deployed memory d) {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(pk);
        console.log("Deployer:", deployer);

        vm.startBroadcast(pk);

        TrustContract trust = new TrustContract();
        console.log("TrustContract:", address(trust));

        TrustScore score = new TrustScore(address(trust));
        console.log("TrustScore:", address(score));

        LendingPool pool = new LendingPool(address(trust), address(score));
        console.log("LendingPool:", address(pool));

        // authorize lender in TrustContract (owner is deployer)
        trust.addAuthorizedLender(address(pool));
        console.log("Authorized lender:", address(pool));

        vm.stopBroadcast();

        d = Deployed({
            trustContract: address(trust),
            trustScore: address(score),
            lendingPool: address(pool),
            authTx: bytes32(0)
        });
    }
}
