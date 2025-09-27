// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ITrustContract } from "./ITrustContract.sol";
import { MathUtils } from "./MathUtils.sol";
import { PenaltyLib } from "./PenaltyLib.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

abstract contract TrustContract is ITrustContract, Ownable, ReentrancyGuard {
    
    uint256 public constant COOPERATE_YIELD_BPS = 100; // 1% TVL per cooperate
    
    
    mapping(bytes32 => contractView) private contracts;
    mapping(address => bytes32[]) private userContracts;
    mapping(address => uint256) private userBreaks;
    mapping(address => uint256) private userExits;
    
    constructor(address initialOwner) Ownable(initialOwner) {

    }
    
    function createBond(address partner) external payable nonReentrant {
        require(msg.value > 0, "Zero stake");
        require(partner != msg.sender && partner != address(0), "Invalid partner");
        
        (address a0, address a1) = MathUtils.sortAddresses(msg.sender, partner);
        bytes32 key = keccak256(abi.encodePacked(a0, a1));
        
        require(contracts[key].createdAt == 0, "Bond exists");
        
        contractView storage bond = contracts[key];
        bond.addr0 = a0;
        bond.addr1 = a1;
        bond.createdAt = uint64(block.timestamp);
        bond.lastActionBlock = uint64(block.number);
        
        
        if (msg.sender == a0) {
            bond.stake0 = uint128(msg.value);
        } else {
            bond.stake1 = uint128(msg.value);
        }
        
        emit BondCreated(key, a0, a1, msg.value);
    }
    
    function addStake(address partner) external payable nonReentrant {
        require(msg.value > 0, "Zero stake");
        
        (address a0, address a1) = MathUtils.sortAddresses(msg.sender, partner);
        bytes32 key = keccak256(abi.encodePacked(a0, a1));
        
        contractView storage bond = contracts[key];
        require(bond.createdAt > 0 && !bond.isActive, "Invalid state");
        
        
        if (msg.sender == a0) {
            require(bond.stake0 == 0, "Already staked");
            bond.stake0 = uint128(msg.value);
        } else {
            require(bond.stake1 == 0, "Already staked");  
            bond.stake1 = uint128(msg.value);
        }
        
        
        if (bond.stake0 > 0 && bond.stake1 > 0) {
            bond.isActive = true;
            userContracts[a0].push(key);
            userContracts[a1].push(key);
            emit BondActivated(key, bond.stake0, bond.stake1);
        }
        
        emit StakeAdded(key, msg.sender, msg.value);
    }
    
    function cooperate(address partner) external {
        bytes32 key = getBondKey(msg.sender, partner);
        contractView storage bond = contracts[key];
        
        require(bond.isActive && !bond.isFrozen, "Invalid state");
        require(_isParticipant(bond, msg.sender), "Not participant");
        
        
        unchecked {
            bond.t += 1;
            bond.lastActionBlock = uint64(block.number);
        }
        
        uint256 tvl = uint256(bond.stake0) + bond.stake1;
        uint256 yieldAdded = PenaltyLib.cooperateYield(tvl, COOPERATE_YIELD_BPS);
        bond.accruedYield += uint128(yieldAdded);
        
        emit Cooperated(key, msg.sender, bond.t, yieldAdded);
    }
    
    function defect(address partner) external nonReentrant {
        bytes32 key = getBondKey(msg.sender, partner);
        contractView storage bond = contracts[key];
        
        require(bond.isActive && !bond.isFrozen, "Invalid state");
        require(_isParticipant(bond, msg.sender), "Not participant");
        
        uint256 total = uint256(bond.stake0) + bond.stake1 + bond.accruedYield;
        uint256 tvl = uint256(bond.stake0) + bond.stake1;
        
        
        uint256 penalty = PenaltyLib.defectPenalty(0, tvl, ++userBreaks[msg.sender]);
        
        
        bond.isActive = false;
        bond.stake0 = 0;
        bond.stake1 = 0; 
        bond.accruedYield = 0;
        
        
        (bool success,) = payable(msg.sender).call{value: total}("");
        require(success, "Transfer failed");
        
        emit Defected(key, msg.sender, total, penalty);
    }
    
    function exit(address partner) external nonReentrant {
        bytes32 key = getBondKey(msg.sender, partner);
        contractView storage bond = contracts[key];
        
        require(bond.isActive && !bond.isFrozen, "Invalid state");
        require(_isParticipant(bond, msg.sender), "Not participant");
        
        uint256 s0 = bond.stake0;
        uint256 s1 = bond.stake1;
        uint256 yield = bond.accruedYield;
        uint256 totalStake = s0 + s1;
        
        
        uint256 yield0 = totalStake > 0 ? (yield * s0) / totalStake : 0;
        uint256 yield1 = yield - yield0;
        
        
        uint256 penalty = PenaltyLib.exitPenalty(totalStake, ++userExits[msg.sender]);
        
        
        bond.isActive = false;
        bond.stake0 = 0;
        bond.stake1 = 0;
        bond.accruedYield = 0;
        
        
        if (s0 + yield0 > 0) {
            (bool ok0,) = payable(bond.addr0).call{value: s0 + yield0}("");
            require(ok0, "Transfer0 failed");
        }
        if (s1 + yield1 > 0) {
            (bool ok1,) = payable(bond.addr1).call{value: s1 + yield1}("");
            require(ok1, "Transfer1 failed");
        }
        
        emit Exited(key, msg.sender, penalty);
    }
    
    
    function getTrustScore(address user) external view returns (uint256) {
        uint256 score;
        bytes32[] memory userBondKeys = userContracts[user];
        for (uint256 i = 0; i < userBondKeys.length; i++) {
            contractView storage bond = contracts[userBondKeys[i]];
            if (bond.isActive) {
                uint256 tvl = uint256(bond.stake0) + bond.stake1;
                score += MathUtils.sqrt(bond.t) * tvl / 100;
            }
        }
        return score;
        
    }
    
    function getProjectedYield(address a, address b, uint256 rounds) external view returns (uint256) {
        contractView memory bond = contracts[getBondKey(a, b)];
        if (!bond.isActive) return 0;
        
        uint256 tvl = uint256(bond.stake0) + bond.stake1;
        uint256 futureYield = rounds * PenaltyLib.cooperateYield(tvl, COOPERATE_YIELD_BPS);
        return bond.accruedYield + futureYield;
    }
    
    function getBondDetails(address a, address b) external view returns (contractView memory) {
        return contracts[getBondKey(a, b)];
    }
    
    function isBondFrozen(address a, address b) external view returns (bool) {
        return contracts[getBondKey(a, b)].isFrozen;
    }
    
    function freezeBond(address a, address b, bool freeze) external {
        require(msg.sender == owner(), "Not authorized"); 
        bytes32 key = getBondKey(a, b);
        require(contracts[key].isActive, "Invalid bond");
        contracts[key].isFrozen = freeze;
        emit BondFrozen(key, freeze, msg.sender);
    }
    
    function getBondKey(address a, address b) public pure returns (bytes32) {
        (address a0, address a1) = MathUtils.sortAddresses(a, b);
        return keccak256(abi.encodePacked(a0, a1));
    }
    
    function _isParticipant(contractView memory bond, address user) private pure returns (bool) {
        return bond.addr0 == user || bond.addr1 == user;
    }
    
    receive() external payable {}
}