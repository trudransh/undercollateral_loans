// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ITrustScore } from "./ITrustScore.sol";
import { ITrustContract } from "./ITrustContract.sol";
import { MathUtils } from "./MathUtils.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TrustScore
 * @notice Implements whitepaper trust scoring equations
 * @dev Simplified trust scoring for MVP
 */
contract TrustScore is ITrustScore, Ownable {
    
    ITrustContract public immutable trustContract;

    /// @dev Tracks user scores and penalty offsets
    mapping(address => UserScore) internal userScores;

    /// @dev Caches contract scores for each user and contractKey
    mapping(address => mapping(bytes32 => ContractScore)) internal contractScores;
   
    uint256 public constant W1 = 40;  
    uint256 public constant W2 = 30;   
    uint256 public constant W3 = 30; 
    uint256 public constant WEIGHT_DENOMINATOR = 100;
    
    uint256 public constant DELTA = 1;
    uint256 public constant PHI = 2;   
    uint256 public constant ALPHA = 1; 

    constructor(address _trustContract) Ownable(msg.sender) {
        trustContract = ITrustContract(_trustContract);
    }
    
    /**
     * @notice Get user's total trust score (for LendingPool integration)
     * @param user Address to get score for
     * @return T_user Total trust score
     */
    function getUserTrustScore(address user) external view override returns (uint256) {
        return calculateUserTrustScore(user);
    }
    
    /**
     * @notice Calculate user's total trust score (Equation 4)
     * T_user = (sum of T_contract^i) * sqrt(n)
     */
    function calculateUserTrustScore(address user) public view override returns (uint256) {
        UserScore memory userScore = userScores[user];
        
        // Get all user contracts from TrustContract
        bytes32[] memory userContracts = trustContract.getUserContracts(user);
        
        uint256 sumOfContractScores = 0;
        uint256 activeContractsCount = 0;
        
        // Calculate scores for all active contracts
        for (uint256 i = 0; i < userContracts.length; i++) {
            bytes32 contractKey = userContracts[i];
            ITrustContract.contractView memory contractData = trustContract.getContract(contractKey);
            
            if (contractData.isActive) {
                uint256 contractScore = _calculateContractScoreInternal(user, contractKey, contractData);
                sumOfContractScores += contractScore;
                activeContractsCount++;
            }
        }
        
        // Apply diversity bonus: sqrt(n)
        uint256 diversityBonus = MathUtils.sqrt(activeContractsCount + 1);
        
        uint256 finalScore = sumOfContractScores * diversityBonus;
        if (finalScore > userScore.penaltyOffset) {
            return finalScore - userScore.penaltyOffset;
        }
        return 0;
    }
    
    /**
     * @notice Calculate single contract score (Equation 2)
     * T_contract = w1*ln(1+X+Y) + w2*sqrt(t) + w3*(T_partner/100 * Y/(X+Y))
     */
    function calculateContractScore(address user, bytes32 contractKey) external view override returns (uint256) {
        ITrustContract.contractView memory contractData = trustContract.getContract(contractKey);
        return _calculateContractScoreInternal(user, contractKey, contractData);
    }
    
    /**
     * @notice Internal function to calculate contract score
     */
    function _calculateContractScoreInternal(
        address user, 
        bytes32 contractKey, 
        ITrustContract.contractView memory contractData
    ) internal view returns (uint256) {
        if (!contractData.isActive) return 0;
        
        uint256 tvl = uint256(contractData.stake0) + contractData.stake1;
        uint256 timeDays = (block.timestamp - contractData.createdAt) / 1 days;
        
        uint256 userStake = (contractData.addr0 == user) ? contractData.stake0 : contractData.stake1;
        uint256 partnerStake = tvl - userStake;
        
        uint256 partnerTrust = _getPartnerTrustScore(user, contractData);
        
        // TVL component: w1 * ln(1 + X + Y)
        uint256 tvlComponent = W1 * _lnApprox(1 + tvl) / WEIGHT_DENOMINATOR;
        
        // Time component: w2 * sqrt(t)
        uint256 timeComponent = W2 * MathUtils.sqrt(timeDays + 1) / WEIGHT_DENOMINATOR; 
        
        // Partner component: w3 * (T_partner/100 * Y/(X+Y))
        uint256 partnerComponent = W3 * (partnerTrust * partnerStake) / (100 * tvl * WEIGHT_DENOMINATOR);
        
        uint256 contractScore = tvlComponent + timeComponent + partnerComponent;
        
        return contractScore;
    }
    
    /**
     * @notice Apply defect penalty (Equation 5)
     * T_new = T_current - (T_contract + sqrt(TVL_contract * Contracts_Broken))
     */
    function applyDefectPenalty(address user, uint256 contractScore, uint256 tvl) external override {
        require(msg.sender == address(trustContract), "Only TrustContract can apply penalties");
        
        UserScore storage userScore = userScores[user];
        userScore.contractsBroken++;
        
        uint256 penalty = contractScore + MathUtils.sqrt(tvl * userScore.contractsBroken);
        userScore.penaltyOffset += penalty;
        
        emit DefectPenaltyApplied(user, penalty, userScore.penaltyOffset);
    }
    
    /**
     * @notice Apply exit penalty (Equation 6)
     * T_new = T_current + T_contract - sqrt(TVL_contract + Contracts_Withdrawn)
     */
    function applyExitPenalty(address user, uint256 contractScore, uint256 tvl) external override {
        require(msg.sender == address(trustContract), "Only TrustContract can apply penalties");
        
        UserScore storage userScore = userScores[user];
        userScore.contractsWithdrawn++;
        
        uint256 penalty = MathUtils.sqrt(tvl + userScore.contractsWithdrawn);
        userScore.penaltyOffset += penalty;
        
        emit ExitPenaltyApplied(user, penalty, userScore.penaltyOffset);
    }

    // ============= VIEW FUNCTIONS =============
    
    function getUserScore(address user) external view override returns (UserScore memory) {
        return userScores[user];
    }
    
    function getContractScore(address user, bytes32 contractKey) external view override returns (ContractScore memory) {
        return contractScores[user][contractKey];
    }
    
    function getWeights() external pure override returns (uint256 w1, uint256 w2, uint256 w3) {
        return (W1, W2, W3);
    }

    // ============= INTERNAL FUNCTIONS =============
    
    /**
     * @notice Simple ln approximation (for gas efficiency)
     */
    function _lnApprox(uint256 x) internal pure returns (uint256) {
        if (x <= 1) return 0;
        
        uint256 y = x - 1;
        if (y == 0) return 0;
       
        return y * 100 / (100 + y); 
    }
    
    /**
     * @notice Get partner's trust score
     */
    function _getPartnerTrustScore(address user, ITrustContract.contractView memory contractData) internal view returns (uint256) {
        address partner = (contractData.addr0 == user) ? contractData.addr1 : contractData.addr0;
        return calculateUserTrustScore(partner);
    }
}