#!/bin/bash

# Contract Verification Script for Celo Sepolia
# This script verifies all deployed contracts on Blockscout

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
CHAIN_NAME="celo_sepolia"
COMPILER_VERSION="0.8.20"

echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}      CONTRACT VERIFICATION SCRIPT${NC}"
echo -e "${BLUE}         Celo Sepolia Testnet${NC}"
echo -e "${BLUE}=============================================${NC}"
echo ""

# Check if addresses are provided
if [ -z "$TRUST_CONTRACT_ADDRESS" ] || [ -z "$TRUST_SCORE_ADDRESS" ] || [ -z "$LENDING_POOL_ADDRESS" ]; then
    echo -e "${YELLOW}📋 Please provide contract addresses as environment variables:${NC}"
    echo "export TRUST_CONTRACT_ADDRESS=0x..."
    echo "export TRUST_SCORE_ADDRESS=0x..."
    echo "export LENDING_POOL_ADDRESS=0x..."
    echo ""
    echo -e "${YELLOW}Or use the addresses from deployment:${NC}"
    if [ -f "deployments/celo_sepolia_addresses.txt" ]; then
        cat deployments/celo_sepolia_addresses.txt
    fi
    exit 1
fi

echo -e "${YELLOW}📋 Verifying contracts with addresses:${NC}"
echo "TrustContract: $TRUST_CONTRACT_ADDRESS"
echo "TrustScore: $TRUST_SCORE_ADDRESS"
echo "LendingPool: $LENDING_POOL_ADDRESS"
echo ""

# Function to verify a contract
verify_contract() {
    local contract_address=$1
    local contract_name=$2
    local contract_path=$3
    local constructor_args=$4
    
    echo -e "${YELLOW}🔍 Verifying ${contract_name}...${NC}"
    
    if [ -z "$constructor_args" ]; then
        # No constructor arguments
        forge verify-contract \
            --chain $CHAIN_NAME \
            --compiler-version $COMPILER_VERSION \
            $contract_address \
            $contract_path
    else
        # With constructor arguments
        forge verify-contract \
            --chain $CHAIN_NAME \
            --compiler-version $COMPILER_VERSION \
            --constructor-args $constructor_args \
            $contract_address \
            $contract_path
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ ${contract_name} verified successfully!${NC}"
    else
        echo -e "${RED}❌ ${contract_name} verification failed!${NC}"
        return 1
    fi
}

# Step 1: Verify TrustContract (no constructor args)
echo -e "${BLUE}Step 1: Verifying TrustContract${NC}"
verify_contract \
    $TRUST_CONTRACT_ADDRESS \
    "TrustContract" \
    "contracts/TrustContract.sol:TrustContract"

echo ""

# Step 2: Verify TrustScore (with TrustContract address)
echo -e "${BLUE}Step 2: Verifying TrustScore${NC}"
TRUST_SCORE_ARGS=$(cast abi-encode "constructor(address)" $TRUST_CONTRACT_ADDRESS)
verify_contract \
    $TRUST_SCORE_ADDRESS \
    "TrustScore" \
    "contracts/TrustScore.sol:TrustScore" \
    $TRUST_SCORE_ARGS

echo ""

# Step 3: Verify LendingPool (with both addresses)
echo -e "${BLUE}Step 3: Verifying LendingPool${NC}"
LENDING_POOL_ARGS=$(cast abi-encode "constructor(address,address)" $TRUST_CONTRACT_ADDRESS $TRUST_SCORE_ADDRESS)
verify_contract \
    $LENDING_POOL_ADDRESS \
    "LendingPool" \
    "contracts/LendingPool.sol:LendingPool" \
    $LENDING_POOL_ARGS

echo ""
echo -e "${GREEN}🎉 All contracts verified successfully!${NC}"
echo ""
echo -e "${BLUE}📊 View your verified contracts on Celo Sepolia Blockscout:${NC}"
echo "TrustContract: https://celo-sepolia.blockscout.com/address/$TRUST_CONTRACT_ADDRESS"
echo "TrustScore: https://celo-sepolia.blockscout.com/address/$TRUST_SCORE_ADDRESS"
echo "LendingPool: https://celo-sepolia.blockscout.com/address/$LENDING_POOL_ADDRESS"