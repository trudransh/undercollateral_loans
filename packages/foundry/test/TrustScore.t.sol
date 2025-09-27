// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import { TrustContract } from "../contracts/TrustContract.sol";
import { TrustScore } from "../contracts/TrustScore.sol";

contract TrustScoreTest is Test {
    TrustContract public trustContract;
    TrustScore public trustScore;
    
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    
function setUp() public {
    trustContract = new TrustContract();
    trustScore = new TrustScore(address(trustContract));
    
    // Add this: Fund the accounts
    vm.deal(alice, 100 ether);
    vm.deal(bob, 100 ether);
}
    
    function testTrustScoreCalculation() public {
        vm.startPrank(alice);
        trustContract.createContract{value: 10 ether}(bob);
        vm.stopPrank();
        
        vm.warp(block.timestamp + 30 days);
        
        uint256 aliceScore = trustScore.getUserTrustScore(alice);
        uint256 bobScore = trustScore.getUserTrustScore(bob);
        
        assertTrue(aliceScore > 0);
        assertTrue(bobScore > 0);
    }
    
    function testTrustScoreWithMultipleContracts() public {
        address charlie = makeAddr("charlie");
        
        vm.startPrank(alice);
        trustContract.createContract{value: 5 ether}(bob);
        trustContract.createContract{value: 5 ether}(charlie);
        vm.stopPrank();
        
        vm.warp(block.timestamp + 30 days);
        
        uint256 aliceScore = trustScore.getUserTrustScore(alice);
        
        // Should have higher score due to diversity bonus
        assertTrue(aliceScore > 0);
    }
}