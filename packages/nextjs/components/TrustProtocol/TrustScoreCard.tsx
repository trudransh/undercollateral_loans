"use client";

import { useTrustProtocol } from "~~/hooks/scaffold-eth/useTrustProtocol";

interface TrustScoreCardProps {
  trustScore: bigint | undefined;
}

export function TrustScoreCard({ trustScore }: TrustScoreCardProps) {
  const { formatTrustScore } = useTrustProtocol();
  
  const score = formatTrustScore(trustScore);
  const scoreNumber = parseFloat(score);
  
  // Determine trust level based on score
  const getTrustLevel = (score: number) => {
    if (score === 0) return { level: "Newcomer", color: "text-gray-600", bgColor: "bg-gray-100" };
    if (score < 1) return { level: "Building", color: "text-yellow-600", bgColor: "bg-yellow-100" };
    if (score < 5) return { level: "Trusted", color: "text-blue-600", bgColor: "bg-blue-100" };
    if (score < 10) return { level: "Reliable", color: "text-green-600", bgColor: "bg-green-100" };
    return { level: "Elite", color: "text-purple-600", bgColor: "bg-purple-100" };
  };

  const trustLevel = getTrustLevel(scoreNumber);

  return (
    <div className="bg-white rounded-lg shadow-md p-6 border border-gray-200">
      <div className="flex items-center space-x-3">
        <div className="text-3xl">⭐</div>
        <div className="flex-1">
          <h3 className="text-lg font-semibold text-gray-900">Trust Score</h3>
          <p className="text-2xl font-bold text-gray-900">{score}</p>
          <div className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${trustLevel.bgColor} ${trustLevel.color}`}>
            {trustLevel.level}
          </div>
        </div>
      </div>
      <div className="mt-4 text-sm text-gray-600">
        <p>Based on contract duration and TVL</p>
        <p>Higher scores = better reputation</p>
      </div>
    </div>
  );
}