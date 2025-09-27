// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title MathUtils
 * @notice Gas-efficient math operations for Trust Protocol
 * @dev Babylonian square root, address sorting, safe math
 */
library MathUtils {
    /**
     * @notice Babylonian method square root (gas-efficient)
     * @param x Input value
     * @return z Square root of x
     */
    function sqrt(uint256 x) internal pure returns (uint256 z) {
        if (x == 0) return 0;
        uint256 y = x;
        z = (x + 1) >> 1;
        while (z < y) {
            y = z;
            z = (x / z + z) >> 1;
        }
    }

    /**
     * @notice Sort two addresses (deterministic bond keys)
     * @param a First address
     * @param b Second address
     * @return lower Sorted address
     * @return higher Sorted address
     */
    function sortAddresses(address a, address b) internal pure returns (address lower, address higher) {
        require(a != b && a != address(0) && b != address(0), "Invalid addresses");
        return a < b ? (a, b) : (b, a);
    }

    /**
     * @notice Safe percentage calculation with basis points
     * @param amount Base amount
     * @param bps Basis points (1 bps = 0.01%)
     * @return Calculated percentage
     */
    function percentageBPS(uint256 amount, uint256 bps) internal pure returns (uint256) {
        return (amount * bps) / 10_000;
    }
}