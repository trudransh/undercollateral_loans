// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ITrustContract
 * @notice Core interface for Trust Protocol contracts - passive cooperation model
 * @dev Contracts earn yield automatically over time. Users only act to EXIT or DEFECT.
 */
interface ITrustContract {
    // ============= STRUCTS =============
    
    struct contractView {
        address addr0;           // Lower address (sorted)
        address addr1;           // Higher address (sorted) 
        uint128 stake0;          // ETH staked by addr0
        uint128 stake1;          // ETH staked by addr1
        uint128 accruedYield;    // Total yield accumulated
        uint32 createdAt;        // Contract creation timestamp
        uint32 lastYieldUpdate;  // Last yield calculation timestamp
        bool isActive;           // Contract is active
        bool isFrozen;           // Contract is frozen (for loans)
    }
    
    // ============= CORE FUNCTIONS =============
    
    /**
     * @notice Create a new trust contract with a partner
     * @param partner The address to create contract with
     */
    function createContract(address partner) external payable;
    
    /**
     * @notice Add stake to existing contract
     * @param partner The contract partner
     */
    function addStake(address partner) external payable;
    
    /**
     * @notice Exit contract - fair withdrawal with mild penalty
     * @param partner The contract partner
     */
    function exit(address partner) external;
    
    /**
     * @notice Defect contract - steal all funds with heavy penalty
     * @param partner The contract partner
     */
    function defect(address partner) external;
    
    // ============= VIEW FUNCTIONS =============
    
    /**
     * @notice Get contract details by key
     * @param contractKey The contract key
     * @return contractData The contract view data
     */
    function getContract(bytes32 contractKey) external view returns (contractView memory);
    
    /**
     * @notice Get contract key for two addresses
     * @param a First address
     * @param b Second address
     * @return key The contract key
     */
    function getContractKey(address a, address b) external pure returns (bytes32);
    
    /**
     * @notice Get projected yield for a contract
     * @param contractKey The contract key
     * @return yield The projected yield amount
     */
    function getProjectedYield(bytes32 contractKey) external view returns (uint256);
    
    /**
     * @notice Check if address is participant in contract
     * @param contractKey The contract key
     * @param user The user address
     * @return isParticipant True if user is participant
     */
    function isParticipant(bytes32 contractKey, address user) external view returns (bool);
    
    // ============= LENDING FUNCTIONS =============
    
    /**
     * @notice Freeze/unfreeze all contracts for a specific user
     * @param user The user whose contracts should be frozen/unfrozen
     * @param freeze True to freeze, false to unfreeze
     */
    function freezeAllUserContracts(address user, bool freeze) external;
    
    /**
     * @notice Claim yields from all user's contracts (for liquidation)
     * @param user The user whose yields should be claimed
     */
    function claimAllUserYields(address user) external;
    
    /**
     * @notice Get total value of all user's contracts
     * @param user The user to calculate total value for
     * @return totalValue Total value across all user's contracts
     */
    function getUserTotalValue(address user) external view returns (uint256);
    
    /**
     * @notice Get all contract keys for a user
     * @param user The user to get contracts for
     * @return contractKeys Array of contract keys
     */
    function getUserContracts(address user) external view returns (bytes32[] memory);
    
    /**
     * @notice Get contract details by key and user
     * @param contractKey The contract key
     * @param user The user to get details for
     * @return contractData The contract view data
     */
    function getContractDetails(bytes32 contractKey, address user) external view returns (contractView memory);
    
    // ============= ADMIN FUNCTIONS =============
    
    /**
     * @notice Add a lending contract as authorized caller
     * @param lender The lending contract address to authorize
     */
    function addAuthorizedLender(address lender) external;
    
    /**
     * @notice Remove a lending contract authorization
     * @param lender The lending contract address to deauthorize
     */
    function removeAuthorizedLender(address lender) external;
    
    // ============= EVENTS =============
    
    event ContractCreated(bytes32 indexed contractKey, address indexed creator, address indexed partner, uint256 amount);
    event StakeAdded(bytes32 indexed contractKey, address indexed user, uint256 amount);
    event ContractExited(bytes32 indexed contractKey, address indexed exiter, uint256 amount, uint256 penalty);
    event ContractDefected(bytes32 indexed contractKey, address indexed defector, uint256 amount, uint256 penalty);
    event ContractFrozen(bytes32 indexed contractKey, bool frozen, address indexed caller);
    event YieldsClaimed(bytes32 indexed contractKey, uint256 amount);
    event LenderAuthorized(address indexed lender);
    event LenderDeauthorized(address indexed lender);
}