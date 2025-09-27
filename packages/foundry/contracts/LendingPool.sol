// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ITrustContract } from "./ITrustContract.sol";
import { ITrustScore } from "./ITrustScore.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract LendingPool is Ownable, ReentrancyGuard {
    
    // ============= STRUCTS =============
    
    struct Loan {
        uint256 id;
        address borrower;
        uint256 amount;
        uint256 interestRate;
        uint256 duration;
        uint256 startTime;
        bool isActive;
        bool isRepaid;
        bool isPaydayLoan;
    }
    
    // ============= STATE VARIABLES =============
    
    ITrustContract public immutable trustContract;
    ITrustScore public immutable trustScore;
    
    uint256 public nextLoanId = 1;
    uint256 public totalLiquidity;
    uint256 public constant MAX_LTV = 8000; // 80% in basis points
    uint256 public constant BASE_INTEREST_RATE = 500; // 5% in basis points
    
    mapping(uint256 => Loan) public loans;
    mapping(address => uint256[]) public userLoans;
    mapping(address => uint256) public userToLoan;
    
    // ============= EVENTS =============
    
    event LoanCreated(uint256 indexed loanId, address indexed borrower, uint256 amount, uint256 interestRate, bool isPaydayLoan);
    event AllContractsFrozen(address indexed user, uint256 indexed loanId, bool frozen);
    event LoanRepaid(uint256 indexed loanId, uint256 amount);
    event LoanDefaulted(uint256 indexed loanId, uint256 amount);
    event YieldsClaimed(uint256 indexed loanId, uint256 totalYields);
    
    // ============= CONSTRUCTOR =============
    
    constructor(address _trustContract, address _trustScore) Ownable(msg.sender) {
        trustContract = ITrustContract(_trustContract);
        trustScore = ITrustScore(_trustScore);
    }
    
    // ============= CORE LENDING FUNCTIONS =============
    
    /**
     * @notice Create a regular loan using ALL user's trust contracts as collateral
     */
    function borrow(uint256 amount, uint256 duration) external nonReentrant {
        require(amount > 0, "Invalid amount");
        require(duration >= 86400, "Duration too short");
        require(userToLoan[msg.sender] == 0, "User has active loan");

        // Calculate max borrowable amount - SIMPLIFIED
        uint256 trustScoreValue = trustScore.getUserTrustScore(msg.sender);
        uint256 totalValue = trustContract.getUserTotalValue(msg.sender);
        
        // Simple calculation: Trust score contribution + 80% of contract value
        uint256 trustContribution = trustScoreValue * 1e16; // 0.01 ETH per trust point
        uint256 collateralContribution = (totalValue * MAX_LTV) / 10000; // 80% of contract value
        uint256 maxBorrowable = trustContribution + collateralContribution;

        require(amount <= maxBorrowable, "Amount exceeds max borrowable");

        // Freeze all user contracts
        trustContract.freezeAllUserContracts(msg.sender, true);

        // Create loan
        uint256 loanId = nextLoanId++;
        loans[loanId] = Loan({
            id: loanId,
            borrower: msg.sender,
            amount: amount,
            interestRate: _calculateInterestRate(msg.sender),
            duration: duration,
            startTime: block.timestamp,
            isActive: true,
            isRepaid: false,
            isPaydayLoan: false
        });
        
        userLoans[msg.sender].push(loanId);
        userToLoan[msg.sender] = loanId;
        
        // Transfer funds to borrower
        require(address(this).balance >= amount, "Insufficient liquidity");
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
        
        emit LoanCreated(loanId, msg.sender, amount, loans[loanId].interestRate, false);
        emit AllContractsFrozen(msg.sender, loanId, true);
    }
    
    /**
     * @notice Repay a loan and unfreeze all user contracts
     */
    function repay(uint256 loanId) external payable nonReentrant {
        Loan storage loan = loans[loanId];
        require(loan.borrower == msg.sender, "Not borrower");
        require(loan.isActive, "Loan inactive");
        require(!loan.isRepaid, "Already repaid");
        
        // Calculate total repayment (principal + interest)
        uint256 elapsedTime = block.timestamp - loan.startTime;
        uint256 interest = (loan.amount * loan.interestRate * elapsedTime) / (365 days * 10000);
        uint256 totalRepayment = loan.amount + interest;
        
        require(msg.value >= totalRepayment, "Insufficient payment");
        
        // Mark as repaid
        loan.isRepaid = true;
        loan.isActive = false;
        delete userToLoan[msg.sender];
        
        // Unfreeze all user contracts
        trustContract.freezeAllUserContracts(msg.sender, false);
        
        // Refund excess payment
        if (msg.value > totalRepayment) {
            (bool success, ) = payable(msg.sender).call{value: msg.value - totalRepayment}("");
            require(success, "Refund failed");
        }
        
        emit LoanRepaid(loanId, totalRepayment);
        emit AllContractsFrozen(msg.sender, loanId, false);
    }
    
    /**
     * @notice Handle loan default - claim yields and slash trust scores
     */
    function liquidate(uint256 loanId) external onlyOwner {
        Loan storage loan = loans[loanId];
        require(loan.isActive, "Loan inactive");
        require(!loan.isRepaid, "Already repaid");
        require(block.timestamp > loan.startTime + loan.duration, "Not expired");
        
        // Mark as defaulted
        loan.isActive = false;
        delete userToLoan[loan.borrower];
        
        // Claim yields from all frozen contracts
        uint256 totalYieldsClaimed = _claimAllUserYields(loan.borrower);
        
        // Unfreeze all contracts
        trustContract.freezeAllUserContracts(loan.borrower, false);
        
        emit LoanDefaulted(loanId, loan.amount);
        emit YieldsClaimed(loanId, totalYieldsClaimed);
        emit AllContractsFrozen(loan.borrower, loanId, false);
    }
    
    // ============= INTERNAL FUNCTIONS =============
    
    /**
     * @notice Calculate interest rate based on trust score
     */
    function _calculateInterestRate(address user) internal view returns (uint256) {
        uint256 userTrustScore = trustScore.getUserTrustScore(user);
        
        // Base rate 5%, reduced by trust score (1% discount per 100 trust points)
        uint256 discount = userTrustScore / 100;
        uint256 finalRate = BASE_INTEREST_RATE > discount ? BASE_INTEREST_RATE - discount : 100; // Min 1%
        
        return finalRate;
    }
    
    /**
     * @notice Claim yields from all user's contracts
     */
    function _claimAllUserYields(address user) internal returns (uint256) {
        bytes32[] memory userContracts = trustContract.getUserContracts(user);
        uint256 totalClaimed = 0;
        
        for (uint256 i = 0; i < userContracts.length; i++) {
            bytes32 contractKey = userContracts[i];
            ITrustContract.contractView memory contractData = trustContract.getContract(contractKey);
            
            if (contractData.isActive && contractData.isFrozen) {
                // Calculate and claim yields for this contract
                uint256 projectedYield = trustContract.getProjectedYield(contractKey);
                totalClaimed += projectedYield;
            }
        }
        
        // Actually claim the yields (this will transfer ETH to the protocol)
        trustContract.claimAllUserYields(user);
        
        return totalClaimed;
    }
    
    // ============= VIEW FUNCTIONS =============
    
    function getLoan(uint256 loanId) external view returns (Loan memory) {
        return loans[loanId];
    }
    
    function getUserLoans(address user) external view returns (uint256[] memory) {
        return userLoans[user];
    }
    
    function getUserLoan(address user) external view returns (uint256) {
        return userToLoan[user];
    }
    
    function getMaxBorrowableAmount(address user) external view returns (uint256) {
        uint256 trustScoreValue = trustScore.getUserTrustScore(user);
        uint256 totalValue = trustContract.getUserTotalValue(user);
        
        uint256 trustContribution = trustScoreValue * 1e16;
        uint256 collateralContribution = (totalValue * MAX_LTV) / 10000;
        
        return trustContribution + collateralContribution;
    }
    
    function calculateRepaymentAmount(uint256 loanId) external view returns (uint256) {
        Loan memory loan = loans[loanId];
        if (!loan.isActive) return 0;
        
        uint256 elapsedTime = block.timestamp - loan.startTime;
        uint256 interest = (loan.amount * loan.interestRate * elapsedTime) / (365 days * 10000);
        
        return loan.amount + interest;
    }
    
    // ============= ADMIN FUNCTIONS =============
    
    function addLiquidity() external payable onlyOwner {
        totalLiquidity += msg.value;
    }
    
    function withdrawLiquidity(uint256 amount) external onlyOwner {
        require(amount <= totalLiquidity, "Insufficient liquidity");
        totalLiquidity -= amount;
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "Withdrawal failed");
    }
    
    // Allow contract to receive ETH
    receive() external payable {
        totalLiquidity += msg.value;
    }
}