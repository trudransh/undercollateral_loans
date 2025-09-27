// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ITrustContract
 * @notice Core interface for Trust Protocol contracts - passive cooperation model
 * @dev Contracts earn yield automatically over time. Users only act to EXIT or DEFECT.
 */
interface ITrustContract {
    
    struct contractView {
        address addr0;           
        address addr1;          
        uint128 stake0;      
        uint128 stake1;          
        uint128 accruedYield;   
        bool isActive;           
        bool isFrozen;           
        uint64 createdAt;    
        uint64 lastYieldUpdate;  
    }
 
    
    /**
     * @notice Create contract with initial stake X (msg.value)
     * @param partner Address to contract with
     */
    function createContract(address partner) external payable;
    
    /**
     * @notice Partner adds stake Y, activates contract and starts automatic yield
     * @param partner Original contract creator
     */
    function addStake(address partner) external payable;
    
    /**
     * @notice Defect action - steal all funds, heavy penalty ϕ
     * @param partner Contract partner (victim)
     */
    function defect(address partner) external;
    
    /**
     * @notice Exit action - fair split, mild penalty α
     * @param partner Contract partner
     */
    function exit(address partner) external;

    
    /**
     * @notice Get user's total trust score across all contracts
     * @param user Address to query
     * @return Trust score based on contract age and TVL
     */
    function getTrustScore(address user) external view returns (uint256);
    
    /**
     * @notice Project future yield over time period
     * @param a First address in contract
     * @param b Second address in contract
     * @param futureDays Number of days to project
     * @return Current + projected yield
     */
    function getProjectedYield(address a, address b, uint256 futureDays) external view returns (uint256);
    
    /**
     * @notice Get complete contract details with current yield
     * @param a First address in contract
     * @param b Second address in contract
     * @return Contract information with updated yield
     */
    function getContractDetails(address a, address b) external view returns (contractView memory);
    
    /**
     * @notice Check if contract is frozen for loan collateral
     * @param a First address in contract
     * @param b Second address in contract
     * @return true if frozen
     */
    function isContractFrozen(address a, address b) external view returns (bool);

    
    /**
     * @notice Freeze/unfreeze contract (called by loan controller)
     * @param a First address in contract
     * @param b Second address in contract
     * @param freeze true to freeze, false to unfreeze
     */
    function freezeContract(address a, address b, bool freeze) external;
    
    /**
     * @notice Generate deterministic key for contract
     * @param a First address
     * @param b Second address
     * @return Unique contract identifier
     */
    function getContractKey(address a, address b) external pure returns (bytes32);

    
    event ContractCreated(bytes32 indexed key, address indexed a0, address indexed a1, uint256 initialStake);
    event ContractActivated(bytes32 indexed key, uint128 stake0, uint128 stake1);
    event StakeAdded(bytes32 indexed key, address indexed by, uint256 amount);
    event YieldAccrued(bytes32 indexed key, uint256 yieldAmount, uint256 totalYield);
    event Defected(bytes32 indexed key, address indexed defector, uint256 stolen, uint256 penalty);
    event Exited(bytes32 indexed key, address indexed user, uint256 penalty);
    event ContractFrozen(bytes32 indexed key, bool frozen, address indexed by);
}