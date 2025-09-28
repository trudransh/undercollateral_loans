#!/bin/bash

# Trust Protocol Deployment Script for Celo Sepolia
# Chain ID: 11142220 (0xaa044c)
# RPC: https://forno.celo.org/sepolia
# Explorer: https://celo-sepolia.blockscout.com/

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CHAIN_NAME="celo_sepolia"
CHAIN_ID="11142220"
RPC_URL="https://rpc.ankr.com/celo_sepolia"
EXPLORER_URL="https://celo-sepolia.blockscout.com"
PRIVATE_KEY="0xb1db46dc1e869bfbb6a33ed21a36f0f9af954c5f7fcec7980044a7de756b14b4"

echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}    TRUST PROTOCOL DEPLOYMENT SCRIPT${NC}"
echo -e "${BLUE}         Celo Sepolia Testnet${NC}"
echo -e "${BLUE}=============================================${NC}"
echo ""

# Create deployments directory
mkdir -p deployments

# Step 1: Compile contracts
echo -e "${YELLOW}📦 Step 1: Compiling contracts...${NC}"
forge build
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Compilation failed!${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Compilation successful!${NC}"
echo ""

# Step 2: Deploy all contracts
echo -e "${YELLOW}🚀 Step 2: Deploying contracts to Celo Sepolia...${NC}"
forge script script/DeployTrustProtocol.s.sol:DeployTrustProtocol \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --verify \
    --etherscan-api-key "YourBlockscoutAPIKey" \
    -vvvv

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Deployment failed!${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All contracts deployed successfully!${NC}"
echo ""

# Step 3: Display deployment information
echo -e "${YELLOW}📋 Step 3: Deployment Summary${NC}"
if [ -f "deployments/celo_sepolia_addresses.txt" ]; then
    echo -e "${GREEN}Deployment addresses:${NC}"
    cat deployments/celo_sepolia_addresses.txt
else
    echo -e "${RED}⚠️  Address file not found. Check deployment logs above.${NC}"
fi

echo ""
echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}         DEPLOYMENT COMPLETE!${NC}"
echo -e "${BLUE}=============================================${NC}"
echo ""
echo -e "${GREEN}🎉 Trust Protocol successfully deployed to Celo Sepolia!${NC}"
echo -e "${GREEN}📊 Explorer: ${EXPLORER_URL}${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Verify contracts using the generated verification script"
echo -e "2. Update your frontend configuration with the new addresses"
echo -e "3. Test the deployment with some transactions"