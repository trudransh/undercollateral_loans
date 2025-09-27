"use client";

import { useState } from "react";
import { Address } from "~~/components/scaffold-eth";
import { useTrustProtocol } from "~~/hooks/scaffold-eth/useTrustProtocol";
import { formatEther } from "viem";

interface ContractCardProps {
  contract: {
    addr0: string;
    addr1: string;
    stake0: bigint;
    stake1: bigint;
    accruedYield: bigint;
    isActive: boolean;
    isFrozen: boolean;
    createdAt: bigint;
    lastYieldUpdate: bigint;
  };
}

export function ContractCard({ contract }: ContractCardProps) {
  const { 
    exitTrustContract, 
    defectFromContract, 
    formatYield, 
    calculateDailyYield 
  } = useTrustProtocol();
  
  const [isLoading, setIsLoading] = useState(false);
  const [action, setAction] = useState<string | null>(null);

  const totalStake = contract.stake0 + contract.stake1;
  const dailyYield = calculateDailyYield(totalStake);
  const isActive = contract.isActive;
  const isFrozen = contract.isFrozen;

  const handleExit = async () => {
    if (!contract.addr0 || !contract.addr1) return;
    
    setIsLoading(true);
    setAction("exit");
    
    try {
      // Determine which address is the partner
      const partner = contract.addr0 === contract.addr0 ? contract.addr1 : contract.addr0;
      await exitTrustContract(partner);
    } catch (error) {
      console.error("Error exiting contract:", error);
    } finally {
      setIsLoading(false);
      setAction(null);
    }
  };

  const handleDefect = async () => {
    if (!contract.addr0 || !contract.addr1) return;
    
    if (!confirm("Are you sure you want to defect? This will steal all funds and damage your reputation!")) {
      return;
    }
    
    setIsLoading(true);
    setAction("defect");
    
    try {
      // Determine which address is the partner
      const partner = contract.addr0 === contract.addr0 ? contract.addr1 : contract.addr0;
      await defectFromContract(partner);
    } catch (error) {
      console.error("Error defecting from contract:", error);
    } finally {
      setIsLoading(false);
      setAction(null);
    }
  };

  const getStatusColor = () => {
    if (isFrozen) return "bg-red-100 text-red-800";
    if (isActive) return "bg-green-100 text-green-800";
    return "bg-gray-100 text-gray-800";
  };

  const getStatusText = () => {
    if (isFrozen) return "Frozen";
    if (isActive) return "Active";
    return "Inactive";
  };

  return (
    <div className="bg-white rounded-lg shadow-md p-6 border border-gray-200 hover:shadow-lg transition-shadow duration-200">
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-lg font-semibold text-gray-900">Trust Contract</h3>
        <span className={`px-2 py-1 rounded-full text-xs font-medium ${getStatusColor()}`}>
          {getStatusText()}
        </span>
      </div>

      {/* Partners */}
      <div className="space-y-2 mb-4">
        <div className="flex items-center space-x-2">
          <span className="text-sm text-gray-600">Partner 1:</span>
          <Address address={contract.addr0} />
        </div>
        <div className="flex items-center space-x-2">
          <span className="text-sm text-gray-600">Partner 2:</span>
          <Address address={contract.addr1} />
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 gap-4 mb-4">
        <div>
          <p className="text-sm text-gray-600">Total Stake</p>
          <p className="text-lg font-semibold">{formatEther(totalStake)} ETH</p>
        </div>
        <div>
          <p className="text-sm text-gray-600">Accrued Yield</p>
          <p className="text-lg font-semibold text-green-600">{formatYield(contract.accruedYield)} ETH</p>
        </div>
        <div>
          <p className="text-sm text-gray-600">Daily Yield</p>
          <p className="text-lg font-semibold">{dailyYield} ETH</p>
        </div>
        <div>
          <p className="text-sm text-gray-600">Created</p>
          <p className="text-sm">{new Date(Number(contract.createdAt) * 1000).toLocaleDateString()}</p>
        </div>
      </div>

      {/* Actions */}
      {isActive && !isFrozen && (
        <div className="flex space-x-2 pt-4 border-t border-gray-200">
          <button
            onClick={handleExit}
            disabled={isLoading}
            className="flex-1 bg-blue-600 hover:bg-blue-700 disabled:bg-blue-300 text-white font-medium py-2 px-4 rounded-lg transition-colors duration-200"
          >
            {isLoading && action === "exit" ? "Exiting..." : "Exit (Fair)"}
          </button>
          <button
            onClick={handleDefect}
            disabled={isLoading}
            className="flex-1 bg-red-600 hover:bg-red-700 disabled:bg-red-300 text-white font-medium py-2 px-4 rounded-lg transition-colors duration-200"
          >
            {isLoading && action === "defect" ? "Defecting..." : "Defect (Steal)"}
          </button>
        </div>
      )}

      {isFrozen && (
        <div className="pt-4 border-t border-gray-200">
          <p className="text-sm text-red-600 text-center">
            Contract is frozen and cannot be modified
          </p>
        </div>
      )}
    </div>
  );
}