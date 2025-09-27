// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ITrustContract } from "./ITrustContract.sol";
import { ITrustScore } from "./ITrustScore.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title LendingPool
 * @notice Under-collateralized lending pool using ALL user trust contracts as collateral
 * @dev Freezes ALL user contracts when loans are taken, unfreezes on repayment/default
 */
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
        bool isPaydayLoan; // For short-term payday loans
    }
    
    // ============= STATE VARIABLES =============
    
    ITrustContract public immutable trustContract;
    ITrustScore public immutable trustScore;
    
    uint256 public nextLoanId = 1;
    uint256 public totalLiquidity;
    uint256 public constant MAX_LTV = 8000; // 80% LTV
    
    mapping(uint256 => Loan) public loans;
    mapping(address => uint256[]) public userLoans;
    mapping(address => uint256) public userToLoan; // Which loan is using this user's contracts
    
    // ============= EVENTS =============
    
    event LoanCreated(
        uint256 indexed loanId,
        address indexed borrower,
        uint256 amount,
        uint256 interestRate,
        bool isPaydayLoan
    );
    
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
     * @param amount Amount to borrow
     * @param duration Loan duration in seconds
     */
    function borrow(
        uint256 amount,
        uint256 duration
    ) external nonReentrant {
        require(amount > 0, "Invalid amount");
        require(duration > 0, "Invalid duration");
        require(userToLoan[msg.sender] == 0, "User has active loan");
        
        // Calculate max borrowable amount based on ALL user contracts
        uint256 maxBorrow = _calculateMaxBorrow(msg.sender);
        require(amount <= maxBorrow, "Amount exceeds limit");
        
        // Create loan
        uint256 loanId = nextLoanId++;
        loans[loanId] = Loan({
            id: loanId,
            borrower: msg.sender,
            amount: amount,
            interestRate: _calculateInterestRate(msg.sender, amount),
            duration: duration,
            startTime: block.timestamp,
            isActive: true,
            isRepaid: false,
            isPaydayLoan: false
        });
        
        userLoans[msg.sender].push(loanId);
        userToLoan[msg.sender] = loanId;
        
        // FREEZE ALL USER'S CONTRACTS
        trustContract.freezeAllUserContracts(msg.sender, true);
        
        // Transfer funds to borrower
        require(address(this).balance >= amount, "Insufficient liquidity");
        payable(msg.sender).transfer(amount);
        
        emit LoanCreated(loanId, msg.sender, amount, loans[loanId].interestRate, false);
        emit AllContractsFrozen(msg.sender, loanId, true);
    }
    
    /**
     * @notice Create a payday loan (short-term, higher rate)
     * @param amount Amount to borrow
     */
    function borrowPayday(uint256 amount) external nonReentrant {
        require(amount > 0, "Invalid amount");
        require(userToLoan[msg.sender] == 0, "User has active loan");
        
        // Payday loans: shorter duration, higher rate, lower limits
        uint256 maxBorrow = _calculateMaxBorrow(msg.sender) / 2; // 50% of regular limit
        require(amount <= maxBorrow, "Amount exceeds payday limit");
        
        uint256 duration = 7 days; // 7 days for payday loans
        
        // Create payday loan
        uint256 loanId = nextLoanId++;
        loans[loanId] = Loan({
            id: loanId,
            borrower: msg.sender,
            amount: amount,
            interestRate: _calculatePaydayInterestRate(msg.sender, amount),
            duration: duration,
            startTime: block.timestamp,
            isActive: true,
            isRepaid: false,
            isPaydayLoan: true
        });
        
        userLoans[msg.sender].push(loanId);
        userToLoan[msg.sender] = loanId;
        
        // FREEZE ALL USER'S CONTRACTS
        trustContract.freezeAllUserContracts(msg.sender, true);
        
        // Transfer funds to borrower
        require(address(this).balance >= amount, "Insufficient liquidity");
        payable(msg.sender).transfer(amount);
        
        emit LoanCreated(loanId, msg.sender, amount, loans[loanId].interestRate, true);
        emit AllContractsFrozen(msg.sender, loanId, true);
    }
    
    /**
     * @notice Repay a loan and unfreeze all user contracts
     * @param loanId ID of the loan to repay
     */
    function repay(uint256 loanId) external payable nonReentrant {
        Loan storage loan = loans[loanId];
        require(loan.borrower == msg.sender, "Not borrower");
        require(loan.isActive, "Loan inactive");
        require(!loan.isRepaid, "Already repaid");
        
        uint256 totalAmount = loan.amount + _calculateInterest(loanId);
        require(msg.value >= totalAmount, "Insufficient payment");
        
        // Mark as repaid
        loan.isRepaid = true;
        loan.isActive = false;
        delete userToLoan[msg.sender];
        
        // UNFREEZE ALL USER'S CONTRACTS
        trustContract.freezeAllUserContracts(msg.sender, false);
        
        // Refund excess payment
        if (msg.value > totalAmount) {
            payable(msg.sender).transfer(msg.value - totalAmount);
        }
        
        emit LoanRepaid(loanId, totalAmount);
        emit AllContractsFrozen(msg.sender, loanId, false);
    }
    
    /**
     * @notice Handle loan default - claim yields and slash trust scores
     * @param loanId ID of the defaulted loan
     */
    function liquidate(uint256 loanId) external onlyOwner {
        Loan storage loan = loans[loanId];
        require(loan.isActive, "Loan inactive");
        require(!loan.isRepaid, "Already repaid");
        require(block.timestamp > loan.startTime + loan.duration, "Not expired");
        
        // Mark as defaulted
        loan.isActive = false;
        delete userToLoan[loan.borrower];
        
        // CLAIM YIELDS FROM ALL FROZEN CONTRACTS
        uint256 totalYieldsClaimed = _claimAllUserYields(loan.borrower);
        
        // Unfreeze all contracts
        trustContract.freezeAllUserContracts(loan.borrower, false);
        
        emit LoanDefaulted(loanId, loan.amount);
        emit YieldsClaimed(loanId, totalYieldsClaimed);
        emit AllContractsFrozen(loan.borrower, loanId, false);
    }
    
    // ============= INTERNAL FUNCTIONS =============
    
    /**
     * @notice Calculate maximum borrowable amount for a user based on ALL their contracts
     */
    function _calculateMaxBorrow(address user) internal view returns (uint256) {
        uint256 totalTrustScore = trustScore.getUserTrustScore(user);
        uint256 totalCollateralValue = trustContract.getUserTotalValue(user);
        
        // Max borrow = min(trust score * factor, collateral value * LTV)
        uint256 trustBasedLimit = totalTrustScore * 2; // 2x trust score
        uint256 collateralBasedLimit = (totalCollateralValue * MAX_LTV) / 10000;
        
        return trustBasedLimit < collateralBasedLimit ? trustBasedLimit : collateralBasedLimit;
    }
    
    /**
     * @notice Calculate interest rate based on trust score
     */
    function _calculateInterestRate(address user, uint256 amount) internal view returns (uint256) {
        uint256 userTrustScore = trustScore.getUserTrustScore(user);
        
        // Base rate 5%, reduced by trust score
        uint256 baseRate = 500; // 5%
        uint256 trustDiscount = userTrustScore / 100; // 1% discount per 100 trust score
        
        return baseRate > trustDiscount ? baseRate - trustDiscount : 100; // Min 1%
    }
    
    /**
     * @notice Calculate payday loan interest rate (higher than regular)
     */
    function _calculatePaydayInterestRate(address user, uint256 amount) internal view returns (uint256) {
        uint256 regularRate = _calculateInterestRate(user, amount);
        return regularRate + 200; // Add 2% for payday loans
    }
    
    /**
     * @notice Calculate interest for a loan
     */
    function _calculateInterest(uint256 loanId) internal view returns (uint256) {
        Loan memory loan = loans[loanId];
        uint256 elapsedTime = block.timestamp - loan.startTime;
        uint256 interest = (loan.amount * loan.interestRate * elapsedTime) / (365 days * 10000);
        return interest;
    }
    
    /**
     * @notice Claim yields from all user's contracts and return total
     */
    function _claimAllUserYields(address user) internal returns (uint256) {
        // Get all user contracts
        bytes32[] memory userContracts = trustContract.getUserContracts(user);
        uint256 totalYields = 0;
        
        for (uint256 i = 0; i < userContracts.length; i++) {
            bytes32 contractKey = userContracts[i];
            ITrustContract.contractView memory contractData = trustContract.getContract(contractKey);
            
            if (contractData.isActive && contractData.isFrozen) {
                // Calculate yields before claiming
                uint256 projectedYield = trustContract.getProjectedYield(contractKey);
                totalYields += projectedYield;
            }
        }
        
        // Claim all yields (this will also slash trust scores)
        trustContract.claimAllUserYields(user);
        
        return totalYields;
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
        return _calculateMaxBorrow(user);
    }
    
    function getPaydayMaxBorrowableAmount(address user) external view returns (uint256) {
        return _calculateMaxBorrow(user) / 2;
    }
    
    // ============= ADMIN FUNCTIONS =============
    
    function addLiquidity() external payable onlyOwner {
        totalLiquidity += msg.value;
    }
    
    function withdrawLiquidity(uint256 amount) external onlyOwner {
        require(amount <= totalLiquidity, "Insufficient liquidity");
        totalLiquidity -= amount;
        payable(owner()).transfer(amount);
    }
    
    // Allow contract to receive ETH
    receive() external payable {
        totalLiquidity += msg.value;
    }
}