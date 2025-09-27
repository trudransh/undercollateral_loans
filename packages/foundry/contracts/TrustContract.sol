// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ITrustContract } from "./ITrustContract.sol";
import { MathUtils } from "./MathUtils.sol";
import { PenaltyLib } from "./PenaltyLib.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title TrustContract
 * @notice Core Trust Protocol implementation - passive cooperation model
 * @dev Contracts earn yield automatically over time. Users only act to EXIT or DEFECT.
 */
contract TrustContract is ITrustContract, Ownable, ReentrancyGuard {
    
    // ============= STATE VARIABLES =============
    
    mapping(bytes32 => contractView) public contracts;
    
    // Track authorized lending contracts
    mapping(address => bool) public authorizedLenders;
    
    // Track all contracts for each user
    mapping(address => bytes32[]) public userContracts;
    
    // ============= MODIFIERS =============
    
    modifier onlyAuthorizedLender() {
        require(
            msg.sender == owner() || authorizedLenders[msg.sender],
            "Not authorized lender"
        );
        _;
    }

    constructor() Ownable(msg.sender) {
        // Constructor sets msg.sender as owner
    }
    
    // ============= CORE FUNCTIONS =============
    
    /**
     * @notice Create a new trust contract with a partner
     */
    function createContract(address partner) external payable override nonReentrant {
        require(msg.value > 0, "Zero stake");
        require(partner != address(0), "Invalid partner");
        require(partner != msg.sender, "Self contract");
        
        bytes32 key = getContractKey(msg.sender, partner);
        require(!contracts[key].isActive, "Contract exists");
        
        contracts[key] = contractView({
            addr0: msg.sender < partner ? msg.sender : partner,
            addr1: msg.sender < partner ? partner : msg.sender,
            stake0: msg.sender < partner ? uint128(msg.value) : 0,
            stake1: msg.sender < partner ? 0 : uint128(msg.value),
            accruedYield: 0,
            createdAt: uint32(block.timestamp),
            lastYieldUpdate: uint32(block.timestamp),
            isActive: true,
            isFrozen: false
        });
        
        // Add to user's contract list
        userContracts[msg.sender].push(key);
        userContracts[partner].push(key);
        
        emit ContractCreated(key, msg.sender, partner, msg.value);
    }
    
    /**
     * @notice Add stake to existing contract
     */
    function addStake(address partner) external payable override nonReentrant {
        bytes32 key = getContractKey(msg.sender, partner);
        _updateContractYield(key);
        
        contractView storage trustContract = contracts[key];
        require(trustContract.isActive && !trustContract.isFrozen, "Invalid state");
        require(_isParticipant(trustContract, msg.sender), "Not participant");
        
        if (trustContract.addr0 == msg.sender) {
            trustContract.stake0 += uint128(msg.value);
        } else {
            trustContract.stake1 += uint128(msg.value);
        }
        
        emit StakeAdded(key, msg.sender, msg.value);
    }
    
    /**
     * @notice Exit contract - fair withdrawal with mild penalty
     */
    function exit(address partner) external override nonReentrant {
        bytes32 key = getContractKey(msg.sender, partner);
        _updateContractYield(key);
        
        contractView storage trustContract = contracts[key];
        require(trustContract.isActive && !trustContract.isFrozen, "Invalid state");
        require(_isParticipant(trustContract, msg.sender), "Not participant");
        
        uint256 s0 = trustContract.stake0;
        uint256 s1 = trustContract.stake1;
        uint256 yield = trustContract.accruedYield;
        uint256 totalStake = s0 + s1;
        
        // Calculate user's share
        uint256 userStake = trustContract.addr0 == msg.sender ? s0 : s1;
        uint256 userYield = (yield * userStake) / totalStake;
        uint256 totalWithdrawal = userStake + userYield;
        
        // Calculate exit penalty (mild)
        uint256 tBond = _calculateBondScore(key);
        uint256 penalty = PenaltyLib.exitPenalty(tBond,totalStake, yield);
        uint256 finalAmount = totalWithdrawal > penalty ? totalWithdrawal - penalty : 0;
        
        // Deactivate contract
        trustContract.isActive = false;
        
        // Transfer funds
        if (finalAmount > 0) {
            payable(msg.sender).transfer(finalAmount);
        }
        
        // Transfer remaining to partner
        uint256 remaining = totalStake + yield - totalWithdrawal;
        if (remaining > 0) {
            payable(partner).transfer(remaining);
        }
        
        emit ContractExited(key, msg.sender, finalAmount, penalty);
    }
    
    /**
     * @notice Defect contract - steal all funds with heavy penalty
     */
    function defect(address partner) external override nonReentrant {
        bytes32 key = getContractKey(msg.sender, partner);
        _updateContractYield(key);
        
        contractView storage trustContract = contracts[key];
        require(trustContract.isActive && !trustContract.isFrozen, "Invalid state");
        require(_isParticipant(trustContract, msg.sender), "Not participant");
        
        uint256 totalAmount = trustContract.stake0 + trustContract.stake1 + trustContract.accruedYield;
        
        // Calculate defect penalty (heavy)
        uint256 tBond = _calculateBondScore(key);
        uint256 penalty = PenaltyLib.defectPenalty(tBond, totalAmount);
        uint256 finalAmount = totalAmount > penalty ? totalAmount - penalty : 0;
        
        // Deactivate contract
        trustContract.isActive = false;
        
        // Transfer all funds to defector (minus penalty)
        if (finalAmount > 0) {
            payable(msg.sender).transfer(finalAmount);
        }
        
        emit ContractDefected(key, msg.sender, finalAmount, penalty);
    }
    
    // ============= VIEW FUNCTIONS =============
    
    function getContract(bytes32 contractKey) external view override returns (contractView memory) {
        return contracts[contractKey];
    }

    function getContractKey(address a, address b) public pure override returns (bytes32) {
        (address addr0, address addr1) = MathUtils.sortAddresses(a, b);
        // Use abi.encode instead of abi.encodePacked for safety and type correctness
        return keccak256(abi.encode(addr0, addr1));
    }

    function getProjectedYield(bytes32 contractKey) external view override returns (uint256) {
        return _getProjectedYield(contractKey);
    }
    
    
    function isParticipant(bytes32 contractKey, address user) external view override returns (bool) {
        contractView memory contractData = contracts[contractKey];
        return contractData.addr0 == user || contractData.addr1 == user;
    }
    
    // ============= LENDING FUNCTIONS =============
    
    /**
     * @notice Freeze/unfreeze all contracts for a specific user
     */
    function freezeAllUserContracts(address user, bool freeze) external override onlyAuthorizedLender {
        bytes32[] memory userContractKeys = userContracts[user];
        
        for (uint256 i = 0; i < userContractKeys.length; i++) {
            bytes32 contractKey = userContractKeys[i];
            
            if (contracts[contractKey].isActive) {
                _updateContractYield(contractKey);
                contracts[contractKey].isFrozen = freeze;
                emit ContractFrozen(contractKey, freeze, msg.sender);
            }
        }
    }
    
    /**
     * @notice Claim yields from all user's contracts (for liquidation)
     */
    function claimAllUserYields(address user) external override onlyAuthorizedLender {
        bytes32[] memory userContractKeys = userContracts[user];
        
        for (uint256 i = 0; i < userContractKeys.length; i++) {
            bytes32 contractKey = userContractKeys[i];
            
            if (contracts[contractKey].isActive && contracts[contractKey].isFrozen) {
                _claimYields(contractKey);
            }
        }
    }
    
    /**
     * @notice Get total value of all user's contracts
     */
    function getUserTotalValue(address user) external view override returns (uint256) {
        bytes32[] memory userContractKeys = userContracts[user];
        uint256 totalValue = 0;
        
        for (uint256 i = 0; i < userContractKeys.length; i++) {
            bytes32 contractKey = userContractKeys[i];
            contractView memory contractData = contracts[contractKey];
            
            if (contractData.isActive) {
                // Calculate user's stake value
                uint256 userStake = contractData.addr0 == user ? contractData.stake0 : contractData.stake1;
                uint256 projectedYield = _getProjectedYield(contractKey);
                uint256 contractValue = userStake + (projectedYield / 2); // User gets half the yield
                
                totalValue += contractValue;
            }
        }
        
        return totalValue;
    }
    
    /**
     * @notice Get all contract keys for a user
     */
    function getUserContracts(address user) external view override returns (bytes32[] memory) {
        return userContracts[user];
    }
    
    /**
     * @notice Get contract details by key and user
     */
    function getContractDetails(bytes32 contractKey, address user) external view override returns (contractView memory) {
        contractView memory contractData = contracts[contractKey];
        
        // Verify user is participant
        require(
            contractData.addr0 == user || contractData.addr1 == user,
            "Not participant in contract"
        );
        
        return contractData;
    }
    
    // ============= ADMIN FUNCTIONS =============
    
    /**
     * @notice Add a lending contract as authorized caller
     */
    function addAuthorizedLender(address lender) external override onlyOwner {
        require(lender != address(0), "Invalid lender address");
        authorizedLenders[lender] = true;
        emit LenderAuthorized(lender);
    }
    
    /**
     * @notice Remove a lending contract authorization
     */
    function removeAuthorizedLender(address lender) external override onlyOwner {
        authorizedLenders[lender] = false;
        emit LenderDeauthorized(lender);
    }
    
    // ============= INTERNAL FUNCTIONS =============
    
    function _updateContractYield(bytes32 contractKey) internal {
        contractView storage trustContract = contracts[contractKey];
        if (!trustContract.isActive) return;
        
        uint256 timeElapsed = block.timestamp - trustContract.lastYieldUpdate;
        uint256 totalStake = trustContract.stake0 + trustContract.stake1;
        
        // Simple yield calculation: 1% per year
        uint256 newYield = (totalStake * timeElapsed * 100) / (365 days * 10000);
        trustContract.accruedYield += uint128(newYield);
        trustContract.lastYieldUpdate = uint32(block.timestamp);
    }
    
    function _isParticipant(contractView memory contractData, address user) internal pure returns (bool) {
        return contractData.addr0 == user || contractData.addr1 == user;
    }
    
    function _calculateBondScore(bytes32 contractKey) internal view returns (uint256) {
        contractView memory contractData = contracts[contractKey];
        uint256 timeElapsed = block.timestamp - contractData.createdAt;
        uint256 totalStake = contractData.stake0 + contractData.stake1;
        
        // Simplified bond score: sqrt(time) * sqrt(stake)
        return MathUtils.sqrt(timeElapsed) * MathUtils.sqrt(totalStake) / 100;
    }
    
    function _claimYields(bytes32 contractKey) internal {
        contractView storage trustContract = contracts[contractKey];
        require(trustContract.isActive, "Contract inactive");
        require(trustContract.isFrozen, "Contract not frozen");
        
        uint256 totalYield = trustContract.accruedYield;
        uint256 totalStake = trustContract.stake0 + trustContract.stake1;
        
        if (totalYield > 0) {
            // Distribute yields proportionally
            uint256 yield0 = (totalYield * trustContract.stake0) / totalStake;
            uint256 yield1 = totalYield - yield0;
            
            // Transfer yields
            if (yield0 > 0) {
                payable(trustContract.addr0).transfer(yield0);
            }
            if (yield1 > 0) {
                payable(trustContract.addr1).transfer(yield1);
            }
            
            // Reset yield and slash trust scores
            trustContract.accruedYield = 0;
            trustContract.lastYieldUpdate = uint32(block.timestamp);
            
            // TODO: Integrate with TrustScore contract to slash scores
            // trustScore.slashTrustScore(trustContract.addr0, contractKey);
            // trustScore.slashTrustScore(trustContract.addr1, contractKey);
            
            emit YieldsClaimed(contractKey, totalYield);
        }
    }
    
    function _getProjectedYield(bytes32 contractKey) internal view returns (uint256) {
        contractView memory contractData = contracts[contractKey];
        
        if (!contractData.isActive) return 0;
        
        uint256 timeElapsed = block.timestamp - contractData.lastYieldUpdate;
        uint256 totalStake = contractData.stake0 + contractData.stake1;
        
        // Simple yield calculation: 1% per year
        return (totalStake * timeElapsed * 100) / (365 days * 10000);
    }

    }