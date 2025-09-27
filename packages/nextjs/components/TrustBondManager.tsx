"use client";

import { useState, useEffect } from "react";
import { useAccount, useReadContract, useWriteContract } from "wagmi";
import { parseEther, formatEther, Address } from "viem";
import toast from "react-hot-toast";

interface TrustBond {
  key: string;
  addr0: Address;
  addr1: Address;
  stake0: bigint;
  stake1: bigint;
  accruedYield: bigint;
  isActive: boolean;
  isFrozen: boolean;
  createdAt: number;
  lastYieldUpdate: number;
}

const TrustBondManager = () => {
  const { address } = useAccount();
  const [partnerAddress, setPartnerAddress] = useState<string>('');
  const [stakeAmount, setStakeAmount] = useState<string>('');
  const [activeTab, setActiveTab] = useState<'create' | 'manage' | 'analytics'>('create');

  // Mock trust bonds data - replace with actual contract reads
  const mockTrustBonds: TrustBond[] = [
    {
      key: '0x123...',
      addr0: address || '0x0',
      addr1: '0xabc...',
      stake0: parseEther('100'),
      stake1: parseEther('150'),
      accruedYield: parseEther('5.25'),
      isActive: true,
      isFrozen: false,
      createdAt: Date.now() - 86400000 * 7,
      lastYieldUpdate: Date.now() - 3600000
    },
    {
      key: '0x456...',
      addr0: address || '0x0',
      addr1: '0xdef...',
      stake0: parseEther('200'),
      stake1: parseEther('0'),
      accruedYield: parseEther('0'),
      isActive: false,
      isFrozen: false,
      createdAt: Date.now() - 86400000 * 2,
      lastYieldUpdate: 0
    }
  ];

  const handleCreateTrustBond = async () => {
    if (!partnerAddress || !stakeAmount) {
      toast.error("Please fill all fields");
      return;
    }

    try {
      // Implement actual contract call to createContract
      toast.success(`Creating trust bond with ${partnerAddress} for ${stakeAmount} ETH`);
      setPartnerAddress('');
      setStakeAmount('');
    } catch (error) {
      toast.error("Failed to create trust bond");
      console.error(error);
    }
  };

  const handleAddStake = async (bondKey: string, amount: string) => {
    try {
      toast.success(`Adding ${amount} ETH stake to bond ${bondKey}`);
    } catch (error) {
      toast.error("Failed to add stake");
    }
  };

  const handleDefect = async (bondKey: string) => {
    if (!confirm("Are you sure you want to defect? This will incur heavy penalties.")) {
      return;
    }

    try {
      toast.success(`Defecting from bond ${bondKey}`);
    } catch (error) {
      toast.error("Defection failed");
    }
  };

  const handleExit = async (bondKey: string) => {
    try {
      toast.success(`Exiting bond ${bondKey} with fair split`);
    } catch (error) {
      toast.error("Exit failed");
    }
  };

  const handleClaimYield = async (bondKey: string) => {
    try {
      toast.success(`Claiming yield from bond ${bondKey}`);
    } catch (error) {
      toast.error("Yield claim failed");
    }
  };

  const calculateDailyYield = (tvl: bigint) => {
    // 1% daily yield
    return (tvl * BigInt(100)) / BigInt(10000);
  };

  const formatAddress = (addr: string) => {
    return `${addr.slice(0, 6)}...${addr.slice(-4)}`;
  };

  const formatTimeAgo = (timestamp: number) => {
    const diff = Date.now() - timestamp;
    const days = Math.floor(diff / (1000 * 60 * 60 * 24));
    const hours = Math.floor(diff / (1000 * 60 * 60));
    
    if (days > 0) return `${days}d ago`;
    if (hours > 0) return `${hours}h ago`;
    return 'Just now';
  };

  return (
    <div className="container mx-auto px-4 py-6 max-w-6xl font-mono">
      {/* Terminal Header */}
      <div className="border-2 border-base-content bg-base-100 p-4 mb-6">
        <div className="flex items-center justify-between mb-2">
          <div className="flex items-center space-x-2">
            <span className="text-primary font-bold">███</span>
            <span className="font-bold text-lg">TRUST_BOND_MANAGER.EXE</span>
          </div>
          <div className="text-xs">
            <span className="bg-primary text-primary-content px-2 py-1">v2.1.3</span>
          </div>
        </div>
        <div className="text-sm opacity-75">
          &gt; INITIALIZE_TRUST_PROTOCOLS... [OK]<br/>
          &gt; SCANNING_BOND_CONTRACTS... [OK]<br/>
          &gt; SYSTEM_READY_FOR_INPUT...
        </div>
      </div>

      {/* Terminal Tab Navigation */}
      <div className="flex space-x-1 mb-6">
        {[
          { key: 'create', icon: '[+]', label: 'CREATE_BOND' },
          { key: 'manage', icon: '[◉]', label: 'MANAGE_BONDS' },
          { key: 'analytics', icon: '[📊]', label: 'ANALYTICS' }
        ].map((tab) => (
          <button
            key={tab.key}
            onClick={() => setActiveTab(tab.key as any)}
            className={`px-4 py-2 font-mono text-sm border-2 transition-all ${
              activeTab === tab.key
                ? 'border-primary bg-primary text-primary-content'
                : 'border-base-content bg-base-100 hover:bg-base-200'
            }`}
          >
            {tab.icon} {tab.label}
          </button>
        ))}
      </div>

      {activeTab === 'create' && (
        <div className="border-2 border-base-content bg-base-100 p-6">
          <div className="mb-6">
            <div className="flex items-center space-x-2 mb-2">
              <span className="text-primary">▶</span>
              <span className="font-bold text-lg">BOND_CREATION_PROTOCOL</span>
            </div>
            <div className="text-xs opacity-75">&gt; ENTER_PARTNER_CREDENTIALS_AND_STAKE_AMOUNT</div>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
            <div>
              <label className="block text-sm font-mono mb-2 text-primary">
                [INPUT] PARTNER_WALLET_ADDRESS:
              </label>
              <input
                type="text"
                value={partnerAddress}
                onChange={(e) => setPartnerAddress(e.target.value)}
                placeholder="0xABCDEF1234567890..."
                className="w-full px-3 py-2 border-2 border-base-content bg-base-100 font-mono text-sm focus:border-primary focus:outline-none"
              />
            </div>

            <div>
              <label className="block text-sm font-mono mb-2 text-primary">
                [INPUT] INITIAL_STAKE_AMOUNT_ETH:
              </label>
              <input
                type="number"
                value={stakeAmount}
                onChange={(e) => setStakeAmount(e.target.value)}
                placeholder="0.000"
                className="w-full px-3 py-2 border-2 border-base-content bg-base-100 font-mono text-sm focus:border-primary focus:outline-none"
              />
            </div>
          </div>

          <div className="mb-6 p-4 border-2 border-base-content bg-base-200">
            <div className="flex items-center space-x-2 mb-3">
              <span className="text-primary">📋</span>
              <span className="font-bold text-sm">BOND_CONTRACT_TERMS.TXT</span>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-3 text-xs font-mono">
              <div className="flex justify-between">
                <span>DAILY_YIELD_RATE:</span>
                <span className="text-primary">1.0% of TVL</span>
              </div>
              <div className="flex justify-between">
                <span>COOPERATION_BONUS:</span>
                <span className="text-primary">FAIR_SPLIT</span>
              </div>
              <div className="flex justify-between">
                <span>EXIT_PENALTY_α:</span>
                <span className="text-warning">MILD</span>
              </div>
              <div className="flex justify-between">
                <span>DEFECT_PENALTY_ϕ:</span>
                <span className="text-error">SEVERE</span>
              </div>
            </div>
          </div>

          <button
            onClick={handleCreateTrustBond}
            disabled={!partnerAddress || !stakeAmount}
            className="w-full border-2 border-base-content bg-primary text-primary-content py-3 px-6 font-mono font-bold hover:bg-primary-focus disabled:bg-base-300 disabled:text-base-content disabled:cursor-not-allowed transition-all"
          >
            [EXECUTE] CREATE_TRUST_BOND.EXE
          </button>
        </div>
      )}

      {activeTab === 'manage' && (
        <div className="space-y-4">
          {mockTrustBonds.map((bond, index) => (
            <div key={bond.key} className="border-2 border-base-content bg-base-100 p-4">
              {/* Bond Header */}
              <div className="flex justify-between items-start mb-4">
                <div className="font-mono">
                  <div className="flex items-center space-x-2 mb-1">
                    <span className="text-primary">◉</span>
                    <span className="font-bold text-lg">BOND_CONTRACT_{String(index + 1).padStart(3, '0')}</span>
                  </div>
                  <div className="text-sm opacity-75">
                    &gt; PARTNER: {formatAddress(bond.addr1)}<br/>
                    &gt; CREATED: {formatTimeAgo(bond.createdAt)}
                  </div>
                </div>
                
                <div className="flex flex-col space-y-1">
                  <div className={`px-2 py-1 text-xs font-mono border ${
                    bond.isActive 
                      ? 'border-success text-success bg-success bg-opacity-20' 
                      : 'border-warning text-warning bg-warning bg-opacity-20'
                  }`}>
                    [{bond.isActive ? 'ACTIVE' : 'PENDING'}]
                  </div>
                  
                  {bond.isFrozen && (
                    <div className="px-2 py-1 text-xs font-mono border border-info text-info bg-info bg-opacity-20">
                      [FROZEN]
                    </div>
                  )}
                </div>
              </div>

              {/* Bond Stats Grid */}
              <div className="grid grid-cols-2 md:grid-cols-4 gap-3 mb-4">
                <div className="border border-base-content p-3 bg-base-200">
                  <div className="text-xs font-mono opacity-75 mb-1">YOUR_STAKE:</div>
                  <div className="text-lg font-bold font-mono">{parseFloat(formatEther(bond.stake0)).toFixed(3)}Ξ</div>
                </div>
                
                <div className="border border-base-content p-3 bg-base-200">
                  <div className="text-xs font-mono opacity-75 mb-1">PARTNER_STAKE:</div>
                  <div className="text-lg font-bold font-mono">{parseFloat(formatEther(bond.stake1)).toFixed(3)}Ξ</div>
                </div>
                
                <div className="border border-base-content p-3 bg-base-200">
                  <div className="text-xs font-mono opacity-75 mb-1">TOTAL_TVL:</div>
                  <div className="text-lg font-bold font-mono">{parseFloat(formatEther(bond.stake0 + bond.stake1)).toFixed(3)}Ξ</div>
                </div>
                
                <div className="border border-success p-3 bg-success bg-opacity-20">
                  <div className="text-xs font-mono text-success mb-1">YIELD_EARNED:</div>
                  <div className="text-lg font-bold font-mono text-success">{parseFloat(formatEther(bond.accruedYield)).toFixed(4)}Ξ</div>
                </div>
              </div>

              {/* Yield Info */}
              {bond.isActive && (
                <div className="mb-4 p-2 border border-info bg-info bg-opacity-10">
                  <div className="text-xs font-mono text-info">
                    &gt; DAILY_YIELD_RATE: {parseFloat(formatEther(calculateDailyYield(bond.stake0 + bond.stake1))).toFixed(4)}Ξ/day
                  </div>
                </div>
              )}

              {/* Action Buttons */}
              <div className="flex flex-wrap gap-2">
                {!bond.isActive && bond.stake1 === BigInt(0) && (
                  <button
                    onClick={() => {
                      const amount = prompt("ENTER_STAKE_AMOUNT_ETH:");
                      if (amount) handleAddStake(bond.key, amount);
                    }}
                    className="px-3 py-2 border-2 border-primary bg-primary text-primary-content font-mono text-xs hover:bg-primary-focus transition-all"
                  >
                    [+] ADD_STAKE
                  </button>
                )}
                
                {bond.isActive && bond.accruedYield > 0 && (
                  <button
                    onClick={() => handleClaimYield(bond.key)}
                    className="px-3 py-2 border-2 border-success bg-success text-success-content font-mono text-xs hover:bg-success-focus transition-all"
                  >
                    [↓] CLAIM_YIELD
                  </button>
                )}
                
                {bond.isActive && (
                  <>
                    <button
                      onClick={() => handleExit(bond.key)}
                      className="px-3 py-2 border-2 border-warning bg-warning text-warning-content font-mono text-xs hover:bg-warning-focus transition-all"
                    >
                      [→] FAIR_EXIT
                    </button>
                    
                    <button
                      onClick={() => handleDefect(bond.key)}
                      className="px-3 py-2 border-2 border-error bg-error text-error-content font-mono text-xs hover:bg-error-focus transition-all"
                    >
                      [!] DEFECT_PENALTY
                    </button>
                  </>
                )}
              </div>
            </div>
          ))}
        </div>
      )}

      {activeTab === 'analytics' && (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {/* Portfolio Analytics Panel */}
          <div className="border-2 border-base-content bg-base-100 p-4">
            <div className="flex items-center space-x-2 mb-4">
              <span className="text-primary">📊</span>
              <span className="font-bold font-mono">PORTFOLIO_ANALYTICS.DAT</span>
            </div>
            
            <div className="space-y-3">
              <div className="flex justify-between items-center py-2 border-b border-base-content">
                <span className="font-mono text-sm opacity-75">ACTIVE_BONDS:</span>
                <span className="font-mono font-bold text-primary">
                  {String(mockTrustBonds.filter(b => b.isActive).length).padStart(3, '0')}
                </span>
              </div>
              
              <div className="flex justify-between items-center py-2 border-b border-base-content">
                <span className="font-mono text-sm opacity-75">TOTAL_STAKED:</span>
                <span className="font-mono font-bold">
                  {parseFloat(formatEther(mockTrustBonds.reduce((sum, b) => sum + b.stake0, BigInt(0)))).toFixed(3)}Ξ
                </span>
              </div>
              
              <div className="flex justify-between items-center py-2 border-b border-base-content">
                <span className="font-mono text-sm opacity-75">YIELD_EARNED:</span>
                <span className="font-mono font-bold text-success">
                  +{parseFloat(formatEther(mockTrustBonds.reduce((sum, b) => sum + b.accruedYield, BigInt(0)))).toFixed(4)}Ξ
                </span>
              </div>
              
              <div className="flex justify-between items-center py-2">
                <span className="font-mono text-sm opacity-75">TRUST_SCORE:</span>
                <div className="flex items-center space-x-2">
                  <div className="w-16 h-2 border border-base-content bg-base-200">
                    <div className="w-4/5 h-full bg-primary"></div>
                  </div>
                  <span className="font-mono font-bold text-primary">85/100</span>
                </div>
              </div>
            </div>
          </div>

          {/* Lending Capacity Panel */}
          <div className="border-2 border-base-content bg-base-100 p-4">
            <div className="flex items-center space-x-2 mb-4">
              <span className="text-primary">💰</span>
              <span className="font-bold font-mono">LENDING_CAPACITY.SYS</span>
            </div>
            
            <div className="space-y-3">
              <div className="flex justify-between items-center py-2 border-b border-base-content">
                <span className="font-mono text-sm opacity-75">COLLATERAL_AVAIL:</span>
                <span className="font-mono font-bold">
                  {parseFloat(formatEther(mockTrustBonds.filter(b => b.isActive).reduce((sum, b) => sum + b.stake0 + b.stake1, BigInt(0)))).toFixed(3)}Ξ
                </span>
              </div>
              
              <div className="flex justify-between items-center py-2 border-b border-base-content">
                <span className="font-mono text-sm opacity-75">MAX_BORROW_80%:</span>
                <span className="font-mono font-bold text-info">
                  {parseFloat(formatEther(mockTrustBonds.filter(b => b.isActive).reduce((sum, b) => sum + (b.stake0 + b.stake1) * BigInt(80) / BigInt(100), BigInt(0)))).toFixed(3)}Ξ
                </span>
              </div>
              
              <div className="flex justify-between items-center py-2 border-b border-base-content">
                <span className="font-mono text-sm opacity-75">CURRENT_BORROWED:</span>
                <span className="font-mono font-bold">0.000Ξ</span>
              </div>
              
              <div className="flex justify-between items-center py-2">
                <span className="font-mono text-sm opacity-75">INTEREST_RATE:</span>
                <span className="font-mono font-bold text-success">5.5% APR</span>
              </div>
            </div>
            
            {/* Utilization Bar */}
            <div className="mt-4 p-3 border border-base-content bg-base-200">
              <div className="text-xs font-mono mb-2 opacity-75">LENDING_UTILIZATION:</div>
              <div className="flex items-center space-x-2">
                <div className="flex-1 h-3 border border-base-content bg-base-100">
                  <div className="w-0 h-full bg-primary"></div>
                </div>
                <span className="font-mono text-xs font-bold">0%</span>
              </div>
            </div>
          </div>
          
          {/* Risk Assessment Panel */}
          <div className="border-2 border-base-content bg-base-100 p-4 md:col-span-2">
            <div className="flex items-center space-x-2 mb-4">
              <span className="text-primary">⚠️</span>
              <span className="font-bold font-mono">RISK_ASSESSMENT_MATRIX.LOG</span>
            </div>
            
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div className="text-center">
                <div className="text-xs font-mono opacity-75 mb-1">LIQUIDATION_RISK:</div>
                <div className="text-2xl font-mono font-bold text-success">LOW</div>
                <div className="text-xs font-mono opacity-75">&lt; 5% probability</div>
              </div>
              
              <div className="text-center">
                <div className="text-xs font-mono opacity-75 mb-1">PARTNER_RELIABILITY:</div>
                <div className="text-2xl font-mono font-bold text-info">HIGH</div>
                <div className="text-xs font-mono opacity-75">92% cooperation rate</div>
              </div>
              
              <div className="text-center">
                <div className="text-xs font-mono opacity-75 mb-1">YIELD_STABILITY:</div>
                <div className="text-2xl font-mono font-bold text-warning">MED</div>
                <div className="text-xs font-mono opacity-75">±0.2% variance</div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default TrustBondManager;