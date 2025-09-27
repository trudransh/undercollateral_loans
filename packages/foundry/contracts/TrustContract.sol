// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ITrustContract } from "./ITrustContract.sol";
import { MathUtils } from "./MathUtils.sol";
import { PenaltyLib } from "./PenaltyLib.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title TrustContract
 * @notice Trust Protocol contracts with passive cooperation model
 * @dev Contracts automatically accrue yield over time. Default state is cooperation.
 */
contract TrustContract is ITrustContract, Ownable, ReentrancyGuard {
    
    // Constants
    uint256 public constant DAILY_YIELD_BPS = 100; 
    
    // Storage
    mapping(bytes32 => contractView) private contracts;
    mapping(address => bytes32[]) private userContracts;
    mapping(address => uint256) private userBreaks;
    mapping(address => uint256) private userExits;
    
    constructor(address initialOwner) Ownable(initialOwner) {}
   
    
    /**
     * @notice Calculate automatically accrued yield since last update
     */
    function _calculatePendingYield(contractView storage trustContract) internal view returns (uint256) {
        if (!trustContract.isActive || trustContract.lastYieldUpdate == 0) return 0;
        
        uint256 timePassed = block.timestamp - trustContract.lastYieldUpdate;
        uint256 tvl = uint256(trustContract.stake0) + trustContract.stake1;
        
        // Daily yield: 1% of TVL per day
        uint256 dailyYield = (tvl * DAILY_YIELD_BPS) / 10_000;
        return (dailyYield * timePassed) / 1 days;
    }
    
    /**
     * @notice Update contract yield (called before any state-changing operation)
     */
    function _updateContractYield(bytes32 key) internal {
        contractView storage trustContract = contracts[key];
        if (!trustContract.isActive) return;
        
        uint256 pendingYield = _calculatePendingYield(trustContract);
        if (pendingYield > 0) {
            trustContract.accruedYield += uint128(pendingYield);
            emit YieldAccrued(key, pendingYield, trustContract.accruedYield);
        }
        trustContract.lastYieldUpdate = uint64(block.timestamp);
    }
    
    // ============= CORE FUNCTIONS =============
    
    function createContract(address partner) external payable nonReentrant {
        require(msg.value > 0, "Zero stake");
        require(partner != msg.sender && partner != address(0), "Invalid partner");
        
        (address a0, address a1) = MathUtils.sortAddresses(msg.sender, partner);
        bytes32 key = keccak256(abi.encodePacked(a0, a1));
        
        require(contracts[key].createdAt == 0, "Contract exists");
        
        contractView storage trustContract = contracts[key];
        trustContract.addr0 = a0;
        trustContract.addr1 = a1;
        trustContract.createdAt = uint64(block.timestamp);
        trustContract.lastYieldUpdate = uint64(block.timestamp); // Will start when activated
        
        // Set initial stake
        if (msg.sender == a0) {
            trustContract.stake0 = uint128(msg.value);
        } else {
            trustContract.stake1 = uint128(msg.value);
        }
        
        emit ContractCreated(key, a0, a1, msg.value);
    }
    
    function addStake(address partner) external payable nonReentrant {
        require(msg.value > 0, "Zero stake");
        
        (address a0, address a1) = MathUtils.sortAddresses(msg.sender, partner);
        bytes32 key = keccak256(abi.encodePacked(a0, a1));
        
        contractView storage trustContract = contracts[key];
        require(trustContract.createdAt > 0 && !trustContract.isActive, "Invalid state");
        
        
        if (msg.sender == a0) {
            require(trustContract.stake0 == 0, "Already staked");
            trustContract.stake0 = uint128(msg.value);
        } else {
            require(trustContract.stake1 == 0, "Already staked");  
            trustContract.stake1 = uint128(msg.value);
        }
        
        
        if (trustContract.stake0 > 0 && trustContract.stake1 > 0) {
            trustContract.isActive = true;
            trustContract.lastYieldUpdate = uint64(block.timestamp); // Start earning NOW
            
            userContracts[a0].push(key);
            userContracts[a1].push(key);
            
            emit ContractActivated(key, trustContract.stake0, trustContract.stake1);
        }
        
        emit StakeAdded(key, msg.sender, msg.value);
    }
    
    function defect(address partner) external nonReentrant {
        bytes32 key = getContractKey(msg.sender, partner);
        
        
        _updateContractYield(key);
        
        contractView storage trustContract = contracts[key];
        require(trustContract.isActive && !trustContract.isFrozen, "Invalid state");
        require(_isParticipant(trustContract, msg.sender), "Not participant");
        
        
        uint256 total = uint256(trustContract.stake0) + trustContract.stake1 + trustContract.accruedYield;
        uint256 tvl = uint256(trustContract.stake0) + trustContract.stake1;
        
        
        uint256 penalty = PenaltyLib.defectPenalty(0, tvl, ++userBreaks[msg.sender]);
        
        // Destroy contract
        trustContract.isActive = false;
        trustContract.stake0 = 0;
        trustContract.stake1 = 0; 
        trustContract.accruedYield = 0;
        
        
        (bool success,) = payable(msg.sender).call{value: total}("");
        require(success, "Transfer failed");
        
        emit Defected(key, msg.sender, total, penalty);
    }
    
    function exit(address partner) external nonReentrant {
        bytes32 key = getContractKey(msg.sender, partner);
        
        
        _updateContractYield(key);
        
        contractView storage trustContract = contracts[key];
        require(trustContract.isActive && !trustContract.isFrozen, "Invalid state");
        require(_isParticipant(trustContract, msg.sender), "Not participant");
        
        uint256 s0 = trustContract.stake0;
        uint256 s1 = trustContract.stake1;
        uint256 yield = trustContract.accruedYield;
        uint256 totalStake = s0 + s1;
        
        
        uint256 yield0 = totalStake > 0 ? (yield * s0) / totalStake : 0;
        uint256 yield1 = yield - yield0;
        
        
       uint256 penalty = PenaltyLib.exitPenalty(totalStake, ++userExits[msg.sender]);
        
    
        trustContract.isActive = false;
        trustContract.stake0 = 0;
        trustContract.stake1 = 0;
        trustContract.accruedYield = 0;
        
      
        if (s0 + yield0 > 0) {
            (bool ok0,) = payable(trustContract.addr0).call{value: s0 + yield0}("");
            require(ok0, "Transfer0 failed");
        }
        if (s1 + yield1 > 0) {
            (bool ok1,) = payable(trustContract.addr1).call{value: s1 + yield1}("");
            require(ok1, "Transfer1 failed");
        }
        
        emit Exited(key, msg.sender, penalty);
    }
    
  
    
    function getTrustScore(address user) external view returns (uint256) {
        uint256 score;
        bytes32[] memory userContractKeys = userContracts[user];
        
        for (uint256 i = 0; i < userContractKeys.length; i++) {
            contractView storage trustContract = contracts[userContractKeys[i]];
            if (trustContract.isActive) {
                uint256 tvl = uint256(trustContract.stake0) + trustContract.stake1;
                
                uint256 daysActive = (block.timestamp - trustContract.createdAt) / 1 days;
                score += MathUtils.sqrt(daysActive + 1) * tvl / 100; 
            }
        }
        return score;
    }
    
    function getProjectedYield(address a, address b, uint256 futureDays) external view returns (uint256) {
        contractView storage trustContract = contracts[getContractKey(a, b)];
        if (!trustContract.isActive) return 0;
        
        uint256 currentYield = trustContract.accruedYield;
        uint256 pendingYield = _calculatePendingYield(trustContract);
        
        uint256 tvl = uint256(trustContract.stake0) + trustContract.stake1;
        uint256 dailyYield = (tvl * DAILY_YIELD_BPS) / 10_000;
        uint256 futureYield = dailyYield * futureDays;
        
        return currentYield + pendingYield + futureYield;
    }
    
    function getContractDetails(address a, address b) external view returns (contractView memory) {
        contractView memory trustContract = contracts[getContractKey(a, b)];
        
        if (trustContract.isActive) {
            uint256 pendingYield = _calculatePendingYield(contracts[getContractKey(a, b)]);
            trustContract.accruedYield += uint128(pendingYield);
        }
        
        return trustContract;
    }
    
    function isContractFrozen(address a, address b) external view returns (bool) {
        return contracts[getContractKey(a, b)].isFrozen;
    }
    
    function freezeContract(address a, address b, bool freeze) external {
        require(msg.sender == owner(), "Not authorized");
        bytes32 key = getContractKey(a, b);
        
        
        _updateContractYield(key);
        
        require(contracts[key].isActive, "Invalid contract");
        contracts[key].isFrozen = freeze;
        emit ContractFrozen(key, freeze, msg.sender);
    }
    
    function getContractKey(address a, address b) public pure returns (bytes32) {
        (address a0, address a1) = MathUtils.sortAddresses(a, b);
        return keccak256(abi.encodePacked(a0, a1));
    }
    
    function _isParticipant(contractView memory trustContract, address user) private pure returns (bool) {
        return trustContract.addr0 == user || trustContract.addr1 == user;
    }
    
    receive() external payable {}
}