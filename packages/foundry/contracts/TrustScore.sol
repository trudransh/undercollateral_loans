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
        // SIMPLIFIED: Return a basic score based on user's contracts
        bytes32[] memory userContracts = trustContract.getUserContracts(user);
        
        if (userContracts.length == 0) {
            return 0;
        }
        
        // Simple calculation: 100 points per contract + time bonus
        uint256 baseScore = userContracts.length * 100;
        
        // Add time bonus for each contract
        uint256 timeBonus = 0;
        for (uint256 i = 0; i < userContracts.length; i++) {
            ITrustContract.contractView memory contractData = trustContract.getContract(userContracts[i]);
            if (contractData.isActive) {
                uint256 timeElapsed = block.timestamp - contractData.createdAt;
                timeBonus += MathUtils.sqrt(timeElapsed / 1 days); // Days since creation
            }
        }
        
        return baseScore + timeBonus;
    }
    
    /**
     * @notice Calculate user's total trust score (Equation 4) - SIMPLIFIED
     * T_user = (sum of T_contract^i) * sqrt(n)
    /**
     * @notice Calculate user's total trust score (Equation 4) - SIMPLIFIED
     * T_user = (sum of T_contract^i) * sqrt(n)
     * @param user Address to get score for
     * @return T_user Total trust score
     */
    function calculateUserTrustScore(address user) public view override returns (uint256) {
        // Use the same logic as getUserTrustScore, but make it self-contained for clarity and future extensibility
        bytes32[] memory userContracts = trustContract.getUserContracts(user);

        if (userContracts.length == 0) {
            return 0;
        }

        uint256 baseScore = userContracts.length * 100;
        uint256 timeBonus = 0;
        for (uint256 i = 0; i < userContracts.length; i++) {
            ITrustContract.contractView memory contractData = trustContract.getContract(userContracts[i]);
            if (contractData.isActive) {
                uint256 timeElapsed = block.timestamp - contractData.createdAt;
                timeBonus += MathUtils.sqrt(timeElapsed / 1 days);
            }
        }

        return baseScore + timeBonus;
    }

    /**
     * @notice Calculate single contract score (Equation 2) - SIMPLIFIED
     */
    function calculateContractScore(address user, bytes32 contractKey) external view override returns (uint256) {
        ITrustContract.contractView memory contractData = trustContract.getContract(contractKey);
        
        if (!contractData.isActive) return 0;
        
        uint256 tvl = uint256(contractData.stake0) + contractData.stake1;
        uint256 timeDays = (block.timestamp - contractData.createdAt) / 1 days;
        
        // Simplified calculation: TVL component + time component
        uint256 tvlComponent = MathUtils.sqrt(tvl / 1e18) * 10; // Scale down for ETH
        uint256 timeComponent = MathUtils.sqrt(timeDays + 1) * 5;
        
        return tvlComponent + timeComponent;
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
     * @notice Apply defect penalty (Equation 5) - SIMPLIFIED
     */
    function applyDefectPenalty(address user, uint256 contractScore, uint256 tvl) external override {
        require(msg.sender == address(trustContract), "Only TrustContract can apply penalties");
        
        UserScore storage userScore = userScores[user];
        userScore.contractsBroken++;
        
        // Simple penalty: 10% of contract score
        uint256 penalty = contractScore / 10;
        userScore.penaltyOffset += penalty;
        
        emit DefectPenaltyApplied(user, penalty, userScore.penaltyOffset);
    }
    
    /**
     * @notice Apply exit penalty (Equation 6) - SIMPLIFIED
     */
    function applyExitPenalty(address user, uint256 contractScore, uint256 tvl) external override {
        require(msg.sender == address(trustContract), "Only TrustContract can apply penalties");
        
        UserScore storage userScore = userScores[user];
        userScore.contractsWithdrawn++;
        
        // Simple penalty: 5% of contract score
        uint256 penalty = contractScore / 20;
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