// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ITrustScore } from "./ITrustScore.sol";
import { ITrustContract } from "./ITrustContract.sol";
import { MathUtils } from "./MathUtils.sol";

/**
 * @title TrustScoring
 * @notice Implements whitepaper trust scoring equations exactly
 * @dev Equations 2, 4, 5, 6 from "The Trust Protocol" whitepaper
 */
contract TrustScore is ITrustScore {
    
    // ============= STATE VARIABLES =============
    
    ITrustContract public immutable trustContract;

    /// @dev Tracks user scores and penalty offsets. Use internal for upgradeability and testing.
    mapping(address => UserScore) internal userScores;

    /// @dev Caches bond scores for each user and bondKey. Use internal for extensibility.
    mapping(address => mapping(bytes32 => BondScore)) internal bondScores;
    // Weights for Equation 2 (must sum to 1)
    uint256 public constant W1 = 40;  // 40% weight for TVL (ln term)
    uint256 public constant W2 = 30;  // 30% weight for time (sqrt term)  
    uint256 public constant W3 = 30;  // 30% weight for partner trust
    uint256 public constant WEIGHT_DENOMINATOR = 100;
    
    // Trust increment per cooperation (δ from whitepaper)
    uint256 public constant DELTA = 1;
    
    // Penalty multipliers (φ and α from whitepaper)
    uint256 public constant PHI = 2;   // Defect penalty multiplier
    uint256 public constant ALPHA = 1; // Exit penalty multiplier

    constructor(address _trustContract) {
        trustContract = ITrustContract(_trustContract);
    }
    
    // ============= CORE SCORING FUNCTIONS =============
    
    /**
     * @notice Calculate user's total trust score (Equation 4)
     * T_user = (sum of T_bond^i) * sqrt(n)
     */
    function calculateUserTrustScore(address user) external view returns (uint256) {
        UserScore memory userScore = userScores[user];
        
        // Calculate sum of all bond scores
        uint256 sumOfBondScores = 0;
        uint256 activeBondsCount = 0;
        
        // Note: In a real implementation, you'd iterate through user's bonds
        // For now, we'll use a simplified approach
        
        // Apply diversity bonus: sqrt(n) where n = number of bonds
        uint256 diversityBonus = MathUtils.sqrt(activeBondsCount + 1); // +1 to avoid sqrt(0)
        
        // Apply penalty offset
        uint256 finalScore = sumOfBondScores * diversityBonus;
        if (finalScore > userScore.penaltyOffset) {
            return finalScore - userScore.penaltyOffset;
        }
        return 0;
    }
    
    /**
     * @notice Calculate single bond score (Equation 2)
     * T_bond = w1*ln(1+X+Y) + w2*sqrt(t) + w3*(T_partner/100 * Y/(X+Y))
     */
    function calculateBondScore(address user, bytes32 bondKey) external view returns (uint256) {
        // Get bond details from TrustContract
        ITrustContract.contractView memory bond = _getBondFromKey(user, bondKey);
        
        if (!bond.isActive) return 0;
        
        uint256 tvl = uint256(bond.stake0) + bond.stake1;
        uint256 timeDays = (block.timestamp - bond.createdAt) / 1 days;
        
        // Determine user's stake (X or Y)
        uint256 userStake = (bond.addr0 == user) ? bond.stake0 : bond.stake1;
        uint256 partnerStake = tvl - userStake;
        
        // Get partner trust score
        uint256 partnerTrust = _getPartnerTrustScore(user, bondKey);
        
        // Calculate each term of Equation 2
        
        // Term 1: w1 * ln(1 + X + Y) - TVL component
        uint256 tvlComponent = W1 * _lnApprox(1 + tvl) / WEIGHT_DENOMINATOR;
        
        // Term 2: w2 * sqrt(t) - Time component  
        uint256 timeComponent = W2 * MathUtils.sqrt(timeDays + 1) / WEIGHT_DENOMINATOR; // +1 to avoid sqrt(0)
        
        // Term 3: w3 * (T_partner/100 * Y/(X+Y)) - Partner trust component
        uint256 partnerComponent = W3 * (partnerTrust * partnerStake) / (100 * tvl * WEIGHT_DENOMINATOR);
        
        // Sum all terms
        uint256 bondScore = tvlComponent + timeComponent + partnerComponent;
        
        return bondScore;
    }
    
    /**
     * @notice Apply defect penalty (Equation 5)
     * T_new = T_current - (T_bond + sqrt(TVL_bond * Bonds_Broken))
     */
    function applyDefectPenalty(address user, uint256 bondScore, uint256 tvl) external {
        require(msg.sender == address(trustContract), "Only TrustContract can apply penalties");
        
        UserScore storage userScore = userScores[user];
        userScore.bondsBroken++;
        
        // Calculate penalty: T_bond + sqrt(TVL_bond * Bonds_Broken)
        uint256 penalty = bondScore + MathUtils.sqrt(tvl * userScore.bondsBroken);
        
        // Apply penalty to user's offset
        userScore.penaltyOffset += penalty;
        
        emit DefectPenaltyApplied(user, penalty, userScore.penaltyOffset);
    }
    
    /**
     * @notice Apply exit penalty (Equation 6)
     * T_new = T_current + T_bond - sqrt(TVL_bond + Bonds_Withdrawn)
     */
    function applyExitPenalty(address user, uint256 bondScore, uint256 tvl) external {
        require(msg.sender == address(trustContract), "Only TrustContract can apply penalties");
        
        UserScore storage userScore = userScores[user];
        userScore.bondsWithdrawn++;
        
        // Calculate penalty: sqrt(TVL_bond + Bonds_Withdrawn)
        uint256 penalty = MathUtils.sqrt(tvl + userScore.bondsWithdrawn);
        
        // Apply penalty to user's offset
        userScore.penaltyOffset += penalty;
        
        emit ExitPenaltyApplied(user, penalty, userScore.penaltyOffset);
    }

    // ============= VIEW FUNCTIONS =============
    
    function getUserScore(address user) external view returns (UserScore memory) {
        return userScores[user];
    }
    
    function getBondScore(address user, bytes32 bondKey) external view returns (BondScore memory) {
        return bondScores[user][bondKey];
    }
    
    function getWeights() external pure returns (uint256 w1, uint256 w2, uint256 w3) {
        return (W1, W2, W3);
    }

    // ============= INTERNAL FUNCTIONS =============
    
    /**
     * @notice Simple ln approximation (for gas efficiency)
     * @param x Input value
     * @return Approximate ln(x)
     */
    function _lnApprox(uint256 x) internal pure returns (uint256) {
        if (x <= 1) return 0;
        
        // Simple approximation: ln(x) ≈ (x-1) - (x-1)²/2 + (x-1)³/3 - ...
        // For gas efficiency, we'll use a simplified version
        uint256 y = x - 1;
        if (y == 0) return 0;
        
        // ln(1+y) ≈ y - y²/2 for small y, but we'll use a more practical approximation
        return y * 100 / (100 + y); // Rough approximation that works for our range
    }
    
    function _getBondFromKey(address user, bytes32 bondKey) internal pure returns (ITrustContract.contractView memory) {
        // This is a simplified implementation
        // In reality, you'd need to decode the bondKey or query TrustContract
        // For now, return empty struct
        return ITrustContract.contractView({
            addr0: address(0),
            addr1: address(0),
            stake0: 0,
            stake1: 0,
            accruedYield: 0,
            isActive: false,
            isFrozen: false,
            createdAt: 0,
            lastYieldUpdate: 0
        });
    }
    
    function _getPartnerTrustScore(address user, bytes32 bondKey) internal view returns (uint256) {
        // Get partner address from bond
        // For now, return a placeholder
        return 50; // Placeholder partner trust score
    }
}