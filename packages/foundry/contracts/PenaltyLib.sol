// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { MathUtils } from "./MathUtils.sol";

/**
 * @title PenaltyLib
 * @notice Implements whitepaper penalty equations exactly
 * @dev Equations 5 & 6 from "The Trust Protocol" whitepaper
 */
library PenaltyLib {
    
    /**
     * @notice Calculate defect penalty (Equation 5)
     * T_new = T_current - (T_bond + sqrt(TVL_bond * Bonds_Broken))
     * @param tBond T_bond of the broken bond
     * @param tvl TVL of the broken bond  
     * @param bondsBroken Number of bonds broken by user
     * @return penalty Penalty amount
     */
    function defectPenalty(uint256 tBond, uint256 tvl, uint256 bondsBroken) internal pure returns (uint256 penalty) {
        // Equation 5: T_bond + sqrt(TVL_bond * Bonds_Broken)
        penalty = tBond + MathUtils.sqrt(tvl * bondsBroken);
    }

    /**
     * @notice Calculate exit penalty (Equation 6)  
     * T_new = T_current + T_bond - sqrt(TVL_bond + Bonds_Withdrawn)
     * @param tvl TVL of the withdrawn bond
     * @param bondsWithdrawn Number of bonds withdrawn by user
     * @return penalty Penalty amount
     */
    function exitPenalty(uint256 tvl, uint256 bondsWithdrawn) internal pure returns (uint256 penalty) {
        // Equation 6: sqrt(TVL_bond + Bonds_Withdrawn)
        // Note: T_bond is added back in the main equation, so penalty is just the sqrt term
        penalty = MathUtils.sqrt(tvl + bondsWithdrawn);
    }

    /**
     * @notice Calculate cooperate yield (simplified)
     * @param tvl Total value locked
     * @param yieldBPS Yield in basis points
     * @return yieldAmount Yield to add
     */
    function cooperateYield(uint256 tvl, uint256 yieldBPS) internal pure returns (uint256 yieldAmount) {
        yieldAmount = (tvl * yieldBPS) / 10_000;
    }
}