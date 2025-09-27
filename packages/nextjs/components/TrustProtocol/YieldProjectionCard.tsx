"use client";

import { useState, useEffect } from "react";
import { useTrustProtocol } from "~~/hooks/scaffold-eth/useTrustProtocol";

export function YieldProjectionCard() {
  const { dailyYieldBps, calculateAPY } = useTrustProtocol();
  const [projectionDays, setProjectionDays] = useState(30);
  const [tvl, setTvl] = useState("1");

  const calculateProjectedYield = () => {
    const tvlAmount = parseFloat(tvl);
    const dailyRate = calculateAPY() / 100; // Convert to decimal
    const totalYield = tvlAmount * dailyRate * projectionDays;
    return totalYield.toFixed(4);
  };

  const calculateMonthlyYield = () => {
    const tvlAmount = parseFloat(tvl);
    const dailyRate = calculateAPY() / 100;
    const monthlyYield = tvlAmount * dailyRate * 30;
    return monthlyYield.toFixed(4);
  };

  const calculateYearlyYield = () => {
    const tvlAmount = parseFloat(tvl);
    const dailyRate = calculateAPY() / 100;
    const yearlyYield = tvlAmount * dailyRate * 365;
    return yearlyYield.toFixed(4);
  };

  return (
    <div className="bg-white rounded-lg shadow-md p-6 border border-gray-200">
      <h2 className="text-2xl font-bold text-gray-900 mb-6">Yield Projection Calculator</h2>
      
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Input Section */}
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Total Value Locked (ETH)
            </label>
            <input
              type="number"
              value={tvl}
              onChange={(e) => setTvl(e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              placeholder="1.0"
              min="0"
              step="0.1"
            />
          </div>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Projection Period (Days)
            </label>
            <input
              type="number"
              value={projectionDays}
              onChange={(e) => setProjectionDays(parseInt(e.target.value) || 0)}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
              placeholder="30"
              min="1"
              max="365"
            />
          </div>
        </div>

        {/* Results Section */}
        <div className="space-y-4">
          <div className="bg-green-50 border border-green-200 rounded-lg p-4">
            <h3 className="font-semibold text-green-900 mb-2">Projected Yield</h3>
            <p className="text-2xl font-bold text-green-600">
              {calculateProjectedYield()} ETH
            </p>
            <p className="text-sm text-green-700">
              Over {projectionDays} days
            </p>
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div className="bg-blue-50 border border-blue-200 rounded-lg p-3">
              <h4 className="font-medium text-blue-900 text-sm">Monthly</h4>
              <p className="text-lg font-bold text-blue-600">
                {calculateMonthlyYield()} ETH
              </p>
            </div>
            
            <div className="bg-purple-50 border border-purple-200 rounded-lg p-3">
              <h4 className="font-medium text-purple-900 text-sm">Yearly</h4>
              <p className="text-lg font-bold text-purple-600">
                {calculateYearlyYield()} ETH
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Info Section */}
      <div className="mt-6 bg-gray-50 border border-gray-200 rounded-lg p-4">
        <h3 className="font-semibold text-gray-900 mb-2">Yield Information</h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm text-gray-700">
          <div>
            <span className="font-medium">Daily Rate:</span> {calculateAPY()}% APY
          </div>
          <div>
            <span className="font-medium">Compounding:</span> Continuous
          </div>
          <div>
            <span className="font-medium">Risk:</span> Partner cooperation required
          </div>
        </div>
      </div>
    </div>
  );
}