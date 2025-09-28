#!/bin/bash

# Individual Contract Deployment Scripts for Celo Sepolia

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
CHAIN_NAME="celo_sepolia"
RPC_URL="https://forno.celo.org/sepolia"
PRIVATE_KEY="0xb1db46dc1e869bfbb6a33ed21a36f0f9af954c5f7fcec7980044a7de756b14b4"

mkdir -p deployments

# Function to deploy TrustContract
deploy_trust_contract() {
    echo -e "${YELLOW}🚀 Deploying TrustContract...${NC}"
    
    forge script script/DeployTrustContract.s.sol:DeployTrustContract \
        --rpc-url $RPC_URL \
        --private-key $PRIVATE_KEY \
        --broadcast \
        -vvv
        
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ TrustContract deployed successfully!${NC}"
    else
        echo -e "${RED}❌ TrustContract deployment failed!${NC}"
        exit 1
    fi
}

# Function to deploy TrustScore
deploy_trust_score() {
    echo -e "${YELLOW}🚀 Deploying TrustScore...${NC}"
    
    # Read TrustContract address
    if [ -z "$TRUST_CONTRACT_ADDRESS" ]; then
        echo -e "${RED}❌ TRUST_CONTRACT_ADDRESS environment variable is required${NC}"
        exit 1
    fi
    
    forge script script/DeployTrustScore.s.sol:DeployTrustScore \
        --rpc-url $RPC_URL \
        --private-key $PRIVATE_KEY \
        --broadcast \
        -vvv
        
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ TrustScore deployed successfully!${NC}"
    else
        echo -e "${RED}❌ TrustScore deployment failed!${NC}"
        exit 1
    fi
}

# Function to deploy LendingPool
deploy_lending_pool() {
    echo -e "${YELLOW}🚀 Deploying LendingPool...${NC}"
    
    # Check required addresses
    if [ -z "$TRUST_CONTRACT_ADDRESS" ] || [ -z "$TRUST_SCORE_ADDRESS" ]; then
        echo -e "${RED}❌ TRUST_CONTRACT_ADDRESS and TRUST_SCORE_ADDRESS environment variables are required${NC}"
        exit 1
    fi
    
    forge script script/DeployLendingPool.s.sol:DeployLendingPool \
        --rpc-url $RPC_URL \
        --private-key $PRIVATE_KEY \
        --broadcast \
        -vvv
        
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ LendingPool deployed successfully!${NC}"
    else
        echo -e "${RED}❌ LendingPool deployment failed!${NC}"
        exit 1
    fi
}

# Main execution
case "$1" in
    "trust-contract")
        deploy_trust_contract
        ;;
    "trust-score")
        deploy_trust_score
        ;;
    "lending-pool")
        deploy_lending_pool
        ;;
    "all")
        echo -e "${BLUE}🚀 Deploying all contracts sequentially...${NC}"
        deploy_trust_contract
        
        # Extract TrustContract address (simplified - in production you'd parse properly)
        echo -e "${YELLOW}📋 Please set TRUST_CONTRACT_ADDRESS and run again for TrustScore${NC}"
        ;;
    *)
        echo -e "${YELLOW}Usage: $0 {trust-contract|trust-score|lending-pool|all}${NC}"
        echo ""
        echo -e "${BLUE}Examples:${NC}"
        echo "  $0 trust-contract                    # Deploy TrustContract only"
        echo "  $0 trust-score                       # Deploy TrustScore (requires TRUST_CONTRACT_ADDRESS)"
        echo "  $0 lending-pool                      # Deploy LendingPool (requires both addresses)"
        echo ""
        echo -e "${YELLOW}Environment variables needed:${NC}"
        echo "  TRUST_CONTRACT_ADDRESS    # For deploying TrustScore and LendingPool"
        echo "  TRUST_SCORE_ADDRESS       # For deploying LendingPool"
        exit 1
        ;;
esac

echo -e "${GREEN}🎉 Deployment completed!${NC}"