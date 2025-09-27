<!-- Pitch Deck Slides (use '---' as slide breaks) -->
## Slide 1 – Title & One‑liner
- **Project**: Trust Bond Lending
- **One‑liner**: Under‑collateralized lending secured by cooperation‑backed trust bonds
- **Who**: Web3 lenders and borrowers excluded by high collateral requirements
- **Stack**: Frontend (Scaffold‑ETH 2), Contracts (Foundry)

---

## Slide 2 – Problem
- High collateral (≥150%) blocks most borrowers
- On‑chain credit primitives underutilized
- Lenders face asymmetric downside and poor recovery on defaults

---

## Slide 3 – Solution
- Trust bonds between partners generate cooperation yield
- Borrow against active bonds at up to 80% LTV
- Automated slashing, freezing, and yield‑based recovery protect lenders

---

## Slide 4 – How It Works
- Passive cooperation: yield accrues while both partners cooperate
- Penalties: exit (mild) vs defect (heavy) per whitepaper formulas
- Lending pool prices risk using trust state and trust scores

---

## Slide 5 – Live Demo (≈90s)
1. Create a trust bond with partner
2. Show cooperation yield status
3. Borrow against the bond (80% LTV)
4. Trigger exit/defect → observe slashing and protections
5. Lender deposits liquidity and earns yield

---

## Slide 6 – Architecture
- Contracts: `TrustContract`, `TrustScore`, `LendingPool`
- Frontend: Next.js + Wagmi + RainbowKit (SE‑2)
- Data flow: Scaffold‑ETH hooks for reads/writes/events

---

## Slide 7 – Key Features
- Trust Bonds: create/manage, yield accrual, cooperative state
- Lending Pool: borrow, lend, manage positions
- Risk: freezing, slashing, yield‑based recovery

---

## Slide 8 – Security & Risk
- Reentrancy guards and ownership controls
- Freezing for turbulent conditions
- Conservative LTV and yield‑driven recovery

---

## Slide 9 – Roadmap
- Integrate deployed contracts and real scoring
- Lender analytics dashboards and oracle feeds
- Multi‑chain support and identity integrations (ENS/SBTs)

---

## Slide 10 – The Ask
- Feedback on risk parameters and scoring weights
- Support to run a guarded testnet launch

---

## Slide 11 – Run Locally
```bash
cd packages/nextjs
yarn install
yarn dev
```
Connect wallet (Sepolia/Goerli), open http://localhost:3000

---

## Slide 12 – Contact
- Team: <add names/handles>
- Repo: github.com/trudransh/undercollateral_loans

---

# Trust Bond Lending Pool UI

This is a comprehensive UI for the Trust Protocol's undercollateralized lending system. It allows users to create trust bonds, earn yield through cooperation, and borrow against their trust bonds with minimal collateral requirements.

## Features

### 🤝 Trust Bond Management
- **Create Trust Bonds**: Partner with trusted individuals to create mutual stake bonds
- **Passive Yield**: Earn 1% daily yield automatically through cooperation
- **Fair Exit**: Exit bonds with mild penalties for fair wealth splitting  
- **Defection Detection**: Heavy penalties for defecting to protect partner funds

### 💰 Lending Pool Operations
- **Borrow Against Bonds**: Use trust bonds as collateral for up to 80% LTV loans
- **Competitive Rates**: 5.5% APR interest rates for trust bond backed loans
- **Lend to Earn**: Provide liquidity to earn guaranteed yields from borrower interest

### 🛡️ Risk Management
- **Slashing Mechanism**: Automatic penalty enforcement for bond violations
- **Freezing Protocol**: Temporary position suspension during high-risk periods
- **Yield Recovery**: Use accumulated trust bond yield to cover default losses
- **Cooperation Incentives**: Better rates and higher yields for maintaining active bonds

## Getting Started

1. **Install Dependencies**
   ```bash
   cd packages/nextjs
   yarn install
   ```

2. **Start Development Server**
   ```bash
   yarn dev
   ```

3. **Connect Wallet**
   - Use MetaMask or any WalletConnect compatible wallet
   - Ensure you have test ETH for Sepolia/Goerli testnet

## Application Structure

### Components

- **`TrustLendingApp.tsx`** - Main application shell with navigation
- **`TrustBondManager.tsx`** - Trust bond creation and management interface
- **`LendingPoolDashboard.tsx`** - Borrowing, lending, and loan management

### Key Features by Tab

#### Overview Tab
- Protocol statistics and TVL metrics
- How-it-works explanations
- Risk management feature descriptions
- Quick navigation to other features

#### Trust Bonds Tab  
- Create new trust bonds with partners
- View and manage existing bonds
- Monitor yield accrual and cooperation status
- Execute exits and defections
- Portfolio analytics and trust scoring

#### Lending Pool Tab
- **Borrow**: Select trust bond collateral and borrow against it
- **Lend**: Provide liquidity to earn from borrower interest payments
- **Manage**: View active loans, execute liquidations, handle defaults
- **Yield Recovery**: Claim recovered funds from defaulted loan yield

## Smart Contract Integration

The UI integrates with the Trust Protocol smart contracts:

- **TrustContract.sol**: Core trust bond logic with passive cooperation model
- **LendingPool.sol**: Manages borrowing, lending, and liquidation logic
- **TrustScore.sol**: Calculates user reputation and creditworthiness

## Risk Mitigation Features

### Automated Slashing
- Defection from trust bonds triggers automatic penalty
- Funds redistributed to protect honest participants
- Heavy penalties (ϕ) discourage malicious behavior

### Dynamic Freezing
- Loans can be temporarily frozen during market volatility
- Protects both lenders and borrowers from liquidation cascades
- Manual unfreeze capability for authorized parties

### Yield-Based Recovery
- Default losses covered by accumulated trust bond yield
- Lenders protected through diversified yield streams
- Sustainable model encouraging long-term cooperation

## Development Notes

### Mock Data
Currently uses mock data for demonstration. To integrate with actual smart contracts:

1. Update contract addresses in `contracts/deployedContracts.ts`
2. Replace mock data calls with actual `useReadContract` and `useWriteContract` hooks
3. Add proper error handling for blockchain interactions
4. Implement transaction confirmation flows

### Styling
- Uses Tailwind CSS for responsive design
- DaisyUI components for consistent UI patterns
- Custom gradient backgrounds and hover effects
- Mobile-first responsive design approach

### State Management
- React hooks for local component state
- Wagmi for blockchain state management
- Toast notifications for user feedback
- Modal systems for multi-step workflows

## Next Steps

1. **Smart Contract Integration**: Connect to deployed trust and lending contracts
2. **Real Yield Calculation**: Implement actual yield calculation based on contract state
3. **Advanced Analytics**: Add charts for yield performance and risk metrics  
4. **Mobile Optimization**: Enhance mobile user experience
5. **Multi-chain Support**: Extend to additional EVM networks

## Hackathon Pitch Deck (Judge-Friendly)

Use this section as a ready-to-build outline for your presentation deck. Each slide has a clear goal, suggested talking points, and demo checkpoints. Target a 4–6 minute walkthrough.

### Slide 1 – Title & One‑liner
- **Project name**: Trust Bond Lending
- **One‑liner**: Under‑collateralized lending secured by cooperation-backed trust bonds
- **Who for**: Web3 lenders and borrowers locked out by high collateral requirements

### Slide 2 – Problem
- High collateral requirements (≥150%) exclude most borrowers
- On‑chain credit is scarce; identity/reputation is underused
- Lenders face asymmetric downside and poor recovery on defaults

### Slide 3 – Solution
- Trust bonds: pair users, stake, and accrue cooperation yield
- Borrow against active trust bonds with lower collateral (up to 80% LTV)
- Automated slashing, freezing, and yield‑based recovery protect lenders

### Slide 4 – How It Works (Game Theory → Contracts → UI)
- Passive cooperation model: yield accrues while both parties remain cooperative
- Penalties: exit (mild) vs. defect (heavy) based on whitepaper formulas
- Lending pool uses trust bond state and trust scores to price risk

### Slide 5 – Live Demo Plan (90 seconds)
1. Create a trust bond with a partner address
2. Show yield accrual and cooperation status
3. Borrow against the bond at 80% LTV
4. Trigger a defect/exit scenario → observe slashing and protections
5. Lender deposits liquidity and earns predictable yield

### Slide 6 – Architecture
- Contracts: `TrustContract`, `TrustScore`, `LendingPool`
- Frontend: Next.js + Wagmi + RainbowKit (SE‑2)
- Data flow: contract reads/writes via Scaffold‑ETH hooks

### Slide 7 – Why Now / Differentiation
- Combines incentive‑aligned game theory with risk controls
- Recovery via yield rather than pure liquidation
- Works with social/identity primitives without requiring full KYC

### Slide 8 – Security & Risk Mitigations
- Reentrancy guards and ownership controls
- Freezing mechanism for turbulent conditions
- Yield‑driven recovery and conservative LTV thresholds

### Slide 9 – Roadmap
- Integrate deployed contracts, real scoring, and oracle feeds
- Advanced analytics for lenders and risk dashboards
- Multi‑chain support and identity integrations (e.g., ENS, SBTs)

### Slide 10 – The Ask
- Feedback on risk parameters and scoring weights
- Mentorship or grants to run a guarded launch on testnet

### Backup Slides (Optional)
- Formulas (defect/exit penalties, yield) and parameter table
- Contract interfaces and key events
- Threat model and mitigation coverage
- Glossary of terms: trust bond, cooperation yield, LTV, freeze

### Demo Script (Quick Reference)
- 0:00 – One‑liner and problem framing
- 0:30 – Create trust bond (enter partner address, stake)
- 1:30 – Show cooperation yield ticking and trust state
- 2:00 – Borrow flow: select bond → set amount → confirm
- 2:45 – Trigger exit/defect → show slashing and lender protection
- 3:30 – Lender deposit → see APR and pool utilization
- 4:00 – Q&A: risks, recovery, roadmap

### Assets to Prepare
- Network and contract addresses (testnet)
- 2–3 screenshots/GIFs of the flows above
- Simple architecture diagram and penalty table
- A one‑pager link in the repo pointing to this section