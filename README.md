## Trust Bond Lending
Undercollateralized lending, built on cooperative trust.

We’re exploring a simple idea with big implications: if two people choose to cooperate on‑chain, that cooperation itself can secure credit. Our protocol lets users form “trust contracts,” earn yield while both sides behave, and unlock borrowing power without over‑collateralizing their lives.

### Why this matters
Today, most on‑chain credit requires 150%+ collateral. That excludes the people who need it most. By using incentives instead of hard collateral alone—think: cooperation yield, fair exits, and slashing for bad behavior—we can make credit more inclusive without making lenders reckless.

### What’s in the box
- Smart contracts (Foundry) that model cooperative bonds, trust scoring, and a lending pool.
- A clean, black‑and‑white Next.js app (Scaffold‑ETH 2) that’s fast to demo and easy to reason about.

---

## Architecture at a glance
- `TrustContract` — create a bond with a partner, add stake, accrue cooperation yield, exit (mild penalty), or defect (heavy penalty). Lenders can freeze/unfreeze and claim yields to cover risk.
- `TrustScore` — a pragmatic scoring model for the MVP: weighs number of bonds and time active; tracks penalty offsets. Purposefully simple so we can ship, test, and iterate.
- `LendingPool` — lends against the total value of a user’s active bonds (up to 80% LTV), with rate discounts from trust score, and clear repay/default flows.

The contracts are event‑rich and designed for operational clarity. We’ve prioritized safety basics (reentrancy guards, owner‑gated admin) and operational controls (freeze, yield‑based recovery) over theoretical completeness. This is opinionated by design.

---

## Frontend
- `TrustLendingApp` — the shell: Overview, Bonds, and Lending views.
- `TrustBondManager` — create and manage cooperative bonds.
- `LendingPoolDashboard_New` — borrow, lend, and manage loans.
- Wallet UX — RainbowKit in the navbar with connect, disconnect, copy, QR, explorer, and network switch.
- Pitch mode — `/pitch` shows a concise, keyboard‑driven deck for live demos.

Under the hood, we stick to Scaffold‑ETH 2 conventions:
- Reads — `useScaffoldReadContract`
- Writes — `useScaffoldWriteContract`
- Events — `useScaffoldEventHistory`
Addresses and ABIs are centralized in `packages/nextjs/contracts/deployedContracts.ts`.

---

## Local setup
```bash
# install
yarn install

# optional: run local chain for debugging
yarn chain

# start the app
yarn start
# visit http://localhost:3000 (or /pitch)
```

---

## Deploy to Celo Sepolia
You’ll need Foundry, a funded testnet account, and a working RPC (we use BlockPI’s public endpoint).

```bash
cd packages/foundry
forge build

export RPC_URL=https://celo-sepolia.blockpi.network/v1/rpc/public
export PRIVATE_KEY=0xYOUR_PRIVATE_KEY

# one‑shot deploy + verify (Blockscout)
make deploy-celo-sepolia-verify

# or deploy then verify
make deploy-celo-sepolia
make verify-celo-sepolia \
  CONTRACT_TRUST=0x... \
  CONTRACT_SCORE=0x... \
  CONTRACT_LENDING=0x...
```

After deploying, update `packages/nextjs/contracts/deployedContracts.ts` and reload the app.
---
Deployed and Verified Contracts on Celo Sepolia:
Trust Contract  : https://celo-sepolia.blockscout.com/address/0xe2726ce1021b21b231562c001a1ecfaa9c9893e2?tab=contract Trust Score:  https://celo-sepolia.blockscout.com/address/0x6cbc62fc95208c4137c928e2a0079836c50f0d14
Lending Pool: https://celo-sepolia.blockscout.com/address/0x273be2224de0dd294c9885ec3d169ab0c7a0181c

---

## Demo script (≈90 seconds)
1) Create a trust bond → show cooperation yield alive and well.
2) Borrow against that bond (up to 80% LTV) → confirm receipt.
3) Simulate exit/defect → highlight fair exit and slashing safeguards.
4) Show lender earnings and recovery via yields.

This is intentionally crisp. Judges should see the value, not wrestle the UI.

---

## Risk, safety, and what’s next
- Safety first: reentrancy guards, owner controls, freezing, conservative LTV.
- Recovery: accrued yields help cover losses on defaults.
- Next: richer trust modeling, oracle inputs, analytics for lenders, and multi‑chain.

We’re not pretending trust can be solved in one weekend. But we can ship an MVP that moves the conversation forward—and gives people a reason to care.

---

## License
MIT