# Trust Protocol - Celo Sepolia Deployment Guide

Complete deployment guide for Trust Protocol smart contracts on Celo Sepolia testnet.

## 📋 Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
- Celo Sepolia testnet tokens for deployment (get from [Celo Faucet](https://faucet.celo.org/sepolia))
- Git and basic command line knowledge

## 🌐 Network Configuration

- **Network**: Celo Sepolia Testnet
- **Chain ID**: 11142220 (0xaa044c)
- **RPC URL**: https://forno.celo.org/sepolia
- **Explorer**: https://celo-sepolia.blockscout.com/
- **Faucet**: https://faucet.celo.org/sepolia

## 🚀 Quick Start Deployment

### 1. Setup Environment

```bash
# Navigate to foundry directory
cd packages/foundry

# Setup deployment scripts
make setup-celo

# Check wallet balance (should have CELO for gas)
make balance
```

### 2. Deploy All Contracts

```bash
# Deploy complete Trust Protocol
make deploy-celo
```

This will:
- Compile all contracts
- Deploy TrustContract, TrustScore, and LendingPool in sequence
- Configure contract permissions
- Save deployment addresses to `deployments/celo_sepolia_addresses.txt`

### 3. Verify Contracts

```bash
# Set contract addresses from deployment
export TRUST_CONTRACT_ADDRESS=0x...
export TRUST_SCORE_ADDRESS=0x...
export LENDING_POOL_ADDRESS=0x...

# Verify all contracts
make verify-celo
```

## 🔧 Individual Contract Deployment

### Deploy TrustContract

```bash
make deploy-trust-contract
```

### Deploy TrustScore

```bash
export TRUST_CONTRACT_ADDRESS=0x...
make deploy-trust-score
```

### Deploy LendingPool

```bash
export TRUST_CONTRACT_ADDRESS=0x...
export TRUST_SCORE_ADDRESS=0x...
make deploy-lending-pool
```

## 📜 Manual Deployment Commands

### Using Forge Scripts

```bash
# Deploy TrustContract
forge script script/DeployTrustContract.s.sol:DeployTrustContract \
  --rpc-url https://forno.celo.org/sepolia \
  --private-key 0xb1db46dc1e869bfbb6a33ed21a36f0f9af954c5f7fcec7980044a7de756b14b4 \
  --broadcast

# Deploy TrustScore (replace TRUST_CONTRACT_ADDRESS)
TRUST_CONTRACT_ADDRESS=0x... forge script script/DeployTrustScore.s.sol:DeployTrustScore \
  --rpc-url https://forno.celo.org/sepolia \
  --private-key 0xb1db46dc1e869bfbb6a33ed21a36f0f9af954c5f7fcec7980044a7de756b14b4 \
  --broadcast

# Deploy LendingPool (replace both addresses)
TRUST_CONTRACT_ADDRESS=0x... \
TRUST_SCORE_ADDRESS=0x... \
forge script script/DeployLendingPool.s.sol:DeployLendingPool \
  --rpc-url https://forno.celo.org/sepolia \
  --private-key 0xb1db46dc1e869bfbb6a33ed21a36f0f9af954c5f7fcec7980044a7de756b14b4 \
  --broadcast
```

### Manual Verification

```bash
# Verify TrustContract
forge verify-contract \
  --chain celo_sepolia \
  --compiler-version 0.8.20 \
  0xYOUR_TRUST_CONTRACT_ADDRESS \
  contracts/TrustContract.sol:TrustContract

# Verify TrustScore
forge verify-contract \
  --chain celo_sepolia \
  --compiler-version 0.8.20 \
  --constructor-args $(cast abi-encode "constructor(address)" 0xTRUST_CONTRACT_ADDRESS) \
  0xYOUR_TRUST_SCORE_ADDRESS \
  contracts/TrustScore.sol:TrustScore

# Verify LendingPool
forge verify-contract \
  --chain celo_sepolia \
  --compiler-version 0.8.20 \
  --constructor-args $(cast abi-encode "constructor(address,address)" 0xTRUST_CONTRACT_ADDRESS 0xTRUST_SCORE_ADDRESS) \
  0xYOUR_LENDING_POOL_ADDRESS \
  contracts/LendingPool.sol:LendingPool
```

## 📁 File Structure

```
packages/foundry/
├── contracts/           # Smart contracts
│   ├── TrustContract.sol
│   ├── TrustScore.sol
│   ├── LendingPool.sol
│   └── ...
├── script/             # Deployment scripts
│   ├── DeployTrustProtocol.s.sol
│   ├── DeployTrustContract.s.sol
│   ├── DeployTrustScore.s.sol
│   └── DeployLendingPool.s.sol
├── deployments/        # Deployment addresses
│   └── celo_sepolia_addresses.txt
├── deploy_celo_sepolia.sh      # Main deployment script
├── deploy_individual.sh         # Individual deployments
├── verify_contracts.sh          # Verification script
├── Makefile.celo               # Celo-specific commands
└── foundry.toml                # Foundry configuration
```

## 🛠 Troubleshooting

### Common Issues

1. **Insufficient Balance**
   ```bash
   # Check balance
   make balance
   # Get testnet tokens from Celo faucet
   ```

2. **RPC Issues**
   ```bash
   # Test RPC connection
   cast block-number --rpc-url https://forno.celo.org/sepolia
   ```

3. **Verification Failures**
   ```bash
   # Ensure contract addresses are correct
   make info
   # Try verifying individual contracts
   make verify-trust-contract
   ```

4. **Compilation Errors**
   ```bash
   # Clean and rebuild
   forge clean
   forge build
   ```

### Gas Estimation

- TrustContract: ~2,000,000 gas
- TrustScore: ~1,500,000 gas  
- LendingPool: ~3,000,000 gas
- Total: ~6,500,000 gas

Recommended CELO balance: 0.01 CELO for deployment

## 📊 Post-Deployment

### View Contracts on Explorer

After deployment, your contracts will be available at:
- https://celo-sepolia.blockscout.com/address/TRUST_CONTRACT_ADDRESS
- https://celo-sepolia.blockscout.com/address/TRUST_SCORE_ADDRESS  
- https://celo-sepolia.blockscout.com/address/LENDING_POOL_ADDRESS

### Integration

Update your frontend configuration with the deployed addresses:

```typescript
// Frontend config
const contracts = {
  trustContract: "0xYOUR_TRUST_CONTRACT_ADDRESS",
  trustScore: "0xYOUR_TRUST_SCORE_ADDRESS", 
  lendingPool: "0xYOUR_LENDING_POOL_ADDRESS"
};
```

## 🎯 Next Steps

1. Test contract interactions on testnet
2. Setup frontend integration
3. Deploy to Celo mainnet when ready
4. Implement monitoring and analytics

## 💡 Commands Reference

```bash
# Setup and info
make setup-celo          # Setup scripts
make info               # Show deployment info
make balance            # Check wallet balance

# Deployment
make deploy-celo        # Deploy all contracts
make deploy-trust-contract    # Deploy individual contracts
make deploy-trust-score
make deploy-lending-pool

# Verification  
make verify-celo        # Verify all contracts
make verify-trust-contract    # Verify individual contracts
make verify-trust-score
make verify-lending-pool

# Help
make help-celo          # Show all commands
```

## 🔐 Security Notes

- Never commit private keys to version control
- Use environment variables for sensitive data
- Test thoroughly on testnet before mainnet deployment
- Consider using hardware wallets for mainnet deployments