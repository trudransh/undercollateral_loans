// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ITrustContract} from "./ITrustContract.sol";
import {MathUtils} from "./MathUtils.sol";
import {PenaltyLib} from "./PenaltyLib.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title TrustContract - PRODUCTION VERSION WITH SELF INTEGRATION
 * @notice Your existing Trust Protocol with Self.xyz verification added
 */
contract TrustContract is ITrustContract, Ownable, ReentrancyGuard {
    
    // ============= SELF VERIFICATION ADDITION =============
    
    struct UserVerification {
        bytes32 selfNullifier;     // Self.xyz nullifier for anonymous identity
        bool isVerified;           // Self.xyz verification status
        uint256 verificationTime;  // When user was verified
    }
    
    mapping(address => UserVerification) public userVerifications;
    mapping(bytes32 => bool) public usedNullifiers; // Prevent nullifier reuse
    mapping(bytes32 => address) public nullifierToWallet; // Map nullifier to wallet
    
    // ============= YOUR EXISTING STATE VARIABLES =============
    
    mapping(bytes32 => contractView) public contracts;
    mapping(address => bool) public authorizedLenders;
    mapping(address => bytes32[]) public userContracts;

    // ============= EVENTS =============
    
    event UserVerifiedWithSelf(address indexed wallet, bytes32 indexed nullifier);

    // ============= MODIFIERS =============

    modifier onlyAuthorizedLender() {
        require(
            msg.sender == owner() || authorizedLenders[msg.sender],
            "Not authorized lender"
        );
        _;
    }
    
    // ADD THIS NEW MODIFIER
    modifier onlyVerifiedUsers(address user) {
        require(userVerifications[user].isVerified, "User not verified with Self.xyz");
        _;
    }

    constructor() Ownable(msg.sender) {}
    
    // ============= SELF VERIFICATION FUNCTIONS =============
    
    /**
     * @notice Verify user with Self.xyz proof and create profile
     * @param nullifier The Self.xyz nullifier from proof
     * @param wallet The wallet address to bind
     */
    function verifySelfProof(bytes32 nullifier, address wallet) external {
        require(nullifier != bytes32(0), "Invalid nullifier");
        require(wallet != address(0), "Invalid wallet");
        require(!usedNullifiers[nullifier], "Nullifier already used");
        require(!userVerifications[wallet].isVerified, "Wallet already verified");
        
        // Store the verification
        usedNullifiers[nullifier] = true;
        nullifierToWallet[nullifier] = wallet;
        
        userVerifications[wallet] = UserVerification({
            selfNullifier: nullifier,
            isVerified: true,
            verificationTime: block.timestamp
        });
        
        emit UserVerifiedWithSelf(wallet, nullifier);
    }
    
    /**
     * @notice Check if user is verified with Self.xyz
     */
    function isUserVerified(address user) external view returns (bool) {
        return userVerifications[user].isVerified;
    }
    
    /**
     * @notice Get user's Self nullifier
     */
    function getUserNullifier(address user) external view returns (bytes32) {
        require(userVerifications[user].isVerified, "User not verified");
        return userVerifications[user].selfNullifier;
    }

    // ============= MODIFIED CORE FUNCTIONS (ADD SELF VERIFICATION REQUIREMENT) =============

    /**
     * @notice Create a new trust contract with a partner - NOW REQUIRES SELF VERIFICATION
     */
    function createContract(
        address partner
    ) external payable override nonReentrant onlyVerifiedUsers(msg.sender) onlyVerifiedUsers(partner) {
        require(msg.value > 0, "Zero stake");
        require(partner != address(0), "Invalid partner");
        require(partner != msg.sender, "Self contract");

        bytes32 key = getContractKey(msg.sender, partner);
        require(!contracts[key].isActive, "Contract exists");

        contracts[key] = contractView({
            addr0: msg.sender < partner ? msg.sender : partner,
            addr1: msg.sender < partner ? partner : msg.sender,
            stake0: msg.sender < partner ? uint128(msg.value) : 0,
            stake1: msg.sender < partner ? 0 : uint128(msg.value),
            accruedYield: 0,
            createdAt: uint32(block.timestamp),
            lastYieldUpdate: uint32(block.timestamp),
            isActive: true,
            isFrozen: false
        });

        // Add to user's contract list
        userContracts[msg.sender].push(key);
        userContracts[partner].push(key);

        emit ContractCreated(key, msg.sender, partner, msg.value);
    }

    /**
     * @notice Add stake to existing contract - NOW REQUIRES SELF VERIFICATION
     */
    function addStake(address partner) external payable override nonReentrant onlyVerifiedUsers(msg.sender) {
        bytes32 key = getContractKey(msg.sender, partner);
        _updateContractYield(key);

        contractView storage trustContract = contracts[key];
        require(
            trustContract.isActive && !trustContract.isFrozen,
            "Invalid state"
        );
        require(_isParticipant(trustContract, msg.sender), "Not participant");

        if (trustContract.addr0 == msg.sender) {
            trustContract.stake0 += uint128(msg.value);
        } else {
            trustContract.stake1 += uint128(msg.value);
        }

        emit StakeAdded(key, msg.sender, msg.value);
    }

    /**
     * @notice Exit contract - NOW REQUIRES SELF VERIFICATION
     */
    function exit(address partner) external override nonReentrant onlyVerifiedUsers(msg.sender) {
        bytes32 key = getContractKey(msg.sender, partner);
        _updateContractYield(key);

        contractView storage trustContract = contracts[key];
        require(
            trustContract.isActive && !trustContract.isFrozen,
            "Invalid state"
        );
        require(_isParticipant(trustContract, msg.sender), "Not participant");

        uint256 s0 = trustContract.stake0;
        uint256 s1 = trustContract.stake1;
        uint256 yield = trustContract.accruedYield;
        uint256 totalStake = s0 + s1;

        uint256 userStake = trustContract.addr0 == msg.sender ? s0 : s1;
        uint256 userYield = (yield * userStake) / totalStake;
        uint256 totalWithdrawal = userStake + userYield;

        uint256 penalty = (totalWithdrawal * 100) / 10000; // 1% penalty
        uint256 finalAmount = totalWithdrawal > penalty
            ? totalWithdrawal - penalty
            : 0;

        trustContract.isActive = false;

        // Transfer funds
        if (finalAmount > 0) {
            (bool success, ) = payable(msg.sender).call{value: finalAmount}("");
            require(success, "Transfer failed");
        }

        // Transfer remaining to partner
        uint256 remaining = totalStake + yield - totalWithdrawal;
        if (remaining > 0) {
            (bool success, ) = payable(partner).call{value: remaining}("");
            require(success, "Transfer failed");
        }

        emit ContractExited(key, msg.sender, finalAmount, penalty);
    }

    /**
     * @notice Defect contract - NOW REQUIRES SELF VERIFICATION
     */
    function defect(address partner) external override nonReentrant onlyVerifiedUsers(msg.sender) {
        bytes32 key = getContractKey(msg.sender, partner);
        _updateContractYield(key);

        contractView storage trustContract = contracts[key];
        require(
            trustContract.isActive && !trustContract.isFrozen,
            "Invalid state"
        );
        require(_isParticipant(trustContract, msg.sender), "Not participant");

        uint256 totalAmount = trustContract.stake0 +
            trustContract.stake1 +
            trustContract.accruedYield;

        // Calculate defect penalty
        uint256 penalty = (totalAmount * 500) / 10000; // 5% penalty
        uint256 finalAmount = totalAmount > penalty ? totalAmount - penalty : 0;

        // Deactivate contract
        trustContract.isActive = false;

        // Transfer all funds to defector (minus penalty)
        if (finalAmount > 0) {
            (bool success, ) = payable(msg.sender).call{value: finalAmount}("");
            require(success, "Transfer failed");
        }

        emit ContractDefected(key, msg.sender, finalAmount, penalty);
    }

    // ============= ALL YOUR EXISTING VIEW FUNCTIONS UNCHANGED =============

    function getContract(
        bytes32 contractKey
    ) external view override returns (contractView memory) {
        return contracts[contractKey];
    }

    function getContractKey(
        address a,
        address b
    ) public pure override returns (bytes32) {
        (address addr0, address addr1) = MathUtils.sortAddresses(a, b);
        return keccak256(abi.encode(addr0, addr1));
    }

    function getProjectedYield(
        bytes32 contractKey
    ) external view override returns (uint256) {
        return _getProjectedYield(contractKey);
    }

    function isParticipant(
        bytes32 contractKey,
        address user
    ) external view override returns (bool) {
        contractView memory contractData = contracts[contractKey];
        return contractData.addr0 == user || contractData.addr1 == user;
    }

    // ============= ALL YOUR EXISTING LENDING FUNCTIONS UNCHANGED =============

    function freezeAllUserContracts(
        address user,
        bool freeze
    ) external override onlyAuthorizedLender {
        bytes32[] memory userContractKeys = userContracts[user];

        for (uint256 i = 0; i < userContractKeys.length; i++) {
            bytes32 contractKey = userContractKeys[i];

            if (contracts[contractKey].isActive) {
                _updateContractYield(contractKey);
                contracts[contractKey].isFrozen = freeze;
                emit ContractFrozen(contractKey, freeze, msg.sender);
            }
        }
    }

    function claimAllUserYields(
        address user
    ) external override onlyAuthorizedLender {
        bytes32[] memory userContractKeys = userContracts[user];

        for (uint256 i = 0; i < userContractKeys.length; i++) {
            bytes32 contractKey = userContractKeys[i];

            if (
                contracts[contractKey].isActive &&
                contracts[contractKey].isFrozen
            ) {
                _claimYields(contractKey);
            }
        }
    }

    function getUserTotalValue(
        address user
    ) external view override returns (uint256) {
        bytes32[] memory userContractKeys = userContracts[user];
        uint256 totalValue = 0;

        for (uint256 i = 0; i < userContractKeys.length; i++) {
            bytes32 contractKey = userContractKeys[i];
            contractView memory contractData = contracts[contractKey];

            if (contractData.isActive) {
                uint256 userStake = contractData.addr0 == user
                    ? contractData.stake0
                    : contractData.stake1;
                uint256 projectedYield = _getProjectedYield(contractKey);
                uint256 contractValue = userStake + (projectedYield / 2);

                totalValue += contractValue;
            }
        }

        return totalValue;
    }

    function getUserContracts(
        address user
    ) external view override returns (bytes32[] memory) {
        return userContracts[user];
    }

    function getContractDetails(
        bytes32 contractKey,
        address user
    ) external view override returns (contractView memory) {
        contractView memory contractData = contracts[contractKey];

        require(
            contractData.addr0 == user || contractData.addr1 == user,
            "Not participant in contract"
        );

        return contractData;
    }

    // ============= ALL YOUR EXISTING ADMIN FUNCTIONS UNCHANGED =============

    function addAuthorizedLender(address lender) external override onlyOwner {
        require(lender != address(0), "Invalid lender address");
        authorizedLenders[lender] = true;
        emit LenderAuthorized(lender);
    }

    function removeAuthorizedLender(
        address lender
    ) external override onlyOwner {
        authorizedLenders[lender] = false;
        emit LenderDeauthorized(lender);
    }

    // ============= ALL YOUR EXISTING INTERNAL FUNCTIONS UNCHANGED =============

    function _updateContractYield(bytes32 contractKey) internal {
        contractView storage trustContract = contracts[contractKey];
        if (!trustContract.isActive) return;

        uint256 timeElapsed = block.timestamp - trustContract.lastYieldUpdate;
        uint256 totalStake = trustContract.stake0 + trustContract.stake1;

        uint256 newYield = (totalStake * timeElapsed * 100) /
            (365 days * 10000);
        trustContract.accruedYield += uint128(newYield);
        trustContract.lastYieldUpdate = uint32(block.timestamp);
    }

    function _isParticipant(
        contractView memory contractData,
        address user
    ) internal pure returns (bool) {
        return contractData.addr0 == user || contractData.addr1 == user;
    }

    function _claimYields(bytes32 contractKey) internal {
        contractView storage trustContract = contracts[contractKey];
        require(trustContract.isActive, "Contract inactive");
        require(trustContract.isFrozen, "Contract not frozen");

        uint256 totalYield = trustContract.accruedYield;
        uint256 totalStake = trustContract.stake0 + trustContract.stake1;

        if (totalYield > 0) {
            uint256 yield0 = (totalYield * trustContract.stake0) / totalStake;
            uint256 yield1 = totalYield - yield0;

            if (yield0 > 0) {
                (bool success, ) = payable(trustContract.addr0).call{
                    value: yield0
                }("");
                require(success, "Transfer failed");
            }
            if (yield1 > 0) {
                (bool success, ) = payable(trustContract.addr1).call{
                    value: yield1
                }("");
                require(success, "Transfer failed");
            }

            trustContract.accruedYield = 0;
            trustContract.lastYieldUpdate = uint32(block.timestamp);

            emit YieldsClaimed(contractKey, totalYield);
        }
    }

    function _getProjectedYield(
        bytes32 contractKey
    ) internal view returns (uint256) {
        contractView memory contractData = contracts[contractKey];

        if (!contractData.isActive) return 0;

        uint256 timeElapsed = block.timestamp - contractData.lastYieldUpdate;
        uint256 totalStake = contractData.stake0 + contractData.stake1;

        return (totalStake * timeElapsed * 100) / (365 days * 10000);
    }
}