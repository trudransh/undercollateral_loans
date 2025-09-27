"use client";

import { useState, useEffect } from "react";
import { useAccount } from "wagmi";
import { Address, Balance } from "~~/components/scaffold-eth";
import { useTrustProtocol } from "~~/hooks/scaffold-eth/useTrustProtocol";
import { CreateContractModal } from "./CreateContractModal";
import { ContractCard } from "./ContractCard";
import { TrustScoreCard } from "./TrustScoreCard";
import { YieldProjectionCard } from "./YieldProjectionCard";

export function TrustDashboard() {
  const { address, isConnected } = useAccount();
  const { trustScore, dailyYieldBps, calculateAPY } = useTrustProtocol();
  const [showCreateModal, setShowCreateModal] = useState(false);
  const [userContracts, setUserContracts] = useState<any[]>([]);

  if (!isConnected) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[400px] space-y-4">
        <div className="text-6xl">🔗</div>
        <h2 className="text-2xl font-bold">Connect Your Wallet</h2>
        <p className="text-lg text-gray-600 text-center max-w-md">
          Connect your wallet to start building trust relationships and earning passive yield through the Trust Protocol.
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-8">
      {/* Header */}
      <div className="text-center space-y-4">
        <h1 className="text-4xl font-bold bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">
          Trust Protocol Dashboard
        </h1>
        <p className="text-lg text-gray-600 max-w-2xl mx-auto">
          Build trust relationships and earn passive yield through cooperative contracts. 
          The more you cooperate, the more you earn.
        </p>
        <div className="flex items-center justify-center space-x-4">
          <Address address={address} />
          <Balance address={address} />
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <TrustScoreCard trustScore={trustScore} />
        <div className="bg-white rounded-lg shadow-md p-6 border border-gray-200">
          <div className="flex items-center space-x-3">
            <div className="text-3xl">📈</div>
            <div>
              <h3 className="text-lg font-semibold text-gray-900">Daily Yield Rate</h3>
              <p className="text-2xl font-bold text-green-600">{calculateAPY()}% APY</p>
              <p className="text-sm text-gray-500">1% per day on total value locked</p>
            </div>
          </div>
        </div>
        <div className="bg-white rounded-lg shadow-md p-6 border border-gray-200">
          <div className="flex items-center space-x-3">
            <div className="text-3xl">🤝</div>
            <div>
              <h3 className="text-lg font-semibold text-gray-900">Active Contracts</h3>
              <p className="text-2xl font-bold text-blue-600">{userContracts.length}</p>
              <p className="text-sm text-gray-500">Trust relationships</p>
            </div>
          </div>
        </div>
      </div>

      {/* Action Buttons */}
      <div className="flex flex-col sm:flex-row gap-4 justify-center">
        <button
          onClick={() => setShowCreateModal(true)}
          className="bg-blue-600 hover:bg-blue-700 text-white font-bold py-3 px-6 rounded-lg transition-colors duration-200 flex items-center space-x-2"
        >
          <span>+</span>
          <span>Create Trust Contract</span>
        </button>
        <button className="bg-gray-600 hover:bg-gray-700 text-white font-bold py-3 px-6 rounded-lg transition-colors duration-200 flex items-center space-x-2">
          <span>🔍</span>
          <span>Find Partners</span>
        </button>
      </div>

      {/* Contracts Section */}
      <div className="space-y-6">
        <h2 className="text-2xl font-bold text-gray-900">Your Trust Contracts</h2>
        
        {userContracts.length === 0 ? (
          <div className="text-center py-12 bg-gray-50 rounded-lg border-2 border-dashed border-gray-300">
            <div className="text-6xl mb-4">🤝</div>
            <h3 className="text-xl font-semibold text-gray-900 mb-2">No Trust Contracts Yet</h3>
            <p className="text-gray-600 mb-6">
              Create your first trust contract to start earning passive yield through cooperation.
            </p>
            <button
              onClick={() => setShowCreateModal(true)}
              className="bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded-lg transition-colors duration-200"
            >
              Create Your First Contract
            </button>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {userContracts.map((contract, index) => (
              <ContractCard key={index} contract={contract} />
            ))}
          </div>
        )}
      </div>

      {/* Yield Projection */}
      <YieldProjectionCard />

      {/* Create Contract Modal */}
      {showCreateModal && (
        <CreateContractModal
          isOpen={showCreateModal}
          onClose={() => setShowCreateModal(false)}
          onContractCreated={(contract) => {
            setUserContracts(prev => [...prev, contract]);
            setShowCreateModal(false);
          }}
        />
      )}
    </div>
  );
}