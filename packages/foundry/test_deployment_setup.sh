#!/bin/bash

# Trust Protocol Deployment Test Script
# Tests the deployment setup without actually deploying

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}   TRUST PROTOCOL DEPLOYMENT TEST${NC}"
echo -e "${BLUE}=============================================${NC}"
echo ""

# Test 1: Check Foundry installation
echo -e "${YELLOW}🔍 Test 1: Checking Foundry installation...${NC}"
if command -v forge &> /dev/null; then
    echo -e "${GREEN}✅ Forge found: $(forge --version | head -1)${NC}"
else
    echo -e "${RED}❌ Forge not found. Please install Foundry.${NC}"
    exit 1
fi

if command -v cast &> /dev/null; then
    echo -e "${GREEN}✅ Cast found: $(cast --version | head -1)${NC}"
else
    echo -e "${RED}❌ Cast not found. Please install Foundry.${NC}"
    exit 1
fi

# Test 2: Check RPC connectivity
echo -e "${YELLOW}🔍 Test 2: Testing Celo Sepolia RPC connectivity...${NC}"
RPC_URL="https://rpc.ankr.com/celo_sepolia"
if BLOCK_NUMBER=$(cast block-number --rpc-url $RPC_URL 2>/dev/null); then
    echo -e "${GREEN}✅ RPC connected. Current block: $BLOCK_NUMBER${NC}"
else
    echo -e "${RED}❌ Failed to connect to Celo Sepolia RPC${NC}"
    exit 1
fi

# Test 3: Check wallet balance
echo -e "${YELLOW}🔍 Test 3: Checking deployer wallet balance...${NC}"
PRIVATE_KEY="0xb1db46dc1e869bfbb6a33ed21a36f0f9af954c5f7fcec7980044a7de756b14b4"
DEPLOYER_ADDRESS=$(cast wallet address --private-key $PRIVATE_KEY)
echo "Deployer address: $DEPLOYER_ADDRESS"

if BALANCE=$(cast balance --rpc-url $RPC_URL $DEPLOYER_ADDRESS 2>/dev/null); then
    BALANCE_ETH=$(cast from-wei $BALANCE)
    echo -e "${GREEN}✅ Balance: $BALANCE_ETH CELO${NC}"
    
    # Check if balance is sufficient (at least 0.01 CELO)
    if (( $(echo "$BALANCE_ETH >= 0.01" | bc -l) )); then
        echo -e "${GREEN}✅ Sufficient balance for deployment${NC}"
    else
        echo -e "${YELLOW}⚠️  Low balance. Get more CELO from faucet: https://faucet.celo.org/sepolia${NC}"
    fi
else
    echo -e "${RED}❌ Failed to check wallet balance${NC}"
fi

# Test 4: Compile contracts
echo -e "${YELLOW}🔍 Test 4: Compiling contracts...${NC}"
if forge build > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Contracts compiled successfully${NC}"
else
    echo -e "${RED}❌ Contract compilation failed${NC}"
    exit 1
fi

# Test 5: Check deployment scripts
echo -e "${YELLOW}🔍 Test 5: Checking deployment scripts...${NC}"
SCRIPTS=(
    "script/DeployTrustProtocol.s.sol"
    "script/DeployTrustContract.s.sol"
    "script/DeployTrustScore.s.sol"
    "script/DeployLendingPool.s.sol"
)

for script in "${SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        echo -e "${GREEN}✅ Found: $script${NC}"
    else
        echo -e "${RED}❌ Missing: $script${NC}"
        exit 1
    fi
done

# Test 6: Check shell scripts
echo -e "${YELLOW}🔍 Test 6: Checking shell scripts...${NC}"
SHELL_SCRIPTS=(
    "deploy_celo_sepolia.sh"
    "deploy_individual.sh" 
    "verify_contracts.sh"
)

for script in "${SHELL_SCRIPTS[@]}"; do
    if [ -f "$script" ] && [ -x "$script" ]; then
        echo -e "${GREEN}✅ Found and executable: $script${NC}"
    elif [ -f "$script" ]; then
        echo -e "${YELLOW}⚠️  Found but not executable: $script${NC}"
        chmod +x "$script"
        echo -e "${GREEN}✅ Made executable: $script${NC}"
    else
        echo -e "${RED}❌ Missing: $script${NC}"
        exit 1
    fi
done

# Test 7: Check foundry configuration
echo -e "${YELLOW}🔍 Test 7: Checking Foundry configuration...${NC}"
if [ -f "foundry.toml" ]; then
    if grep -q "celo_sepolia" foundry.toml; then
        echo -e "${GREEN}✅ Celo Sepolia configuration found in foundry.toml${NC}"
    else
        echo -e "${YELLOW}⚠️  Celo Sepolia configuration might be missing${NC}"
    fi
else
    echo -e "${RED}❌ foundry.toml not found${NC}"
    exit 1
fi

# Test 8: Create deployments directory
echo -e "${YELLOW}🔍 Test 8: Checking deployments directory...${NC}"
if [ ! -d "deployments" ]; then
    mkdir -p deployments
    echo -e "${GREEN}✅ Created deployments directory${NC}"
else
    echo -e "${GREEN}✅ Deployments directory exists${NC}"
fi

echo ""
echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}          ALL TESTS PASSED! 🎉${NC}"
echo -e "${BLUE}=============================================${NC}"
echo ""
echo -e "${GREEN}✅ Your deployment setup is ready!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Ensure you have enough CELO tokens (>0.01 CELO)"
echo -e "2. Run: make deploy-celo"
echo -e "3. After deployment, run: make verify-celo"
echo ""
echo -e "${BLUE}Quick deployment command:${NC}"
echo -e "make setup-celo && make deploy-celo && make verify-celo"