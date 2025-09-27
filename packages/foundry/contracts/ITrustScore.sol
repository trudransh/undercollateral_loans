// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ITrustScore
 * @notice Trust Protocol scoring layer - implements whitepaper equations
 * @dev Simplified trust scoring for MVP
 */
interface ITrustScore {
    
    // ============= STRUCTS =============
    
    struct ContractScore {
        bytes32 contractKey;
        uint256 contractScore;   // T_contract from Equation 2
        uint256 tvl;            // X + Y
        uint256 time;           // t (days)
        uint256 partnerTrust;   // T_partner
        uint256 userStake;      // User's stake (X or Y)
        uint256 totalStake;     // X + Y
    }

    struct UserScore {
        uint256 totalScore;     // T_user from Equation 4
        uint256 contractsCount; // n (number of contracts)
        uint256 contractsBroken; // For penalty calculations
        uint256 contractsWithdrawn; // For penalty calculations
        uint256 penaltyOffset;  // Accumulated penalties
    }

    // ============= CORE FUNCTIONS =============
    
    /**
     * @notice Get user's total trust score (for LendingPool)
     * @param user Address to get score for
     * @return T_user Total trust score
     */
    function getUserTrustScore(address user) external view returns (uint256);
    
    /**
     * @notice Calculate user's total trust score (Equation 4)
     * @param user Address to calculate score for
     * @return T_user = (sum of T_contract^i) * sqrt(n)
     */
    function calculateUserTrustScore(address user) external view returns (uint256);
    
    /**
     * @notice Calculate single contract score (Equation 2)
     * @param user User address
     * @param contractKey Contract identifier
     * @return T_contract = w1*ln(1+X+Y) + w2*sqrt(t) + w3*(T_partner/100 * Y/(X+Y))
     */
    function calculateContractScore(address user, bytes32 contractKey) external view returns (uint256);
    
    /**
     * @notice Apply defect penalty (Equation 5)
     * @param user User who defected
     * @param contractScore T_contract of the broken contract
     * @param tvl TVL of the broken contract
     */
    function applyDefectPenalty(address user, uint256 contractScore, uint256 tvl) external;
    
    /**
     * @notice Apply exit penalty (Equation 6)
     * @param user User who exited
     * @param contractScore T_contract of the withdrawn contract
     * @param tvl TVL of the withdrawn contract
     */
    function applyExitPenalty(address user, uint256 contractScore, uint256 tvl) external;

    // ============= VIEW FUNCTIONS =============
    
    function getUserScore(address user) external view returns (UserScore memory);
    function getContractScore(address user, bytes32 contractKey) external view returns (ContractScore memory);
    function getWeights() external pure returns (uint256 w1, uint256 w2, uint256 w3);

    // ============= EVENTS =============
    
    event UserScoreUpdated(address indexed user, uint256 newScore, uint256 contractsCount);
    event ContractScoreCalculated(address indexed user, bytes32 indexed contractKey, uint256 score);
    event DefectPenaltyApplied(address indexed user, uint256 penalty, uint256 newScore);
    event ExitPenaltyApplied(address indexed user, uint256 penalty, uint256 newScore);
}