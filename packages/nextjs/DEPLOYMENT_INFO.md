# Trust Protocol - Celo Sepolia Deployment

## Deployed Contracts (Verified on Blockscout)

### Trust Contract
- **Address**: `0xe2726ce1021b21b231562c001a1ecfaa9c9893e2`
- **Explorer**: https://celo-sepolia.blockscout.com/address/0xe2726ce1021b21b231562c001a1ecfaa9c9893e2?tab=contract
- **Description**: Core trust bond management contract for creating and managing mutual trust relationships

### Trust Score
- **Address**: `0x6cbc62fc95208c4137c928e2a0079836c50f0d14`
- **Explorer**: https://celo-sepolia.blockscout.com/address/0x6cbc62fc95208c4137c928e2a0079836c50f0d14
- **Description**: Trust scoring system for evaluating user creditworthiness based on trust bonds

### Lending Pool
- **Address**: `0x273be2224de0dd294c9885ec3d169ab0c7a0181c`
- **Explorer**: https://celo-sepolia.blockscout.com/address/0x273be2224de0dd294c9885ec3d169ab0c7a0181c
- **Description**: Undercollateralized lending protocol using trust scores for borrowing capacity

## Network Configuration
- **Chain ID**: 11142220
- **Network Name**: Celo Sepolia
- **RPC URL**: https://rpc.ankr.com/celo_sepolia
- **Explorer**: https://celo-sepolia.blockscout.com
- **Native Currency**: CELO

## Frontend Integration
The contracts are now configured in the frontend:
- Added to `contracts/deployedContracts.ts` with proper ABIs
- Celo Sepolia chain added to `scaffold.config.ts`
- RPC override configured for optimal connectivity
- All contracts verified on Blockscout for easy interaction

## Key Features Available
1. **Trust Bond Creation**: Users can create mutual trust bonds with ETH stakes
2. **Yield Generation**: Staked ETH generates daily yield (5 basis points)
3. **Trust Scoring**: Automated scoring based on trust bond performance
4. **Undercollateralized Lending**: Borrow against trust scores with minimal collateral
5. **Social Cooperation**: Mutual accountability through shared financial stakes

## Next Steps
1. Connect wallet to Celo Sepolia network
2. Test trust bond creation with small amounts
3. Verify yield generation and trust score updates
4. Test lending functionality with accumulated trust scores
5. Monitor contract performance and user adoption

All contracts are live and ready for testing on Celo Sepolia testnet!