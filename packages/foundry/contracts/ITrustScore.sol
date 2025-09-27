// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ITrustScoring
 * @notice Trust Protocol scoring layer - implements whitepaper equations exactly
 * @dev Uses Equations 2, 4, 5, and 6 from the whitepaper
 */
interface ITrustScore {
    
    // ============= STRUCTS =============
    
    struct BondScore {
        bytes32 bondKey;
        uint256 bondScore;     // T_bond from Equation 2
        uint256 tvl;           // X + Y
        uint256 time;          // t (days)
        uint256 partnerTrust;  // T_partner
        uint256 userStake;     // User's stake (X or Y)
        uint256 totalStake;    // X + Y
    }

    struct UserScore {
        uint256 totalScore;    // T_user from Equation 4
        uint256 bondsCount;    // n (number of bonds)
        uint256 bondsBroken;   // For penalty calculations
        uint256 bondsWithdrawn; // For penalty calculations
        uint256 penaltyOffset; // Accumulated penalties
    }

    // ============= CORE FUNCTIONS =============
    
    /**
     * @notice Calculate user's total trust score (Equation 4)
     * @param user Address to calculate score for
     * @return T_user = (sum of T_bond^i) * sqrt(n)
     */
    function calculateUserTrustScore(address user) external view returns (uint256);
    
    /**
     * @notice Calculate single bond score (Equation 2)
     * @param user User address
     * @param bondKey Bond identifier
     * @return T_bond = w1*ln(1+X+Y) + w2*sqrt(t) + w3*(T_partner/100 * Y/(X+Y))
     */
    function calculateBondScore(address user, bytes32 bondKey) external view returns (uint256);
    
    /**
     * @notice Apply defect penalty (Equation 5)
     * @param user User who defected
     * @param bondScore T_bond of the broken bond
     * @param tvl TVL of the broken bond
     */
    function applyDefectPenalty(address user, uint256 bondScore, uint256 tvl) external;
    
    /**
     * @notice Apply exit penalty (Equation 6)
     * @param user User who exited
     * @param bondScore T_bond of the withdrawn bond
     * @param tvl TVL of the withdrawn bond
     */
    function applyExitPenalty(address user, uint256 bondScore, uint256 tvl) external;

    // ============= VIEW FUNCTIONS =============
    
    function getUserScore(address user) external view returns (UserScore memory);
    function getBondScore(address user, bytes32 bondKey) external view returns (BondScore memory);
    function getWeights() external pure returns (uint256 w1, uint256 w2, uint256 w3);

    // ============= EVENTS =============
    
    event UserScoreUpdated(address indexed user, uint256 newScore, uint256 bondsCount);
    event BondScoreCalculated(address indexed user, bytes32 indexed bondKey, uint256 score);
    event DefectPenaltyApplied(address indexed user, uint256 penalty, uint256 newScore);
    event ExitPenaltyApplied(address indexed user, uint256 penalty, uint256 newScore);
}