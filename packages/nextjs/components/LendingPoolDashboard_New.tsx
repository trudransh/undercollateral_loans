"use client";

import { useState } from "react";
import { useAccount } from "wagmi";
import { parseEther, formatEther } from "viem";
import toast from "react-hot-toast";

interface LendingPool {
  id: string;
  totalDeposits: bigint;
  totalBorrowed: bigint;
  interestRate: number;
  liquidationThreshold: number;
  isActive: boolean;
}

interface UserLoan {
  id: string;
  borrower: string;
  collateralAmount: bigint;
  borrowedAmount: bigint;
  interestRate: number;
  dueDate: number;
  status: 'active' | 'defaulted' | 'frozen' | 'repaid';
  trustBondAddress: string;
  liquidationPrice: bigint;
}

const LendingPoolDashboard = () => {
  const { address } = useAccount();
  const [activeTab, setActiveTab] = useState<'borrow' | 'lend' | 'manage'>('borrow');
  const [borrowAmount, setBorrowAmount] = useState('');
  const [lendAmount, setLendAmount] = useState('');
  const [selectedTrustBond, setSelectedTrustBond] = useState<string>('');

  // Mock data - replace with actual contract calls
  const mockLendingPools: LendingPool[] = [
    {
      id: '1',
      totalDeposits: parseEther('1000'),
      totalBorrowed: parseEther('800'),
      interestRate: 5.5,
      liquidationThreshold: 80,
      isActive: true
    }
  ];

  const mockUserLoans: UserLoan[] = [
    {
      id: '1',
      borrower: address || '0x0',
      collateralAmount: parseEther('100'),
      borrowedAmount: parseEther('80'),
      interestRate: 5.5,
      dueDate: Date.now() + 86400000 * 30, // 30 days
      status: 'active',
      trustBondAddress: '0x123...',
      liquidationPrice: parseEther('120')
    }
  ];

  const mockTrustBonds = [
    { address: '0x123...ABC', partner: '0xabc...DEF', stake: parseEther('100'), isActive: true },
    { address: '0x456...GHI', partner: '0xdef...JKL', stake: parseEther('200'), isActive: true },
  ];

  const handleBorrow = async () => {
    if (!borrowAmount || !selectedTrustBond) {
      toast.error("[ERROR] PLEASE_FILL_ALL_FIELDS");
      return;
    }

    try {
      toast.success(`[SUCCESS] BORROWING_${borrowAmount}_ETH`);
      setBorrowAmount('');
      setSelectedTrustBond('');
    } catch (error) {
      toast.error("[ERROR] BORROWING_FAILED");
      console.error(error);
    }
  };

  const handleLend = async () => {
    if (!lendAmount) {
      toast.error("[ERROR] PLEASE_ENTER_AMOUNT");
      return;
    }

    try {
      toast.success(`[SUCCESS] LENDING_${lendAmount}_ETH`);
      setLendAmount('');
    } catch (error) {
      toast.error("[ERROR] LENDING_FAILED");
      console.error(error);
    }
  };

  const handleSlash = async (loanId: string) => {
    try {
      toast.success(`[SUCCESS] SLASHING_LOAN_${loanId}`);
    } catch (error) {
      toast.error("[ERROR] SLASHING_FAILED");
      console.error(error);
    }
  };

  const handleFreeze = async (loanId: string) => {
    try {
      toast.success(`[SUCCESS] FREEZING_LOAN_${loanId}`);
    } catch (error) {
      toast.error("[ERROR] FREEZE_FAILED");
      console.error(error);
    }
  };

  const handleUnfreeze = async (loanId: string) => {
    try {
      toast.success(`[SUCCESS] UNFREEZING_LOAN_${loanId}`);
    } catch (error) {
      toast.error("[ERROR] UNFREEZE_FAILED");
      console.error(error);
    }
  };

  const handleDefault = async (loanId: string) => {
    try {
      toast.success(`[SUCCESS] MARKING_DEFAULT_${loanId}`);
    } catch (error) {
      toast.error("[ERROR] DEFAULT_FAILED");
      console.error(error);
    }
  };

  return (
    <div className="container mx-auto px-4 py-8 max-w-6xl">
      <div className="mb-8 text-center">
        <h1 className="retro-title text-5xl mb-4 glitch">LENDING_POOL_v3.2</h1>
        <div className="font-mono text-lg border-2 border-base-content p-4 bg-base-100">
          {'>'} BORROW_AGAINST_TRUST_BONDS_OR_LEND_TO_EARN_YIELD
        </div>
      </div>

      {/* Retro Terminal Navigation */}
      <div className="flex space-x-2 mb-8 justify-center">
        {['borrow', 'lend', 'manage'].map((tab) => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab as any)}
            className={`btn font-mono uppercase ${
              activeTab === tab ? 'btn-primary' : 'btn-ghost'
            }`}
          >
            [{tab}_MODE]
          </button>
        ))}
      </div>

      {/* Pool Status Terminal */}
      <div className="mb-8">
        {mockLendingPools.map((pool) => (
          <div key={pool.id} className="card bg-base-100 p-6">
            <h3 className="retro-subtitle text-2xl mb-6 text-center">[POOL_STATUS_TERMINAL]</h3>
            <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
              <div className="border-2 border-base-content p-4 text-center">
                <div className="font-mono text-sm mb-2">TOTAL_DEPOSITS:</div>
                <div className="font-mono text-2xl font-bold">{formatEther(pool.totalDeposits)} ETH</div>
              </div>
              <div className="border-2 border-base-content p-4 text-center">
                <div className="font-mono text-sm mb-2">TOTAL_BORROWED:</div>
                <div className="font-mono text-2xl font-bold">{formatEther(pool.totalBorrowed)} ETH</div>
              </div>
              <div className="border-2 border-base-content p-4 text-center">
                <div className="font-mono text-sm mb-2">INTEREST_RATE:</div>
                <div className="font-mono text-2xl font-bold blink">{pool.interestRate}%</div>
              </div>
              <div className="border-2 border-base-content p-4 text-center">
                <div className="font-mono text-sm mb-2">UTILIZATION:</div>
                <div className="font-mono text-2xl font-bold">
                  {((Number(pool.totalBorrowed) / Number(pool.totalDeposits)) * 100).toFixed(1)}%
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Terminal Tab Content */}
      {activeTab === 'borrow' && (
        <div className="card bg-base-100 p-8">
          <h2 className="retro-subtitle text-2xl mb-8 text-center">[BORROW_AGAINST_TRUST_BONDS]</h2>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
            <div className="border-2 border-base-content p-6">
              <label className="block font-mono text-sm font-bold mb-4">
                SELECT_TRUST_BOND_COLLATERAL:
              </label>
              <select
                value={selectedTrustBond}
                onChange={(e) => setSelectedTrustBond(e.target.value)}
                className="input w-full font-mono"
              >
                <option value="">SELECT_TRUST_BOND...</option>
                {mockTrustBonds.map((bond, index) => (
                  <option key={index} value={bond.address}>
                    {bond.address} - {formatEther(bond.stake)} ETH
                  </option>
                ))}
              </select>
              
              {selectedTrustBond && (
                <div className="mt-4 p-4 border border-base-content bg-base-200">
                  <div className="font-mono text-sm space-y-2">
                    <div>{'>'} COLLATERAL_VALUE: 100 ETH</div>
                    <div>{'>'} MAX_BORROW: 80 ETH (80%)</div>
                    <div>{'>'} LIQUIDATION_THRESHOLD: 120 ETH</div>
                    <div className="badge badge-outline mt-2">STATUS: ACTIVE</div>
                  </div>
                </div>
              )}
            </div>

            <div className="border-2 border-base-content p-6">
              <label className="block font-mono text-sm font-bold mb-4">
                BORROW_AMOUNT_(ETH):
              </label>
              <input
                type="number"
                value={borrowAmount}
                onChange={(e) => setBorrowAmount(e.target.value)}
                placeholder="0.0"
                className="input w-full font-mono text-2xl"
              />
              
              {borrowAmount && (
                <div className="mt-4 p-3 border border-base-content bg-base-200">
                  <div className="font-mono text-sm space-y-1">
                    <div>{'>'} REQUESTED: {borrowAmount} ETH</div>
                    <div>{'>'} INTEREST: {(parseFloat(borrowAmount) * 0.055).toFixed(4)} ETH/YEAR</div>
                    <div>{'>'} TOTAL_REPAY: {(parseFloat(borrowAmount) * 1.055).toFixed(4)} ETH</div>
                  </div>
                </div>
              )}
            </div>
          </div>

          <button
            onClick={handleBorrow}
            disabled={!borrowAmount || !selectedTrustBond}
            className="btn btn-primary w-full mt-8 text-xl glitch"
          >
            [EXECUTE_BORROW] {borrowAmount || '0'} ETH
          </button>
        </div>
      )}

      {activeTab === 'lend' && (
        <div className="card bg-base-100 p-8">
          <h2 className="retro-subtitle text-2xl mb-8 text-center">[LEND_TO_EARN_YIELD]</h2>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
            <div className="border-2 border-base-content p-6">
              <label className="block font-mono text-sm font-bold mb-4">
                LEND_AMOUNT_(ETH):
              </label>
              <input
                type="number"
                value={lendAmount}
                onChange={(e) => setLendAmount(e.target.value)}
                placeholder="0.0"
                className="input w-full font-mono text-2xl"
              />
              
              {lendAmount && (
                <div className="mt-4 p-3 border border-base-content bg-base-200">
                  <div className="font-mono text-sm space-y-1">
                    <div>{'>'} AMOUNT: {lendAmount} ETH</div>
                    <div>{'>'} ANNUAL_YIELD: {(parseFloat(lendAmount) * 0.055).toFixed(4)} ETH</div>
                    <div>{'>'} MONTHLY_YIELD: {(parseFloat(lendAmount) * 0.055 / 12).toFixed(6)} ETH</div>
                  </div>
                </div>
              )}
            </div>

            <div className="border-2 border-base-content p-6">
              <h4 className="retro-subtitle mb-4">[LENDING_TERMS]</h4>
              <div className="font-mono text-sm space-y-3">
                <div className="border border-base-content p-3">
                  <div>APY: 5.5%</div>
                </div>
                <div className="border border-base-content p-3">
                  <div>COMPOUND: DAILY</div>
                </div>
                <div className="border border-base-content p-3">
                  <div>WITHDRAWAL: ANYTIME</div>
                </div>
                <div className="border border-base-content p-3">
                  <div>RISK: TRUST_BOND_BACKED</div>
                </div>
              </div>
            </div>
          </div>

          <button
            onClick={handleLend}
            disabled={!lendAmount}
            className="btn btn-primary w-full mt-8 text-xl glitch"
          >
            [EXECUTE_LEND] {lendAmount || '0'} ETH
          </button>
        </div>
      )}

      {activeTab === 'manage' && (
        <div className="space-y-8">
          <div className="card bg-base-100 p-8">
            <h2 className="retro-subtitle text-2xl mb-8 text-center">[ACTIVE_LOANS_MANAGEMENT]</h2>
            
            <div className="space-y-6">
              {mockUserLoans.map((loan) => (
                <div key={loan.id} className="border-2 border-base-content p-6">
                  <div className="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
                    <div className="text-center p-3 border border-base-content">
                      <p className="font-mono text-sm mb-1">COLLATERAL</p>
                      <p className="font-mono text-lg font-bold">{formatEther(loan.collateralAmount)} ETH</p>
                    </div>
                    <div className="text-center p-3 border border-base-content">
                      <p className="font-mono text-sm mb-1">BORROWED</p>
                      <p className="font-mono text-lg font-bold">{formatEther(loan.borrowedAmount)} ETH</p>
                    </div>
                    <div className="text-center p-3 border border-base-content">
                      <p className="font-mono text-sm mb-1">INTEREST_RATE</p>
                      <p className="font-mono text-lg font-bold">{loan.interestRate}%</p>
                    </div>
                    <div className="text-center p-3 border border-base-content">
                      <p className="font-mono text-sm mb-1">STATUS</p>
                      <div className={`badge badge-outline font-mono ${
                        loan.status === 'active' ? 'badge-primary' :
                        loan.status === 'frozen' ? 'badge-warning' :
                        loan.status === 'defaulted' ? 'badge-error' :
                        'badge-success'
                      }`}>
                        {loan.status.toUpperCase()}
                      </div>
                    </div>
                  </div>

                  <div className="flex flex-wrap gap-3 justify-center">
                    {loan.status === 'active' && (
                      <>
                        <button
                          onClick={() => handleFreeze(loan.id)}
                          className="btn btn-warning font-mono"
                        >
                          [FREEZE_LOAN]
                        </button>
                        <button
                          onClick={() => handleSlash(loan.id)}
                          className="btn btn-error font-mono"
                        >
                          [SLASH_COLLATERAL]
                        </button>
                        <button
                          onClick={() => handleDefault(loan.id)}
                          className="btn btn-error font-mono"
                        >
                          [MARK_DEFAULT]
                        </button>
                      </>
                    )}
                    
                    {loan.status === 'frozen' && (
                      <button
                        onClick={() => handleUnfreeze(loan.id)}
                        className="btn btn-primary font-mono"
                      >
                        [UNFREEZE_LOAN]
                      </button>
                    )}

                    <button className="btn btn-ghost font-mono">
                      [VIEW_DETAILS]
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Yield Recovery Section */}
          <div className="card bg-base-100 p-8">
            <h2 className="retro-subtitle text-2xl mb-8 text-center">[YIELD_RECOVERY_SYSTEM]</h2>
            <div className="font-mono text-center mb-8">
              {'>'} RECOVER_FUNDS_FROM_DEFAULTED_LOANS_THROUGH_TRUST_BOND_YIELD
            </div>
            
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
              <div className="p-6 border-2 border-base-content text-center">
                <p className="font-mono text-sm mb-2">AVAILABLE_YIELD</p>
                <p className="font-mono text-3xl font-bold text-primary">2.34 ETH</p>
              </div>
              <div className="p-6 border-2 border-base-content text-center">
                <p className="font-mono text-sm mb-2">RECOVERY_PENDING</p>
                <p className="font-mono text-3xl font-bold blink">1.87 ETH</p>
              </div>
              <div className="p-6 border-2 border-base-content text-center">
                <p className="font-mono text-sm mb-2">TOTAL_RECOVERED</p>
                <p className="font-mono text-3xl font-bold">15.42 ETH</p>
              </div>
            </div>

            <button className="btn btn-primary w-full text-xl font-mono glitch">
              [CLAIM_AVAILABLE_YIELD]
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

export default LendingPoolDashboard;