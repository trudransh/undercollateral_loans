// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ITrustContract
 * @notice Core interface for Trust Protocol contracts - game-theoretic model from whitepaper
 * @dev Implements contract creation (X/Y stakes), actions (cooperate/defect/exit), penalties (ϕ/α)
 */
interface ITrustContract {
    // ============= STRUCTS =============

    struct contractView {
        address addr0; // Lower address (sorted)
        address addr1; // Higher address (sorted)
        uint128 stake0; // ETH staked by addr0
        uint128 stake1; // ETH staked by addr1
        uint128 accruedYield; // Mock yield from cooperate actions
        uint64 t; // Time dimension (cooperate rounds)
        bool isActive; // contract is active
        bool isFrozen; // Frozen for loan collateral
        uint64 createdAt; // Creation timestamp
        uint64 lastActionBlock; // Last action block
    }

    /**
     * @notice Create contract with initial stake X (msg.value)
     * @param partner Address to contract with
     */
    function createcontract(address partner) external payable;

    /**
     * @notice Partner adds stake Y, activates contract
     * @param partner Original contract creator
     */
    function addStake(address partner) external payable;

    /**
     * @notice Cooperate action - both benefit (C,C payoff)
     * @param partner contract partner
     */
    function cooperate(address partner) external;

    /**
     * @notice Defect action - steal all funds, heavy penalty ϕ
     * @param partner contract partner (victim)
     */
    function defect(address partner) external;

    /**
     * @notice Exit action - fair split, mild penalty α
     * @param partner contract partner
     */
    function exit(address partner) external;

    function getTrustScore(address user) external view returns (uint256);

    function getProjectedYield(
        address a,
        address b,
        uint256 rounds
    ) external view returns (uint256);

    function getcontractDetails(
        address a,
        address b
    ) external view returns (contractView memory);

    function iscontractFrozen(
        address a,
        address b
    ) external view returns (bool);

    function freezecontract(address a, address b, bool freeze) external;

    function getcontractKey(
        address a,
        address b
    ) external pure returns (bytes32);

    event contractCreated(
        bytes32 indexed key,
        address indexed a0,
        address indexed a1,
        uint256 initialStake
    );
    event contractActivated(
        bytes32 indexed key,
        uint128 stake0,
        uint128 stake1
    );

    event contractFrozen(bytes32 indexed key, bool frozen, address indexed by);
    event BondCreated(
        bytes32 indexed key,
        address indexed a0,
        address indexed a1,
        uint256 initialStake
    );
    event BondActivated(bytes32 indexed key, uint128 stake0, uint128 stake1);
    event StakeAdded(bytes32 indexed key, address indexed by, uint256 amount);
    event Cooperated(
        bytes32 indexed key,
        address indexed user,
        uint64 newT,
        uint256 yieldAdded
    );
    event Defected(
        bytes32 indexed key,
        address indexed defector,
        uint256 stolen,
        uint256 penalty
    );
    event Exited(bytes32 indexed key, address indexed user, uint256 penalty);
    event BondFrozen(bytes32 indexed key, bool frozen, address indexed by);
}
