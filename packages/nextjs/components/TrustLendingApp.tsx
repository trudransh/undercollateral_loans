"use client";

import { useState, useEffect } from "react";
import { useAccount, useBalance } from "wagmi";
import { formatEther } from "viem";
import LendingPoolDashboard from "./LendingPoolDashboard_New";
import TrustBondManager from "./TrustBondManager";

const TrustLendingApp = () => {
  const { address, isConnected } = useAccount();
  const [activeView, setActiveView] = useState<'overview' | 'bonds' | 'lending'>('overview');
  const [totalBonds, setTotalBonds] = useState(0);
  const [totalBondValue, setTotalBondValue] = useState(0);
  const [ethPriceUSD, setEthPriceUSD] = useState(2400); // Mock ETH price in USD
  const [showFeaturesModal, setShowFeaturesModal] = useState(false);
  
  // Get wallet ETH balance
  const { data: balance } = useBalance({
    address: address,
  });
  
  // Helper function to convert ETH to USD
  const ethToUSD = (ethAmount: number): string => {
    return (ethAmount * ethPriceUSD).toFixed(2);
  };
  
  // Mock data for total bonds - replace with actual contract calls
  useEffect(() => {
    if (isConnected && address) {
      // Simulate fetching user's trust bonds from contracts
      setTotalBonds(3); // Number of active trust bonds
      setTotalBondValue(450); // Total value in ETH
    }
    
    // Simulate real-time ETH price updates
    const priceInterval = setInterval(() => {
      setEthPriceUSD(prev => prev + (Math.random() - 0.5) * 10); // Random price fluctuation
    }, 5000);
    
    return () => clearInterval(priceInterval);
  }, [isConnected, address]);

  // Handle keyboard shortcuts for modal
  useEffect(() => {
    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape' && showFeaturesModal) {
        setShowFeaturesModal(false);
      }
    };

    document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, [showFeaturesModal]);

  if (!isConnected) {
    return (
      <div className="min-h-screen bg-base-100 flex items-center justify-center p-4">
        <div className="text-center max-w-4xl">
          <h1 className="retro-title text-6xl mb-8 glitch">TRUST_PROTOCOL_LENDING</h1>
          <div className="mb-8">
            <span className="text-2xl font-mono">{'>'}</span>
            <span className="text-xl font-mono ml-2 blink">CONNECT_WALLET_TO_ACCESS_SYSTEM</span>
          </div>
          
          <div className="space-y-6">
            <button 
              onClick={() => setShowFeaturesModal(true)}
              className="btn btn-primary font-mono text-lg glitch"
            >
              [VIEW_SYSTEM_FEATURES]
            </button>
            
            <div className="text-center">
              <p className="font-mono text-lg mb-4">[WARNING: WALLET_CONNECTION_REQUIRED]</p>
              <div className="badge badge-outline text-lg px-4 py-2">STATUS: DISCONNECTED</div>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-base-100">
      {/* Enhanced Retro Navigation Header */}
      <nav className="bg-base-100 border-b-4 border-base-content shadow-lg">
        <div className="container mx-auto px-4">
          <div className="flex flex-col lg:flex-row lg:justify-between lg:items-center py-3 space-y-3 lg:space-y-0">
            
            {/* Left Section - Logo and Navigation */}
            <div className="flex flex-col sm:flex-row items-start sm:items-center space-y-3 sm:space-y-0 sm:space-x-6">
              <div className="flex items-center space-x-3">
                <h1 className="retro-title text-xl lg:text-2xl font-bold font-mono tracking-wider">LENDING_W3.0</h1>
              </div>
              
              {/* Main Navigation Tabs */}
              <div className="flex space-x-1">
                {[
                  { key: 'overview', label: 'OVERVIEW', icon: '●' },
                  { key: 'bonds', label: 'TRUST_BONDS', icon: '◆' },
                  { key: 'lending', label: 'LENDING_POOL', icon: '₿' }
                ].map((item) => (
                  <button
                    key={item.key}
                    onClick={() => setActiveView(item.key as any)}
                    className={`px-3 py-2 border-2 font-mono text-xs font-bold transition-all ${
                      activeView === item.key
                        ? 'border-primary bg-primary text-primary-content'
                        : 'border-base-content bg-base-100 hover:bg-base-200'
                    }`}
                  >
                    {item.icon} [{item.label}]
                  </button>
                ))}
              </div>

              {/* Secondary Actions */}
              {/* <div className="flex space-x-2">
                <button
                  onClick={() => setShowFeaturesModal(true)}
                  className="btn btn-sm btn-ghost font-mono hover:btn-outline"
                  title="View System Features"
                >
                  [?] INFO
                </button>
                
                <button
                  className="btn btn-sm btn-ghost font-mono hover:btn-outline"
                  title="System Settings"
                >
                  [⚙] CONFIG
                </button>
              </div> */}
            </div>

            {/* Right Section - User Dashboard */}
            <div className="flex flex-col space-y-2 lg:space-y-0 lg:flex-row lg:items-center lg:space-x-2">
              
              {/* Data Display Panels */}
              <div className="flex space-x-1">
                {/* ETH Price */}
                <div className="border-2 border-base-content px-3 py-2 bg-base-100 font-mono">
                  <div className="text-xs opacity-75">ETH/USD</div>
                  <div className="text-sm font-bold">${ethPriceUSD.toFixed(2)}</div>
                </div>
                
                {/* Wallet Balance */}
                <div className="border-2 border-base-content px-3 py-2 bg-base-100 font-mono">
                  <div className="text-xs opacity-75">BALANCE</div>
                  <div className="text-sm font-bold">
                    {balance ? parseFloat(formatEther(balance.value)).toFixed(3) : '0.000'}
                  </div>
                </div>
                
                {/* Trust Bonds */}
                <div className="border-2 border-base-content px-3 py-2 bg-base-100 font-mono">
                  <div className="text-xs opacity-75">BONDS</div>
                  <div className="text-sm font-bold text-primary">{totalBonds}</div>
                </div>
                
                {/* Portfolio Value */}
                <div className="border-2 border-base-content px-3 py-2 bg-base-100 font-mono">
                  <div className="text-xs opacity-75">PORTFOLIO</div>
                  <div className="text-sm font-bold">
                    {(parseFloat(balance ? formatEther(balance.value) : '0') + totalBondValue).toFixed(2)}Ξ
                  </div>
                </div>
              </div>
              
              {/* User Status & Controls */}
              <div className="flex items-center space-x-1">
                {/* Connection Status */}
                {/* <div className="border-2 border-base-content px-2 py-2 bg-base-100 flex items-center space-x-1">
                  <div className="w-2 h-2 bg-primary rounded-full blink"></div>
                  <span className="font-mono text-xs">ONLINE</span>
                </div> */}
                
                {/* User Address */}
                {/* <div className="border-2 border-base-content px-2 py-2 bg-base-100 font-mono text-xs">
                  👤 {address?.slice(0, 4)}...{address?.slice(-4)}
                </div> */}
                
                {/* Actions Menu */}
                {/* <div className="dropdown dropdown-end">
                  <div tabIndex={0} role="button" className="border-2 border-base-content px-2 py-2 bg-base-100 font-mono text-xs hover:bg-base-200 cursor-pointer">
                    [⋮]
                  </div>
                  <ul tabIndex={0} className="dropdown-content menu p-2 shadow-lg bg-base-100 border-2 border-base-content w-52 font-mono text-sm">
                    <li><a href="#" className="hover:bg-base-200">[📋] COPY_ADDRESS</a></li>
                    <li><a href="#" className="hover:bg-base-200">[🔗] VIEW_ON_EXPLORER</a></li>
                    <li><a href="#" className="hover:bg-base-200">[📊] TRANSACTION_HISTORY</a></li>
                    <li><a href="#" className="hover:bg-base-200">[⚙️] SETTINGS</a></li>
                    <li className="border-t border-base-content mt-2 pt-2">
                      <a href="#" className="hover:bg-red-100 text-error">[🚪] DISCONNECT</a>
                    </li>
                  </ul>
                </div> */}
              </div>
            </div>
          </div>
        </div>
      </nav>

      {/* Main Content */}
      <main className="container mx-auto px-4 py-8">
        {activeView === 'overview' && (
          <div className="space-y-8">
            {/* Hero Section */}
            <div className="text-center mb-12">
              <h1 className="retro-title text-5xl mb-6 glitch">
                UNDERCOLLATERALIZED_LENDING_PROTOCOL
              </h1>
              <div className="max-w-4xl mx-auto bg-base-100 border-4 border-base-content p-6">
                <p className="text-xl font-mono leading-relaxed">
                  {'>'} LEVERAGE_SOCIAL_TRUST_AND_AUTOMATED_COOPERATION<br/>
                  {'>'} UNLOCK_CAPITAL_EFFICIENCY_THROUGH_TRUST_BONDS<br/>
                  {'>'} EARN_YIELD_AND_BORROW_WITH_MINIMAL_COLLATERAL
                </p>
              </div>
            </div>

            {/* User Portfolio Dashboard */}
            <div className="card bg-base-100 p-6 mb-8">
              <h2 className="retro-subtitle text-2xl mb-6 text-center">[USER_PORTFOLIO_DASHBOARD]</h2>
              
              <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
                <div className="border-2 border-base-content p-4 text-center">
                  <div className="font-mono text-sm mb-2">WALLET_BALANCE:</div>
                  <div className="font-mono text-2xl font-bold blink">
                    {balance ? parseFloat(formatEther(balance.value)).toFixed(4) : '0.0000'} ETH
                  </div>
                  <div className="font-mono text-xs mt-1">
                    ${balance ? ethToUSD(parseFloat(formatEther(balance.value))) : '0.00'} USD
                  </div>
                </div>
                
                <div className="border-2 border-base-content p-4 text-center">
                  <div className="font-mono text-sm mb-2">ACTIVE_BONDS:</div>
                  <div className="font-mono text-2xl font-bold">{totalBonds}</div>
                  <div className="badge badge-outline mt-2">STATUS: ONLINE</div>
                </div>
                
                <div className="border-2 border-base-content p-4 text-center">
                  <div className="font-mono text-sm mb-2">BOND_VALUE:</div>
                  <div className="font-mono text-2xl font-bold">{totalBondValue} ETH</div>
                  <div className="font-mono text-xs mt-1">
                    ${ethToUSD(totalBondValue)} USD
                  </div>
                </div>
                
                <div className="border-2 border-base-content p-4 text-center">
                  <div className="font-mono text-sm mb-2">TOTAL_ASSETS:</div>
                  <div className="font-mono text-2xl font-bold">
                    {(parseFloat(balance ? formatEther(balance.value) : '0') + totalBondValue).toFixed(4)} ETH
                  </div>
                  <div className="font-mono text-xs mt-1">
                    ${ethToUSD(parseFloat(balance ? formatEther(balance.value) : '0') + totalBondValue)} USD
                  </div>
                </div>
              </div>
            </div>

            {/* System Status Dashboard */}
            <div className="card bg-base-100 p-6 mb-8">
              <h2 className="retro-subtitle text-2xl mb-6 text-center">[SYSTEM_STATUS_DASHBOARD]</h2>
              
              <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
                <div className="text-center p-4 border-2 border-base-content">
                  <div className="font-mono text-3xl font-bold mb-2">$2.4M</div>
                  <div className="font-mono text-sm">TOTAL_VALUE_LOCKED</div>
                  <div className="progress progress-primary mt-2" style={{width: '90%'}}></div>
                </div>
                
                <div className="text-center p-4 border-2 border-base-content">
                  <div className="font-mono text-3xl font-bold mb-2">5.2%</div>
                  <div className="font-mono text-sm">AVERAGE_YIELD_APY</div>
                  <div className="badge badge-outline mt-2">STABLE</div>
                </div>
                
                <div className="text-center p-4 border-2 border-base-content">
                  <div className="font-mono text-3xl font-bold mb-2">1,247</div>
                  <div className="font-mono text-sm">ACTIVE_TRUST_BONDS</div>
                  <div className="badge badge-primary mt-2">ONLINE</div>
                </div>
                
                <div className="text-center p-4 border-2 border-base-content">
                  <div className="font-mono text-3xl font-bold mb-2 blink">87.3%</div>
                  <div className="font-mono text-sm">COOPERATION_RATE</div>
                  <div className="badge badge-outline mt-2">OPTIMAL</div>
                </div>
              </div>
            </div>

            {/* Active Trust Bonds Breakdown */}
            <div className="card bg-base-100 p-8">
              <h2 className="retro-subtitle text-2xl mb-8 text-center">[ACTIVE_TRUST_BONDS_BREAKDOWN]</h2>
              
              <div className="space-y-4">
                {/* Mock bond data - replace with actual contract calls */}
                {[
                  { 
                    id: '001', 
                    partner: '0xabc...DEF', 
                    stake: '150', 
                    yield: '2.34', 
                    status: 'ACTIVE',
                    duration: '45_DAYS'
                  },
                  { 
                    id: '002', 
                    partner: '0xdef...GHI', 
                    stake: '200', 
                    yield: '4.12', 
                    status: 'ACTIVE',
                    duration: '23_DAYS'
                  },
                  { 
                    id: '003', 
                    partner: '0xghi...JKL', 
                    stake: '100', 
                    yield: '1.89', 
                    status: 'ACTIVE',
                    duration: '67_DAYS'
                  }
                ].map((bond, index) => (
                  <div key={index} className="border-2 border-base-content p-4">
                    <div className="grid grid-cols-1 md:grid-cols-6 gap-4">
                      <div className="text-center p-2 border border-base-content">
                        <div className="font-mono text-xs mb-1">BOND_ID</div>
                        <div className="font-mono font-bold">{bond.id}</div>
                      </div>
                      <div className="text-center p-2 border border-base-content">
                        <div className="font-mono text-xs mb-1">PARTNER</div>
                        <div className="font-mono font-bold">{bond.partner}</div>
                      </div>
                      <div className="text-center p-2 border border-base-content">
                        <div className="font-mono text-xs mb-1">STAKE_AMOUNT</div>
                        <div className="font-mono font-bold">{bond.stake} ETH</div>
                      </div>
                      <div className="text-center p-2 border border-base-content">
                        <div className="font-mono text-xs mb-1">YIELD_EARNED</div>
                        <div className="font-mono font-bold blink">{bond.yield} ETH</div>
                      </div>
                      <div className="text-center p-2 border border-base-content">
                        <div className="font-mono text-xs mb-1">DURATION</div>
                        <div className="font-mono font-bold">{bond.duration}</div>
                      </div>
                      <div className="text-center p-2 border border-base-content">
                        <div className="font-mono text-xs mb-1">STATUS</div>
                        <div className="badge badge-primary font-mono">{bond.status}</div>
                      </div>
                    </div>
                  </div>
                ))}
                
                <div className="text-center mt-6">
                  <div className="font-mono text-sm mb-4">
                    {'>'} TOTAL_BONDS: {totalBonds} | TOTAL_VALUE: {totalBondValue} ETH | TOTAL_YIELD: 8.35 ETH
                  </div>
                  <button className="btn btn-primary font-mono glitch">
                    [VIEW_ALL_BONDS]
                  </button>
                </div>
              </div>
            </div>

            {/* Protocol Execution Flow */}
            <div className="card bg-base-100 p-8">
              <h2 className="retro-subtitle text-2xl mb-8 text-center">[PROTOCOL_EXECUTION_FLOW]</h2>
              
              <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
                <div className="text-center border-2 border-base-content p-6">
                  <div className="w-16 h-16 bg-base-300 border-2 border-base-content flex items-center justify-center mx-auto mb-4 font-mono text-2xl font-bold">
                    [1]
                  </div>
                  <h3 className="retro-subtitle text-lg mb-3">CREATE_TRUST_BONDS</h3>
                  <div className="font-mono text-sm leading-relaxed">
                    {'>'} PARTNER_WITH_TRUSTED_INDIVIDUALS<br/>
                    {'>'} CREATE_MUTUAL_STAKE_BONDS<br/>
                    {'>'} EARN_PASSIVE_YIELD_THROUGH_COOPERATION
                  </div>
                </div>
                
                <div className="text-center border-2 border-base-content p-6">
                  <div className="w-16 h-16 bg-base-300 border-2 border-base-content flex items-center justify-center mx-auto mb-4 font-mono text-2xl font-bold">
                    [2]
                  </div>
                  <h3 className="retro-subtitle text-lg mb-3">BORROW_AGAINST_BONDS</h3>
                  <div className="font-mono text-sm leading-relaxed">
                    {'>'} USE_TRUST_BONDS_AS_COLLATERAL<br/>
                    {'>'} BORROW_UP_TO_80%_OF_BOND_VALUE<br/>
                    {'>'} COMPETITIVE_INTEREST_RATES
                  </div>
                </div>
                
                <div className="text-center border-2 border-base-content p-6">
                  <div className="w-16 h-16 bg-base-300 border-2 border-base-content flex items-center justify-center mx-auto mb-4 font-mono text-2xl font-bold blink">
                    [3]
                  </div>
                  <h3 className="retro-subtitle text-lg mb-3">AUTOMATED_RECOVERY</h3>
                  <div className="font-mono text-sm leading-relaxed">
                    {'>'} SMART_CONTRACT_DEFAULT_HANDLING<br/>
                    {'>'} SLASHING_FREEZING_MECHANISMS<br/>
                    {'>'} YIELD_BASED_RECOVERY_SYSTEM
                  </div>
                </div>
              </div>
            </div>

            {/* Risk Management System */}
            <div className="card bg-base-100 p-8">
              <h2 className="retro-subtitle text-2xl mb-8">[RISK_MANAGEMENT_PROTOCOLS]</h2>
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="space-y-6">
                  <div className="border-2 border-base-content p-4">
                    <div className="flex items-start space-x-3">
                      <div className="badge badge-outline font-mono">
                        [S]
                      </div>
                      <div>
                        <h4 className="font-mono font-bold mb-2">SLASHING_MECHANISM</h4>
                        <p className="font-mono text-sm leading-relaxed">
                          AUTOMATIC_PENALTY_FOR_BOND_DEFECTION<br/>
                          PROTECTS_LENDER_FUNDS_FROM_DEFAULTS
                        </p>
                      </div>
                    </div>
                  </div>
                  
                  <div className="border-2 border-base-content p-4">
                    <div className="flex items-start space-x-3">
                      <div className="badge badge-outline font-mono blink">
                        [F]
                      </div>
                      <div>
                        <h4 className="font-mono font-bold mb-2">FREEZING_PROTOCOL</h4>
                        <p className="font-mono text-sm leading-relaxed">
                          TEMPORARY_SUSPENSION_OF_RISKY_POSITIONS<br/>
                          ACTIVATED_DURING_MARKET_VOLATILITY
                        </p>
                      </div>
                    </div>
                  </div>
                </div>
                
                <div className="space-y-6">
                  <div className="border-2 border-base-content p-4">
                    <div className="flex items-start space-x-3">
                      <div className="badge badge-outline font-mono">
                        [Y]
                      </div>
                      <div>
                        <h4 className="font-mono font-bold mb-2">YIELD_RECOVERY</h4>
                        <p className="font-mono text-sm leading-relaxed">
                          ACCUMULATED_YIELD_FROM_TRUST_BONDS<br/>
                          COVERS_DEFAULT_LOSSES_AUTOMATICALLY
                        </p>
                      </div>
                    </div>
                  </div>
                  
                  <div className="border-2 border-base-content p-4">
                    <div className="flex items-start space-x-3">
                      <div className="badge badge-outline font-mono">
                        [C]
                      </div>
                      <div>
                        <h4 className="font-mono font-bold mb-2">COOPERATION_INCENTIVES</h4>
                        <p className="font-mono text-sm leading-relaxed">
                          HIGHER_YIELDS_FOR_MAINTAINED_BONDS<br/>
                          BETTER_RATES_FOR_TRUST_PARTICIPANTS
                        </p>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* System Access Terminals */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="card bg-base-100 p-8 border-4 border-base-content">
                <h3 className="retro-subtitle text-xl mb-4">[TRUST_BOND_TERMINAL]</h3>
                <div className="font-mono text-sm mb-6 leading-relaxed">
                  {'>'} CREATE_FIRST_TRUST_BOND<br/>
                  {'>'} BEGIN_EARNING_PASSIVE_YIELD<br/>
                  {'>'} ESTABLISH_COOPERATION_PROTOCOLS
                </div>
                <button 
                  onClick={() => setActiveView('bonds')}
                  className="btn btn-primary w-full glitch"
                >
                  [ACCESS_TRUST_BONDS]
                </button>
              </div>
              
              <div className="card bg-base-100 p-8 border-4 border-base-content">
                <h3 className="retro-subtitle text-xl mb-4">[LENDING_POOL_TERMINAL]</h3>
                <div className="font-mono text-sm mb-6 leading-relaxed">
                  {'>'} BORROW_AGAINST_TRUST_BONDS<br/>
                  {'>'} LEND_TO_EARN_INTEREST<br/>
                  {'>'} ACCESS_UNDERCOLLATERALIZED_LOANS
                </div>
                <button 
                  onClick={() => setActiveView('lending')}
                  className="btn btn-primary w-full glitch"
                >
                  [ACCESS_LENDING_POOL]
                </button>
              </div>
            </div>
          </div>
        )}

        {activeView === 'bonds' && <TrustBondManager />}
        {activeView === 'lending' && <LendingPoolDashboard />}
      </main>

      {/* System Features Modal */}
      {showFeaturesModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="card bg-base-100 p-8 max-w-2xl w-full border-4 border-base-content relative">
            {/* Close Button */}
            <button
              onClick={() => setShowFeaturesModal(false)}
              className="absolute top-4 right-4 btn btn-sm btn-ghost font-mono text-2xl"
            >
              [X]
            </button>

            <h2 className="retro-subtitle text-3xl mb-8 text-center">[SYSTEM_FEATURES_v2.0]</h2>
            
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
              <div className="border-2 border-base-content p-4">
                <h3 className="font-mono font-bold mb-3">TRUST_BOND_SYSTEM:</h3>
                <div className="space-y-2 font-mono text-sm">
                  <div className="flex items-center">
                    <span className="text-primary mr-2">{'>'}</span>
                    <span>CREATE_MUTUAL_STAKE_BONDS</span>
                  </div>
                  <div className="flex items-center">
                    <span className="text-primary mr-2">{'>'}</span>
                    <span>PARTNER_WITH_TRUSTED_USERS</span>
                  </div>
                  <div className="flex items-center">
                    <span className="text-primary mr-2">{'>'}</span>
                    <span>EARN_PASSIVE_YIELD_REWARDS</span>
                  </div>
                </div>
              </div>

              <div className="border-2 border-base-content p-4">
                <h3 className="font-mono font-bold mb-3">LENDING_PROTOCOL:</h3>
                <div className="space-y-2 font-mono text-sm">
                  <div className="flex items-center">
                    <span className="text-primary mr-2">{'>'}</span>
                    <span>BORROW_AGAINST_COLLATERAL</span>
                  </div>
                  <div className="flex items-center">
                    <span className="text-primary mr-2">{'>'}</span>
                    <span>LEND_TO_EARN_INTEREST</span>
                  </div>
                  <div className="flex items-center">
                    <span className="text-primary mr-2">{'>'}</span>
                    <span>UNDERCOLLATERALIZED_LOANS</span>
                  </div>
                </div>
              </div>

              <div className="border-2 border-base-content p-4">
                <h3 className="font-mono font-bold mb-3">RISK_MANAGEMENT:</h3>
                <div className="space-y-2 font-mono text-sm">
                  <div className="flex items-center">
                    <span className="text-primary mr-2">{'>'}</span>
                    <span>AUTOMATED_SLASHING</span>
                  </div>
                  <div className="flex items-center">
                    <span className="text-primary mr-2">{'>'}</span>
                    <span>FREEZING_PROTOCOLS</span>
                  </div>
                  <div className="flex items-center">
                    <span className="text-primary mr-2">{'>'}</span>
                    <span>YIELD_BASED_RECOVERY</span>
                  </div>
                </div>
              </div>

              <div className="border-2 border-base-content p-4">
                <h3 className="font-mono font-bold mb-3">COOPERATION_SYSTEM:</h3>
                <div className="space-y-2 font-mono text-sm">
                  <div className="flex items-center">
                    <span className="text-primary mr-2">{'>'}</span>
                    <span>INCENTIVE_MECHANISMS</span>
                  </div>
                  <div className="flex items-center">
                    <span className="text-primary mr-2">{'>'}</span>
                    <span>TRUST_SCORE_TRACKING</span>
                  </div>
                  <div className="flex items-center">
                    <span className="text-primary mr-2">{'>'}</span>
                    <span>SOCIAL_CONSENSUS</span>
                  </div>
                </div>
              </div>
            </div>

            <div className="border-2 border-base-content p-4 bg-base-200 mb-6">
              <div className="font-mono text-center">
                <div className="text-sm mb-2">PLATFORM_STATUS:</div>
                <div className="badge badge-primary font-mono">ACTIVE_BETA</div>
                <div className="text-xs mt-2">
                  {'>'} CONNECT_WALLET_TO_START_USING_PROTOCOL
                </div>
              </div>
            </div>

            <button
              onClick={() => setShowFeaturesModal(false)}
              className="btn btn-primary w-full font-mono text-lg glitch"
            >
              [CLOSE_FEATURES_OVERVIEW]
            </button>
          </div>
        </div>
      )}
    </div>
  );
};

export default TrustLendingApp;