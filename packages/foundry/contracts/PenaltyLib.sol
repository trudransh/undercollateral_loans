// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { MathUtils } from "./MathUtils.sol";

/**
 * @title PenaltyLib
 * @notice Implements whitepaper penalty equations for Trust Protocol
 * @dev Simplified penalty calculations for MVP
 */
library PenaltyLib {
    
    // ============= CONSTANTS =============
    
    uint256 public constant PHI = 500; // Heavy penalty for defection (5% of TVL)
    uint256 public constant ALPHA = 100; // Mild penalty for exit (1% of TVL)
    
    /**
     * @notice Calculate defect penalty (Equation 5 - simplified)
     * T_new = T_current - (T_bond + sqrt(TVL_bond * Bonds_Broken))
     * @param tBond T_bond of the broken bond
     * @param totalAmount Total amount being stolen (TVL + yields)
     * @return penalty Penalty amount
     */
    function defectPenalty(uint256 tBond, uint256 totalAmount) internal pure returns (uint256 penalty) {
        // Simplified: Heavy penalty = PHI% of total amount + bond score
        penalty = (totalAmount * PHI) / 10000 + tBond;
    }

    /**
     * @notice Calculate exit penalty (Equation 6 - simplified)
     * T_new = T_current + T_bond - sqrt(TVL_bond + Bonds_Withdrawn)
     * @param tBond T_bond of the withdrawn bond
     * @param totalStake Total stake in the contract
     * @param totalYield Total yield in the contract
     * @return penalty Penalty amount
     */
    function exitPenalty(uint256 tBond, uint256 totalStake, uint256 totalYield) internal pure returns (uint256 penalty) {
        // Simplified: Mild penalty = ALPHA% of total value
        uint256 totalValue = totalStake + totalYield;
        penalty = (totalValue * ALPHA) / 10000;
    }

    /**
     * @notice Calculate cooperate yield (simplified)
     * @param tvl Total value locked
     * @param timeElapsed Time elapsed in seconds
     * @return yieldAmount Yield to add
     */
    function calculateYield(uint256 tvl, uint256 timeElapsed) internal pure returns (uint256 yieldAmount) {
        // Simple yield: 1% per year (100 basis points)
        yieldAmount = (tvl * timeElapsed * 100) / (365 days * 10000);
    }
    
    /**
     * @notice Calculate trust score penalty for defection
     * @param tBond Current bond trust score
     * @param tvl Total value locked in bond
     * @return trustPenalty Trust score penalty
     */
    function defectTrustPenalty(uint256 tBond, uint256 tvl) internal pure returns (uint256 trustPenalty) {
        // Heavy trust penalty for defection
        trustPenalty = tBond + MathUtils.sqrt(tvl);
    }
    
    /**
     * @notice Calculate trust score penalty for exit
     * @param tBond Current bond trust score
     * @param tvl Total value locked in bond
     * @return trustPenalty Trust score penalty
     */
    function exitTrustPenalty(uint256 tBond, uint256 tvl) internal pure returns (uint256 trustPenalty) {
        // Mild trust penalty for exit
        trustPenalty = MathUtils.sqrt(tvl) / 2;
    }
}