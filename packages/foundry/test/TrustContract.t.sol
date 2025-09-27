// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import { TrustContract } from "../contracts/TrustContract.sol";
import { ITrustContract } from "../contracts/ITrustContract.sol";

/**
 * @title TrustContractTest
 * @notice Comprehensive test suite for Trust Protocol Layer 1
 * @dev Tests all core functionality, edge cases, and game theory mechanics
 */
contract TrustContractTest is Test {
    TrustContract public trustContract;
    
    
    address public owner = address(0x1);
    address public alice = address(0xA11cE);  
    address public bob = address(0xB0B);        
    address public charlie = address(0xCA112);  
    address public attacker = address(0xBAD);   

    uint256 constant INITIAL_BALANCE = 100 ether;
    uint256 constant ALICE_STAKE = 10 ether;
    uint256 constant BOB_STAKE = 5 ether;
    uint256 constant DAILY_YIELD_BPS = 100; 
    
    event ContractCreated(bytes32 indexed key, address indexed a0, address indexed a1, uint256 initialStake);
    event ContractActivated(bytes32 indexed key, uint128 stake0, uint128 stake1);
    event StakeAdded(bytes32 indexed key, address indexed by, uint256 amount);
    event YieldAccrued(bytes32 indexed key, uint256 yieldAmount, uint256 totalYield);
    event Defected(bytes32 indexed key, address indexed defector, uint256 stolen, uint256 penalty);
    event Exited(bytes32 indexed key, address indexed user, uint256 penalty);

    function setUp() public {
        
        trustContract = new TrustContract(owner);
        
        vm.deal(alice, INITIAL_BALANCE);
        vm.deal(bob, INITIAL_BALANCE);
        vm.deal(charlie, INITIAL_BALANCE);
        vm.deal(attacker, INITIAL_BALANCE);
        
        vm.label(owner, "Owner");
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(charlie, "Charlie");
        vm.label(attacker, "Attacker");
        vm.label(address(trustContract), "TrustContract");
    }

    function testCreateContract() public {
        bytes32 expectedKey = trustContract.getContractKey(alice, bob);
        
        vm.expectEmit(true, true, true, true);
        emit ContractCreated(expectedKey, alice, bob, ALICE_STAKE);
        
        vm.prank(alice);
        trustContract.createContract{value: ALICE_STAKE}(bob);
        
        ITrustContract.contractView memory contractData = trustContract.getContractDetails(alice, bob);
        
        assertEq(contractData.addr0, alice);
        assertEq(contractData.addr1, bob);
        assertEq(contractData.stake0, ALICE_STAKE);
        assertEq(contractData.stake1, 0);
        assertFalse(contractData.isActive);
        assertFalse(contractData.isFrozen);
        assertGt(contractData.createdAt, 0);
    }

    function testCreateContractRevertsOnZeroStake() public {
        vm.prank(alice);
        vm.expectRevert("Zero stake");
        trustContract.createContract{value: 0}(bob);
    }

    function testCreateContractRevertsOnSelfPartner() public {
        vm.prank(alice);
        vm.expectRevert("Invalid partner");
        trustContract.createContract{value: ALICE_STAKE}(alice);
    }

    function testCreateContractRevertsOnZeroAddressPartner() public {
        vm.prank(alice);
        vm.expectRevert("Invalid partner");
        trustContract.createContract{value: ALICE_STAKE}(address(0));
    }

    function testCreateContractRevertsOnDuplicate() public {
        vm.prank(alice);
        trustContract.createContract{value: ALICE_STAKE}(bob);
        
        vm.prank(alice);
        vm.expectRevert("Contract exists");
        trustContract.createContract{value: ALICE_STAKE}(bob);
    }


    function testAddStakeActivatesContract() public {

        vm.prank(alice);
        trustContract.createContract{value: ALICE_STAKE}(bob);
        
        bytes32 key = trustContract.getContractKey(alice, bob);

        vm.expectEmit(true, true, true, true);
        emit ContractActivated(key, uint128(ALICE_STAKE), uint128(BOB_STAKE));

        vm.prank(bob);
        trustContract.addStake{value: BOB_STAKE}(alice);
        
        ITrustContract.contractView memory contractData = trustContract.getContractDetails(alice, bob);
        
        assertTrue(contractData.isActive);
        assertEq(contractData.stake0, ALICE_STAKE);
        assertEq(contractData.stake1, BOB_STAKE);
        assertGt(contractData.lastYieldUpdate, 0);
    }

    function testAddStakeRevertsOnAlreadyStaked() public {
        vm.prank(alice);
        trustContract.createContract{value: ALICE_STAKE}(bob);
        
        vm.prank(alice);
        vm.expectRevert("Already staked");
        trustContract.addStake{value: 1 ether}(bob);
    }

    function testAutomaticYieldAccrual() public {

        _createAndActivateContract();
        

        vm.warp(block.timestamp + 1 days);
        
        ITrustContract.contractView memory contractData = trustContract.getContractDetails(alice, bob);
        

        uint256 expectedYield = (ALICE_STAKE + BOB_STAKE) * DAILY_YIELD_BPS / 10_000;
        assertEq(contractData.accruedYield, expectedYield);
    }

    function testYieldAccrualOverMultipleDays() public {
        _createAndActivateContract();
        

        vm.warp(block.timestamp + 5 days);
        
        ITrustContract.contractView memory contractData = trustContract.getContractDetails(alice, bob);
        

        uint256 expectedYield = (ALICE_STAKE + BOB_STAKE) * DAILY_YIELD_BPS * 5 / 10_000;
        assertEq(contractData.accruedYield, expectedYield);
    }

    function testProjectedYield() public {
        _createAndActivateContract();
        

        vm.warp(block.timestamp + 1 days);
        
        
        uint256 projectedYield = trustContract.getProjectedYield(alice, bob, 10);
        
        
        uint256 currentYield = (ALICE_STAKE + BOB_STAKE) * DAILY_YIELD_BPS / 10_000;
        uint256 futureYield = (ALICE_STAKE + BOB_STAKE) * DAILY_YIELD_BPS * 10 / 10_000;
        uint256 expectedTotal = currentYield + futureYield;
        
        assertEq(projectedYield, expectedTotal);
    }

  

    function testDefectStealsAllFunds() public {
        _createAndActivateContract();
        

        vm.warp(block.timestamp + 2 days);
        
        uint256 aliceBalanceBefore = alice.balance;
        uint256 totalFunds = ALICE_STAKE + BOB_STAKE + ((ALICE_STAKE + BOB_STAKE) * DAILY_YIELD_BPS * 2 / 10_000);
        
        vm.prank(alice);
        trustContract.defect(bob);
        
        assertEq(alice.balance, aliceBalanceBefore + totalFunds);
        
        ITrustContract.contractView memory contractData = trustContract.getContractDetails(alice, bob);
        assertFalse(contractData.isActive);
        assertEq(contractData.stake0, 0);
        assertEq(contractData.stake1, 0);
        assertEq(contractData.accruedYield, 0);
    }

    function testDefectRevertsOnInactiveContract() public {
        vm.prank(alice);
        vm.expectRevert("Invalid state");
        trustContract.defect(bob);
    }

    function testDefectRevertsOnFrozenContract() public {
        _createAndActivateContract();
        
        vm.prank(owner);
        trustContract.freezeContract(alice, bob, true);
        
        vm.prank(alice);
        vm.expectRevert("Invalid state");
        trustContract.defect(bob);
    }

    function testDefectRevertsOnNonParticipant() public {
        _createAndActivateContract();
        
        vm.prank(charlie);
        vm.expectRevert("Not participant");
        trustContract.defect(alice);
    }

  

    function testExitDistributesFairly() public {
        _createAndActivateContract();
        
        vm.warp(block.timestamp + 1 days);
        
        uint256 aliceBalanceBefore = alice.balance;
        uint256 bobBalanceBefore = bob.balance;
        
        vm.prank(alice);
        trustContract.exit(bob);
        
        uint256 totalYield = (ALICE_STAKE + BOB_STAKE) * DAILY_YIELD_BPS / 10_000;
        uint256 aliceYieldShare = totalYield * ALICE_STAKE / (ALICE_STAKE + BOB_STAKE);
        uint256 bobYieldShare = totalYield - aliceYieldShare;
        
        assertEq(alice.balance, aliceBalanceBefore + ALICE_STAKE + aliceYieldShare);
        assertEq(bob.balance, bobBalanceBefore + BOB_STAKE + bobYieldShare);
        
        ITrustContract.contractView memory contractData = trustContract.getContractDetails(alice, bob);
        assertFalse(contractData.isActive);
    }

    function testExitWithZeroYield() public {
        _createAndActivateContract();
        
        uint256 aliceBalanceBefore = alice.balance;
        uint256 bobBalanceBefore = bob.balance;
        
        vm.prank(alice);
        trustContract.exit(bob);
        
        assertEq(alice.balance, aliceBalanceBefore + ALICE_STAKE);
        assertEq(bob.balance, bobBalanceBefore + BOB_STAKE);
    }

    function testTrustScoreGrowsWithTime() public {
        _createAndActivateContract();
        
        uint256 initialScore = trustContract.getTrustScore(alice);
        assertEq(initialScore, 0); 
        
        vm.warp(block.timestamp + 4 days);
        
        uint256 laterScore = trustContract.getTrustScore(alice);
        uint256 expectedScore = 2 * (ALICE_STAKE + BOB_STAKE) / 100;
            
        assertEq(laterScore, expectedScore);
    }

    function testTrustScoreMultipleContracts() public {
        _createAndActivateContract();
        
        vm.prank(alice);
        trustContract.createContract{value: 8 ether}(charlie);
        
        vm.prank(charlie);
        trustContract.addStake{value: 7 ether}(alice);
        
        vm.warp(block.timestamp + 1 days);
        
        uint256 aliceScore = trustContract.getTrustScore(alice);
        
        uint256 expectedScore = 1 * (15 ether + 15 ether) / 100;
        assertEq(aliceScore, expectedScore);
    }


    function testOwnerCanFreezeContract() public {
        _createAndActivateContract();
        
        vm.prank(owner);
        trustContract.freezeContract(alice, bob, true);
        
        assertTrue(trustContract.isContractFrozen(alice, bob));
    }

    function testNonOwnerCannotFreeze() public {
        _createAndActivateContract();
        
        vm.prank(alice);
        vm.expectRevert();
        trustContract.freezeContract(alice, bob, true);
    }

    function testFrozenContractPreventsActions() public {
        _createAndActivateContract();
        
        vm.prank(owner);
        trustContract.freezeContract(alice, bob, true);
        
        vm.prank(alice);
        vm.expectRevert("Invalid state");
        trustContract.defect(bob);
        
        vm.prank(alice);
        vm.expectRevert("Invalid state");
        trustContract.exit(bob);
    }


    function testContractKeyConsistency() public view{
        bytes32 key1 = trustContract.getContractKey(alice, bob);
        bytes32 key2 = trustContract.getContractKey(bob, alice);
        
        assertEq(key1, key2, "Contract keys should be identical regardless of order");
    }

    function testReentrancyProtection() public {
    
        _createAndActivateContract();
        
        vm.prank(alice);
        trustContract.defect(bob);
        
        vm.prank(alice);
        vm.expectRevert("Invalid state");
        trustContract.defect(bob);
    }

    function testYieldUpdateOnFreeze() public {
        _createAndActivateContract();
        
        vm.warp(block.timestamp + 1 days);
        
        vm.prank(owner);
        trustContract.freezeContract(alice, bob, true);
        
        ITrustContract.contractView memory contractData = trustContract.getContractDetails(alice, bob);
        uint256 expectedYield = (ALICE_STAKE + BOB_STAKE) * DAILY_YIELD_BPS / 10_000;
        
        assertEq(contractData.accruedYield, expectedYield);
        assertTrue(contractData.isFrozen);
    }


    function testFuzzCreateContract(uint256 stakeAmount) public {
        vm.assume(stakeAmount > 0 && stakeAmount <= INITIAL_BALANCE);
        
        vm.prank(alice);
        trustContract.createContract{value: stakeAmount}(bob);
        
        ITrustContract.contractView memory contractData = trustContract.getContractDetails(alice, bob);
        assertEq(contractData.stake0, stakeAmount);
        assertFalse(contractData.isActive);
    }

    function testFuzzYieldAccrual(uint256 timeSkip) public {
        vm.assume(timeSkip > 0 && timeSkip <= 365 days);
        
        _createAndActivateContract();
        
        vm.warp(block.timestamp + timeSkip);
        
        uint256 projectedYield = trustContract.getProjectedYield(alice, bob, 0);
        uint256 expectedYield = (ALICE_STAKE + BOB_STAKE) * DAILY_YIELD_BPS * timeSkip / (10_000 * 1 days);
        
        assertEq(projectedYield, expectedYield);
    }


    function _createAndActivateContract() internal {
        vm.prank(alice);
        trustContract.createContract{value: ALICE_STAKE}(bob);
        
        vm.prank(bob);
        trustContract.addStake{value: BOB_STAKE}(alice);
    }


    function invariant_contractBalanceMatchesStakes() public {

    }

    function invariant_trustScoreNeverNegative() public view {
        assertGe(trustContract.getTrustScore(alice), 0);
        assertGe(trustContract.getTrustScore(bob), 0);
        assertGe(trustContract.getTrustScore(charlie), 0);
    }
}