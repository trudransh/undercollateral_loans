// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ITrustContract } from "./ITrustContract.sol";

/**
 * @title ITrustScoring
 * @notice Interface for Trust Protocol scoring layer
 * @dev Handles trust score calculations, penalties, and user reputation tracking
 */
interface ITrustScoring {
    
    // ============= STRUCTS =============
    
    /**
     * @notice User reputation profile
     * @param totalScore Current trust score across all contracts
     * @param totalContracts Number of active contracts
     * @param totalDefects Number of times user has defected
     * @param totalExits Number of times user has exited
     * @param penaltyOffset Total penalty applied to user
     * @param lastUpdated Block timestamp of last score update
     * @param riskTier Current risk assessment tier
     */
    struct UserProfile {
        uint256 totalScore;
        uint32 totalContracts;
        uint32 totalDefects;
        uint32 totalExits;
        uint256 penaltyOffset;
        uint64 lastUpdated;
        RiskTier riskTier;
    }

    /**
     * @notice Contract score breakdown
     * @param contractKey Unique contract identifier
     * @param baseScore Time and TVL based score
     * @param partnerInfluence Partner trust influence
     * @param ageBonus Bonus for contract longevity
     * @param yieldBonus Bonus for yield performance
     * @param totalScore Final calculated score
     */
    struct ContractScore {
        bytes32 contractKey;
        uint256 baseScore;
        uint256 partnerInfluence;
        uint256 ageBonus;
        uint256 yieldBonus;
        uint256 totalScore;
    }

    /**
     * @notice Risk tier classification
     */
    enum RiskTier {
        SAFE,       // High trust, no defaults
        MODERATE,   // Medium trust, some history
        RISKY,      // Low trust, default history
        BANNED      // Too many defaults, banned
    }

    // ============= CORE FUNCTIONS =============
    
    /**
     * @notice Calculate complete user trust score
     * @param user Address to calculate score for
     * @return totalScore Final trust score
     * @return riskTier User's risk classification
     */
    function calculateTrustScore(address user) external view returns (uint256 totalScore, RiskTier riskTier);
    
    /**
     * @notice Calculate score for specific contract
     * @param user User address
     * @param contractKey Contract identifier
     * @return score Contract score breakdown
     */
    function calculateContractScore(address user, bytes32 contractKey) external view returns (ContractScore memory score);
    
    /**
     * @notice Apply penalty to user (called by TrustContract)
     * @param user User to penalize
     * @param penaltyType Type of penalty (defect/exit)
     * @param penaltyAmount Amount of penalty
     */
    function applyPenalty(address user, PenaltyType penaltyType, uint256 penaltyAmount) external;
    
    /**
     * @notice Update user score (called when contracts change)
     * @param user User to update
     */
    function updateUserScore(address user) external;

    // ============= VIEW FUNCTIONS =============
    
    /**
     * @notice Get user profile with current stats
     * @param user Address to query
     * @return profile Complete user profile
     */
    function getUserProfile(address user) external view returns (UserProfile memory profile);
    
    /**
     * @notice Get user's risk tier
     * @param user Address to query
     * @return riskTier Current risk classification
     */
    function getUserRiskTier(address user) external view returns (RiskTier riskTier);
    
    /**
     * @notice Get all contract scores for user
     * @param user Address to query
     * @return scores Array of contract scores
     */
    function getUserContractScores(address user) external view returns (ContractScore[] memory scores);
    
    /**
     * @notice Check if user is banned
     * @param user Address to check
     * @return isBanned True if user is banned
     */
    function isUserBanned(address user) external view returns (bool isBanned);
    
    /**
     * @notice Get penalty history for user
     * @param user Address to query
     * @return defects Number of defects
     * @return exits Number of exits
     * @return totalPenalty Total penalty applied
     */
    function getPenaltyHistory(address user) external view returns (uint32 defects, uint32 exits, uint256 totalPenalty);

    // ============= ADMIN FUNCTIONS =============
    
    /**
     * @notice Set penalty thresholds (owner only)
     * @param maxDefects Maximum defects before ban
     * @param maxExits Maximum exits before restriction
     */
    function setPenaltyThresholds(uint32 maxDefects, uint32 maxExits) external;
    
    /**
     * @notice Ban/unban user (owner only)
     * @param user User to ban/unban
     * @param banned Ban status
     */
    function setUserBanStatus(address user, bool banned) external;

    // ============= EVENTS =============
    
    event TrustScoreUpdated(address indexed user, uint256 newScore, RiskTier riskTier, uint64 timestamp);
    event PenaltyApplied(address indexed user, PenaltyType penaltyType, uint256 penaltyAmount, uint256 newScore);
    event UserBanned(address indexed user, string reason, uint64 timestamp);
    event UserUnbanned(address indexed user, uint64 timestamp);
    event PenaltyThresholdsUpdated(uint32 maxDefects, uint32 maxExits, address indexed by);
    event ContractScoreCalculated(address indexed user, bytes32 indexed contractKey, uint256 score, uint64 timestamp);

    // ============= ENUMS =============
    
    enum PenaltyType {
        DEFECT,
        EXIT
    }
}