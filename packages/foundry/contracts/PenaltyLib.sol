// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { MathUtils } from "./MathUtils.sol";

library PenaltyLib {
    uint256 internal constant PHI = 2;     
    uint256 internal constant ALPHA = 1;    
    
    function defectPenalty(uint256 tBond, uint256 tvl, uint256 breaks) internal pure returns (uint256) {
        uint256 breakCount = breaks == 0 ? 1 : breaks;
        uint256 basePenalty = tBond + MathUtils.sqrt(tvl * breakCount);
        return basePenalty * PHI;
    }

    function exitPenalty(uint256 tvl, uint256 exits) internal pure returns (uint256) {
        return MathUtils.sqrt(tvl + exits) * ALPHA;
    }

    function cooperateYield(uint256 tvl, uint256 cooperateBPS) internal pure returns (uint256) {
        return MathUtils.percentageBPS(tvl, cooperateBPS);
    }
}