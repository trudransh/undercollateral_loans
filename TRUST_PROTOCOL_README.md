# Trust Protocol - Layer 1 Implementation

## Overview

The Trust Protocol is a revolutionary DeFi primitive that enables passive cooperation through smart contracts. Instead of requiring active participation, contracts automatically accrue yield over time, with users only needing to act when they want to exit or defect.

## Key Features

### 🤝 Passive Cooperation Model
- Contracts automatically earn 1% daily yield on total value locked (TVL)
- No active participation required - cooperation is the default state
- Users only act to EXIT (fair split) or DEFECT (steal all funds)

### ⭐ Trust Scoring System
- Trust scores based on contract duration and TVL
- Higher scores indicate better reputation and reliability
- Trust levels: Newcomer → Building → Trusted → Reliable → Elite

### 💰 Yield Mechanics
- **Daily Yield Rate**: 1% per day (100 BPS)
- **Compounding**: Continuous
- **Risk**: Partner cooperation required
- **Penalties**: Exit penalties (α) and defect penalties (φ)

## Smart Contract Architecture

### Core Contract: `TrustContract.sol`

#### Key Functions:
- `createContract(address partner)` - Create new trust contract with initial stake
- `addStake(address partner)` - Partner adds stake to activate contract
- `exit(address partner)` - Fair exit with mild penalty
- `defect(address partner)` - Steal all funds with heavy penalty
- `getTrustScore(address user)` - Get user's trust score
- `getContractDetails(address a, address b)` - Get contract information
- `getProjectedYield(address a, address b, uint256 futureDays)` - Project future yield

#### Events:
- `ContractCreated` - New contract created
- `ContractActivated` - Contract activated when both parties stake
- `StakeAdded` - Additional stake added
- `YieldAccrued` - Yield automatically accrued
- `Defected` - User defected from contract
- `Exited` - User exited contract fairly
- `ContractFrozen` - Contract frozen/unfrozen

## Frontend Features

### 🎯 Dashboard
- Trust score display with reputation levels
- Active contracts overview
- Yield projection calculator
- Real-time contract status

### 📊 Contract Management
- Create new trust contracts
- View contract details and yield
- Exit contracts fairly
- Defect from contracts (with warning)
- Freeze/unfreeze contracts

### 💡 Yield Calculator
- Project yield over any time period
- Monthly and yearly projections
- TVL-based calculations
- Risk assessment information

## Getting Started

### Prerequisites
- Node.js 20.18.3+
- Yarn 3.2.3+
- Foundry (for smart contract development)

### Installation
```bash
# Install dependencies
yarn install

# Start local blockchain
yarn chain

# Deploy contracts
yarn deploy

# Start frontend
yarn start
```

### Usage

1. **Connect Wallet**: Connect your Ethereum wallet to the application
2. **Create Contract**: Click "Create Trust Contract" and enter partner address + stake amount
3. **Wait for Partner**: Partner needs to add their stake to activate the contract
4. **Earn Yield**: Contract automatically accrues 1% daily yield
5. **Exit or Defect**: Choose to exit fairly or defect (steal funds)

## Contract Lifecycle

```
1. User A creates contract with stake X
   ↓
2. User B adds stake Y (contract activates)
   ↓
3. Both earn 1% daily yield on (X + Y)
   ↓
4. Either user can:
   - EXIT: Fair split with mild penalty
   - DEFECT: Steal all funds with heavy penalty
```

## Risk Considerations

### ⚠️ Defection Risk
- Partners can defect and steal all funds
- Defection damages trust score
- Higher trust scores reduce defection likelihood

### 🔒 Contract Freezing
- Contracts can be frozen for loan collateral
- Frozen contracts cannot be modified
- Only contract owner can freeze/unfreeze

### 💸 Penalty System
- **Exit Penalty (α)**: Mild penalty for fair exits
- **Defect Penalty (φ)**: Heavy penalty for defection
- Penalties increase with repeated violations

## Technical Details

### Smart Contract Address
- **Local Network**: `0x5FbDB2315678afecb367f032d93F642f64180aa3`
- **Network**: Foundry (Chain ID: 31337)

### Gas Optimization
- Uses OpenZeppelin's ReentrancyGuard
- Optimized for gas efficiency
- Batch operations where possible

### Security Features
- Reentrancy protection
- Access control (Ownable)
- Input validation
- Safe math operations

## Future Roadmap

### Phase 2: Trust Scoring Layer
- Advanced reputation system
- Social trust networks
- Automated risk assessment

### Phase 3: Lending Integration
- Use trust contracts as collateral
- Automated loan origination
- Risk-based interest rates

### Phase 4: Cross-Chain Support
- Multi-chain trust contracts
- Cross-chain yield farming
- Universal trust scoring

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Support

- GitHub Issues: [Create an issue](https://github.com/your-repo/issues)
- Discord: [Join our community](https://discord.gg/your-invite)
- Documentation: [Read the docs](https://docs.trustprotocol.com)

---

**Built with ❤️ using Scaffold-ETH 2**