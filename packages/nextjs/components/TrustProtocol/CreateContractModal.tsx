"use client";

import { useState } from "react";
import { AddressInput, EtherInput } from "~~/components/scaffold-eth";
import { useTrustProtocol } from "~~/hooks/scaffold-eth/useTrustProtocol";
import { parseEther } from "viem";

interface CreateContractModalProps {
  isOpen: boolean;
  onClose: () => void;
  onContractCreated: (contract: any) => void;
}

export function CreateContractModal({ isOpen, onClose, onContractCreated }: CreateContractModalProps) {
  const [partnerAddress, setPartnerAddress] = useState("");
  const [stakeAmount, setStakeAmount] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  
  const { createTrustContract } = useTrustProtocol();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!partnerAddress || !stakeAmount) {
      setError("Please fill in all fields");
      return;
    }

    if (parseFloat(stakeAmount) <= 0) {
      setError("Stake amount must be greater than 0");
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const tx = await createTrustContract(partnerAddress, stakeAmount);
      
      if (tx) {
        // Create a mock contract object for the UI
        const contract = {
          addr0: partnerAddress,
          addr1: partnerAddress, // This will be updated when partner adds stake
          stake0: parseEther(stakeAmount),
          stake1: BigInt(0),
          accruedYield: BigInt(0),
          isActive: false,
          isFrozen: false,
          createdAt: BigInt(Math.floor(Date.now() / 1000)),
          lastYieldUpdate: BigInt(0),
        };
        
        onContractCreated(contract);
        setPartnerAddress("");
        setStakeAmount("");
      }
    } catch (err: any) {
      setError(err.message || "Failed to create contract");
    } finally {
      setIsLoading(false);
    }
  };

  const handleClose = () => {
    setPartnerAddress("");
    setStakeAmount("");
    setError(null);
    onClose();
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg shadow-xl max-w-md w-full mx-4">
        <div className="p-6">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-2xl font-bold text-gray-900">Create Trust Contract</h2>
            <button
              onClick={handleClose}
              className="text-gray-400 hover:text-gray-600 text-2xl"
            >
              ×
            </button>
          </div>

          <form onSubmit={handleSubmit} className="space-y-6">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Partner Address
              </label>
              <AddressInput
                value={partnerAddress}
                onChange={setPartnerAddress}
                placeholder="0x..."
              />
              <p className="text-xs text-gray-500 mt-1">
                Enter the Ethereum address of your trust partner
              </p>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Initial Stake Amount
              </label>
              <EtherInput
                value={stakeAmount}
                onChange={setStakeAmount}
                placeholder="0.1"
              />
              <p className="text-xs text-gray-500 mt-1">
                This will be your initial stake in the trust contract
              </p>
            </div>

            {error && (
              <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded">
                {error}
              </div>
            )}

            <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
              <h3 className="font-semibold text-blue-900 mb-2">How it works:</h3>
              <ul className="text-sm text-blue-800 space-y-1">
                <li>• You create the contract with an initial stake</li>
                <li>• Your partner adds their stake to activate it</li>
                <li>• Both earn 1% daily yield on the total value</li>
                <li>• Either can exit fairly or defect (steal all funds)</li>
              </ul>
            </div>

            <div className="flex space-x-4">
              <button
                type="button"
                onClick={handleClose}
                className="flex-1 bg-gray-300 hover:bg-gray-400 text-gray-800 font-medium py-3 px-4 rounded-lg transition-colors duration-200"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={isLoading}
                className="flex-1 bg-blue-600 hover:bg-blue-700 disabled:bg-blue-300 text-white font-medium py-3 px-4 rounded-lg transition-colors duration-200"
              >
                {isLoading ? "Creating..." : "Create Contract"}
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
}