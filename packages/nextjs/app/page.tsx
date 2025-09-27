"use client";

import Link from "next/link";
import type { NextPage } from "next";
import { useAccount } from "wagmi";
import { BugAntIcon, MagnifyingGlassIcon } from "@heroicons/react/24/outline";
import { Address } from "~~/components/scaffold-eth";
import { TrustDashboard } from "~~/components/TrustProtocol/TrustDashboard";

const Home: NextPage = () => {
  const { address: connectedAddress } = useAccount();

  return (
    <>
      <div className="min-h-screen bg-gray-50">
        {/* Header */}
        <div className="bg-white shadow-sm border-b border-gray-200">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="flex justify-between items-center py-6">
              <div className="flex items-center space-x-4">
                <h1 className="text-2xl font-bold text-gray-900">Trust Protocol</h1>
                <span className="bg-blue-100 text-blue-800 text-xs font-medium px-2.5 py-0.5 rounded-full">
                  Beta
                </span>
              </div>
              <div className="flex items-center space-x-4">
                <Link
                  href="/debug"
                  className="text-gray-600 hover:text-gray-900 px-3 py-2 rounded-md text-sm font-medium"
                >
                  Debug
                </Link>
                <Link
                  href="/blockexplorer"
                  className="text-gray-600 hover:text-gray-900 px-3 py-2 rounded-md text-sm font-medium"
                >
                  Explorer
                </Link>
              </div>
            </div>
          </div>
        </div>

        {/* Main Content */}
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <TrustDashboard />
        </div>

        {/* Footer */}
        <div className="bg-white border-t border-gray-200 mt-16">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
            <div className="text-center text-gray-600">
              <p className="mb-4">
                Built with Scaffold-ETH 2 • Trust Protocol Layer 1
              </p>
              <div className="flex justify-center space-x-6">
                <Link href="/debug" className="hover:text-gray-900">
                  Debug Contracts
                </Link>
                <Link href="/blockexplorer" className="hover:text-gray-900">
                  Block Explorer
                </Link>
              </div>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default Home;
