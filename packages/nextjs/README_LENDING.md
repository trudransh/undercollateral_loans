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