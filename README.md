# Trust Bond Lending – Undercollateralized Loans on Ethereum (Celo Sepolia Demo)

A hackathon project implementing an undercollateralized lending protocol powered by cooperation-backed trust bonds. It ships a Foundry smart-contract suite and a Next.js (Scaffold‑ETH 2) frontend for a judge‑friendly demo.

## Key Idea
- Borrowers form trust bonds with partners and stake ETH.
- While cooperating, bonds accrue yield; defect/exit applies penalties.
- LendingPool allows borrowing against active trust bonds (up to 80% LTV) with lender protections via slashing, freezing, and yield‑based recovery.

## Monorepo Structure
- `packages/foundry`: Solidity contracts, tests, and deployment scripts (Foundry)
- `packages/nextjs`: Next.js app (Scaffold‑ETH 2), Wagmi + RainbowKit UI

## Smart Contracts (packages/foundry)
- `TrustContract.sol`
  - Create/add stake to trust bonds, exit (mild penalty), defect (heavy penalty)
  - Accrue cooperation yield; freeze/unfreeze by authorized lenders
  - Claim yields, compute user total value for lending collateralization
- `TrustScore.sol`
  - Simplified trust scoring: rewards number/age of bonds; supports penalty offsets
- `LendingPool.sol`
  - Borrow using all user bonds as collateral (MAX_LTV=80%)
  - Interest rate discounts from trust score; repay/liquidate flows
  - Freezing + yield‑claim on default for lender protection

### Dev Tooling
- Foundry config in `packages/foundry/foundry.toml`
- Makefile targets for build/test/deploy/verify
- Deployment helper scripts under `packages/foundry/deployments` and `packages/foundry/script`

## Frontend (packages/nextjs)
- New degen‑styled black/white UI with modern UX
- `TrustLendingApp.tsx`: high‑level app views
- `TrustBondManager.tsx`: create/manage trust bonds
- `LendingPoolDashboard_New.tsx`: borrow, lend, manage loans
- Wallet connect/disconnect in navbar via RainbowKit; address dropdown with copy/QR/explorer/switch network
- Judge deck at `/pitch` (keyboard nav: ←/→, H/L)

### Smart Contract Integration
- Contract ABIs/addresses in `packages/nextjs/contracts/*` and `contracts/deployedContracts.ts`
- Use Scaffold‑ETH 2 hooks:
  - `useScaffoldReadContract` for reads
  - `useScaffoldWriteContract` for writes
  - `useScaffoldEventHistory` for events

## Run Locally
```bash
# 1) install deps
yarn install

# 2) run local chain (optional)
# in another terminal: yarn chain

# 3) start frontend
yarn start
# open http://localhost:3000 (or /pitch for the deck)
```

## Deploy (Celo Sepolia)
Prereqs: Foundry installed; a funded Celo Sepolia account; working RPC URL.

```bash
cd packages/foundry
forge build

# recommended public RPC
export RPC_URL=https://celo-sepolia.blockpi.network/v1/rpc/public
export PRIVATE_KEY=0xYOUR_PRIVATE_KEY

# Deploy + verify (Blockscout)
make deploy-celo-sepolia-verify

# OR deploy only
make deploy-celo-sepolia

# Manual verification helper
make verify-celo-sepolia \
  CONTRACT_TRUST=0x... \
  CONTRACT_SCORE=0x... \
  CONTRACT_LENDING=0x...
```

After deployment, add addresses to `packages/nextjs/contracts/deployedContracts.ts` and restart the frontend.

## Demo Flow for Judges (90s)
1) Create a trust bond with a partner; show cooperation yield ticking
2) Borrow against the bond (up to 80% LTV)
3) Trigger exit/defect → see slashing and protections
4) Lender deposits liquidity and earns yield

## Security & Risk
- Reentrancy guards, owner‑gated admin
- Freezing mechanism; conservative LTV
- Yield‑based recovery on default

## Notes
- Trust scoring is simplified for MVP; parameters can be tuned
- All contract operations are gas‑aware and event‑rich for easy monitoring

## License
MIT