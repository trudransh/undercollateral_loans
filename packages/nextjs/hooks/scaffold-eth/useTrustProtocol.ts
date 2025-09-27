import { useScaffoldReadContract, useScaffoldWriteContract } from "./useScaffoldContract";
import { useAccount } from "wagmi";
import { parseEther, formatEther } from "viem";
import { useState, useEffect } from "react";

export interface ContractView {
  addr0: string;
  addr1: string;
  stake0: bigint;
  stake1: bigint;
  accruedYield: bigint;
  isActive: boolean;
  isFrozen: boolean;
  createdAt: bigint;
  lastYieldUpdate: bigint;
}

export interface TrustProtocolData {
  trustScore: bigint;
  dailyYieldBps: bigint;
  contracts: ContractView[];
  projectedYields: Record<string, bigint>;
}

export function useTrustProtocol() {
  const { address } = useAccount();
  const [trustData, setTrustData] = useState<TrustProtocolData | null>(null);

  // Read contract data
  const { data: trustScore } = useScaffoldReadContract({
    contractName: "TrustContract",
    functionName: "getTrustScore",
    args: address ? [address] : undefined,
  });

  const { data: dailyYieldBps } = useScaffoldReadContract({
    contractName: "TrustContract",
    functionName: "DAILY_YIELD_BPS",
  });

  // Write contract functions
  const { writeContractAsync: createContract } = useScaffoldWriteContract({
    contractName: "TrustContract",
  });

  const { writeContractAsync: addStake } = useScaffoldWriteContract({
    contractName: "TrustContract",
  });

  const { writeContractAsync: exitContract } = useScaffoldWriteContract({
    contractName: "TrustContract",
  });

  const { writeContractAsync: defectContract } = useScaffoldWriteContract({
    contractName: "TrustContract",
  });

  const { writeContractAsync: freezeContract } = useScaffoldWriteContract({
    contractName: "TrustContract",
  });

  // Get contract details
  const getContractDetails = async (partner: string) => {
    if (!address) return null;
    
    const { data } = await useScaffoldReadContract({
      contractName: "TrustContract",
      functionName: "getContractDetails",
      args: [address, partner],
    });
    
    return data;
  };

  // Get projected yield
  const getProjectedYield = async (partner: string, futureDays: number) => {
    if (!address) return null;
    
    const { data } = await useScaffoldReadContract({
      contractName: "TrustContract",
      functionName: "getProjectedYield",
      args: [address, partner, BigInt(futureDays)],
    });
    
    return data;
  };

  // Contract creation
  const createTrustContract = async (partner: string, stakeAmount: string) => {
    if (!createContract) return;
    
    return await createContract({
      functionName: "createContract",
      args: [partner as `0x${string}`],
      value: parseEther(stakeAmount),
    });
  };

  // Add stake to existing contract
  const addStakeToContract = async (partner: string, stakeAmount: string) => {
    if (!addStake) return;
    
    return await addStake({
      functionName: "addStake",
      args: [partner as `0x${string}`],
      value: parseEther(stakeAmount),
    });
  };

  // Exit contract (fair split)
  const exitTrustContract = async (partner: string) => {
    if (!exitContract) return;
    
    return await exitContract({
      functionName: "exit",
      args: [partner as `0x${string}`],
    });
  };

  // Defect from contract (steal all funds)
  const defectFromContract = async (partner: string) => {
    if (!defectContract) return;
    
    return await defectContract({
      functionName: "defect",
      args: [partner as `0x${string}`],
    });
  };

  // Freeze/unfreeze contract
  const toggleContractFreeze = async (partner: string, freeze: boolean) => {
    if (!freezeContract) return;
    
    return await freezeContract({
      functionName: "freezeContract",
      args: [address as `0x${string}`, partner as `0x${string}`, freeze],
    });
  };

  // Utility functions
  const formatTrustScore = (score: bigint | undefined) => {
    if (!score) return "0";
    return formatEther(score);
  };

  const formatYield = (yieldAmount: bigint | undefined) => {
    if (!yieldAmount) return "0";
    return formatEther(yieldAmount);
  };

  const calculateDailyYield = (tvl: bigint) => {
    if (!dailyYieldBps) return "0";
    const dailyYield = (tvl * dailyYieldBps) / BigInt(10000);
    return formatEther(dailyYield);
  };

  const calculateAPY = () => {
    if (!dailyYieldBps) return 0;
    return Number(dailyYieldBps) / 100; // Convert BPS to percentage
  };

  return {
    // Data
    trustScore,
    dailyYieldBps,
    trustData,
    
    // Contract functions
    createTrustContract,
    addStakeToContract,
    exitTrustContract,
    defectFromContract,
    toggleContractFreeze,
    getContractDetails,
    getProjectedYield,
    
    // Utility functions
    formatTrustScore,
    formatYield,
    calculateDailyYield,
    calculateAPY,
  };
}