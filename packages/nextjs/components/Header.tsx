"use client";

import React, { useRef } from "react";
import Link from "next/link";
import { usePathname, useSearchParams } from "next/navigation";
import { hardhat } from "viem/chains";
import { Bars3Icon } from "@heroicons/react/24/outline";
import { FaucetButton, RainbowKitCustomConnectButton } from "~~/components/scaffold-eth";
import { useOutsideClick, useTargetNetwork } from "~~/hooks/scaffold-eth";

const RetroNavButtons = () => {
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const activeView = searchParams.get("view") || "overview";

  const buttons = [
    { key: "home", label: "HOME", href: "/", isActive: pathname === "/" && !searchParams.get("view") },
    { key: "pitch", label: "PITCH", href: "/pitch", isActive: pathname === "/pitch" },
    // { key: "overview", label: "OVERVIEW", href: "/?view=overview", isActive: pathname === "/" && activeView === "overview" },
    { key: "bonds", label: "TRUST_CONTRACTS", href: "/?view=bonds", isActive: pathname === "/" && activeView === "bonds" },
    { key: "lending", label: "LENDING_POOLS", href: "/?view=lending", isActive: pathname === "/" && activeView === "lending" },
  ];

  return (
    <div className="flex space-x-1">
      {buttons.map(btn => (
        <Link
          key={btn.key}
          href={btn.href}
          className={`px-3 py-2 border-2 font-mono text-xs font-bold transition-all ${
            btn.isActive ? "border-primary bg-primary text-primary-content" : "border-base-content bg-base-100 hover:bg-base-200"
          }`}
        >
          {btn.label}
        </Link>
      ))}
    </div>
  );
};

/**
 * Site header
 */
export const Header = () => {
  const { targetNetwork } = useTargetNetwork();
  const isLocalNetwork = targetNetwork.id === hardhat.id;

  const burgerMenuRef = useRef<HTMLDetailsElement>(null);
  useOutsideClick(burgerMenuRef, () => {
    burgerMenuRef?.current?.removeAttribute("open");
  });

  return (
    <div className="sticky lg:static top-0 navbar bg-base-100 min-h-0 shrink-0 justify-between z-20 shadow-md shadow-secondary px-0 sm:px-2">
      <div className="navbar-start w-auto lg:w-1/2">
        <details className="dropdown" ref={burgerMenuRef}>
          <summary className="ml-1 btn btn-ghost lg:hidden hover:bg-transparent">
            <Bars3Icon className="h-1/2" />
          </summary>
          <ul
            className="menu menu-compact dropdown-content mt-3 p-2 shadow-sm bg-base-100 rounded-box w-52"
            onClick={() => {
              burgerMenuRef?.current?.removeAttribute("open");
            }}
          >
            <li>
              <RetroNavButtons />
            </li>
          </ul>
        </details>
        <div className="hidden lg:flex items-center gap-4 ml-2 mr-6 shrink-0">
          <h1 className="retro-title text-xl lg:text-2xl font-bold font-mono tracking-wider">LENDING_W3.0</h1>
          <RetroNavButtons />
        </div>
        <ul className="lg:hidden"><RetroNavButtons /></ul>
      </div>
      <div className="navbar-end grow mr-4">
        <RainbowKitCustomConnectButton />
        {isLocalNetwork && <FaucetButton />}
      </div>
    </div>
  );
};
