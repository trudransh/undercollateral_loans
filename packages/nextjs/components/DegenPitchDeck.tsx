"use client";

import React, { useEffect, useState, useCallback } from "react";

const slides = [
  {
    title: "TRUST_BOND_LENDING",
    subtitle: "UNDERCOLLATERALIZED_LOANS_POWERED_BY_COOPERATION",
    bullets: [
      "STACK: NEXTJS + WAGMI + RAINBOWKIT (SE‑2)",
      "CONTRACTS: TRUSTCONTRACT / TRUSTSCORE / LENDINGPOOL",
    ],
  },
  {
    title: "PROBLEM",
    subtitle: "CAPITAL_INEFFICIENT_ONCHAIN_CREDIT",
    bullets: [
      "COLLATERAL_REQUIREMENTS ≥150%",
      "REPUTATION/IDENTITY UNDERUTILIZED",
      "ASYMMETRIC_LENDER_DOWNSIDE",
    ],
  },
  {
    title: "SOLUTION",
    subtitle: "COOPERATION_BACKED_TRUST_BONDS",
    bullets: [
      "YIELD_WHILE_COOPERATING",
      "BORROW_UP_TO_80%_LTV",
      "SLASHING_FREEZING_YIELD_RECOVERY",
    ],
  },
  {
    title: "HOW_IT_WORKS",
    subtitle: "GAME_THEORY → CONTRACTS → UI",
    bullets: [
      "EXIT = MILD_PENALTY | DEFECT = HEAVY_PENALTY",
      "POOL_PRICES_RISK_VIA_TRUST_STATE",
      "SCAFFOLD_ETH_HOOKS FOR IO",
    ],
  },
  {
    title: "LIVE_DEMO",
    subtitle: "90_SECONDS_WALKTHROUGH",
    bullets: [
      "CREATE_TRUST_BOND",
      "BORROW_AT_80%_LTV",
      "TRIGGER_DEFECT/EXIT → PROTECTIONS",
    ],
  },
  {
    title: "SECURITY",
    subtitle: "RISK_CONTROLS",
    bullets: [
      "REENTRANCY_GUARDS",
      "FREEZING_PROTOCOL",
      "YIELD_BASED_RECOVERY",
    ],
  },
  {
    title: "ROADMAP",
    subtitle: "NEXT_STEPS",
    bullets: [
      "INTEGRATE_REAL_SCORING + ORACLES",
      "ANALYTICS_DASHBOARDS",
      "MULTICHAIN + IDENTITY",
    ],
  },
  {
    title: "THE_ASK",
    subtitle: "PARTNER_WITH_US",
    bullets: [
      "FEEDBACK_ON_PARAMETERS",
      "MENTORSHIP/GRANTS_FOR_TESTNET_LAUNCH",
    ],
  },
];

const Arrow = ({ direction }: { direction: "left" | "right" }) => (
  <div
    className="w-10 h-10 border-2 border-base-content flex items-center justify-center cursor-pointer select-none"
    aria-hidden
  >
    {direction === "left" ? "◀" : "▶"}
  </div>
);

const Slide = ({ title, subtitle, bullets }: { title: string; subtitle: string; bullets: string[] }) => (
  <div className="w-full h-full flex flex-col items-center justify-center text-center p-6">
    <h1 className="retro-title text-4xl md:text-6xl mb-4 glitch">{title}</h1>
    <h2 className="retro-subtitle text-lg md:text-2xl mb-6">{subtitle}</h2>
    <div className="max-w-3xl w-full border-4 border-base-content p-6 bg-base-100">
      <ul className="text-left font-mono space-y-2 text-sm md:text-base">
        {bullets.map((b, i) => (
          <li key={i} className="flex items-start">
            <span className="mr-2 text-primary">{">"}</span>
            <span>{b}</span>
          </li>
        ))}
      </ul>
    </div>
  </div>
);

const ProgressDots = ({ index, total }: { index: number; total: number }) => (
  <div className="flex space-x-2 mt-4">
    {Array.from({ length: total }).map((_, i) => (
      <div
        key={i}
        className={`w-2 h-2 border border-base-content ${i === index ? "bg-base-content" : "bg-base-100"}`}
      />
    ))}
  </div>
);

const DegenPitchDeck: React.FC = () => {
  const [index, setIndex] = useState(0);

  const go = useCallback(
    (dir: -1 | 1) => {
      setIndex(prev => {
        const next = prev + dir;
        if (next < 0) return slides.length - 1;
        if (next >= slides.length) return 0;
        return next;
      });
    },
    []
  );

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "ArrowRight" || e.key.toLowerCase() === "l") go(1 as 1);
      if (e.key === "ArrowLeft" || e.key.toLowerCase() === "h") go(-1 as -1);
      if (e.key === "Home") setIndex(0);
      if (e.key === "End") setIndex(slides.length - 1);
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [go]);

  const current = slides[index];

  return (
    <div className="min-h-screen bg-base-100 text-base-content flex flex-col">
      <div className="flex-1 grid grid-cols-[auto_1fr_auto] items-center">
        <div className="hidden md:flex justify-center" onClick={() => go(-1)}>
          <Arrow direction="left" />
        </div>
        <Slide title={current.title} subtitle={current.subtitle} bullets={current.bullets} />
        <div className="hidden md:flex justify-center" onClick={() => go(1)}>
          <Arrow direction="right" />
        </div>
      </div>

      <div className="border-t-4 border-base-content py-3 px-4 flex items-center justify-between font-mono text-xs">
        <div className="flex items-center space-x-2">
          <span className="badge badge-outline">DEMO_MODE</span>
          <span>Press ←/→ or H/L to navigate</span>
        </div>
        <ProgressDots index={index} total={slides.length} />
        <div>
          <span className="mr-2">{index + 1}</span>/<span>{slides.length}</span>
        </div>
      </div>
    </div>
  );
};

export default DegenPitchDeck;
