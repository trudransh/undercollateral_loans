.PHONY: build deploy generate-abis get-address account chain compile flatten fork format lint test verify

DEPLOY_SCRIPT ?= script/Deploy.s.sol

# setup wallet for anvil
setup-anvil-wallet:
	shx rm ~/.foundry/keystores/scaffold-eth-default 2>/dev/null; 	shx rm -rf broadcast/Deploy.s.sol/31337
	cast wallet import --private-key 0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6 --unsafe-password 'localhost' scaffold-eth-default

# Start local chain
chain: setup-anvil-wallet
	anvil

# Start a fork
fork: setup-anvil-wallet
	anvil --fork-url ${FORK_URL} --chain-id 31337

# Deploy the contracts
deploy:
	@if [ ! -f "$(DEPLOY_SCRIPT)" ]; then 		echo "Error: Deploy script '$(DEPLOY_SCRIPT)' not found"; 		exit 1; 	fi
	@if [ "$(RPC_URL)" = "localhost" ]; then 		if [ "$(ETH_KEYSTORE_ACCOUNT)" = "scaffold-eth-default" ]; then 			forge script $(DEPLOY_SCRIPT) --rpc-url localhost --password localhost --broadcast --legacy --ffi; 		else 			forge script $(DEPLOY_SCRIPT) --rpc-url localhost --broadcast --legacy --ffi; 		fi 	else 		forge script $(DEPLOY_SCRIPT) --rpc-url $(RPC_URL) --broadcast --legacy --ffi; 	fi

# Deploy and generate ABIs
deploy-and-generate-abis: deploy generate-abis 

# Generate TypeScript ABIs
generate-abis:
	node scripts-js/generateTsAbis.js

# List account
account:
	@node scripts-js/checkAccountBalance.js

# Get address of a keystore
get-address:
	@cast wallet address --account $(ACCOUNT_NAME)

# Compile contracts
compile:
	forge compile

# Flatten contracts
flatten:
	forge flatten

# Format code
format:
	forge fmt && prettier --write ./scripts-js/**/*.js

# Lint code
lint:
	forge fmt --check && prettier --check ./scripts-js/**/*.js

# Run tests
test:
	forge test

# Verify contracts
verify:
	forge script script/VerifyAll.s.sol --ffi --rpc-url $(RPC_URL)

# --- Celo Sepolia helpers ---
.PHONY: deploy-celo-sepolia verify-celo-sepolia

deploy-celo-sepolia:
	@$(MAKE) deploy DEPLOY_SCRIPT=deployments/DeployCeloSepolia.s.sol

# Deploy + verify on Celo Sepolia in one go (Blockscout)
.PHONY: deploy-celo-sepolia-verify
deploy-celo-sepolia-verify:
	@if [ -z "$(PRIVATE_KEY)" ]; then echo "Missing PRIVATE_KEY=0x..."; exit 1; fi
	@if [ -z "$(RPC_URL)" ]; then echo "Missing RPC_URL (e.g. https://celo-sepolia.blockpi.network/v1/rpc/public)"; exit 1; fi
	forge script deployments/DeployCeloSepolia.s.sol \
		--rpc-url $(RPC_URL) \
		--private-key $(PRIVATE_KEY) \
		--broadcast \
		--verify \
		--verifier blockscout \
		--verifier-url https://celo-sepolia.blockscout.com/api \
		--chain-id 11142220 \
		--ffi || true

# Requires: CONTRACT_TRUST=0x.. CONTRACT_SCORE=0x.. CONTRACT_LENDING=0x..
verify-celo-sepolia:
	@if [ -z "$(CONTRACT_TRUST)" ]; then echo "Missing CONTRACT_TRUST=0x..."; exit 1; fi
	@if [ -z "$(CONTRACT_SCORE)" ]; then echo "Missing CONTRACT_SCORE=0x..."; exit 1; fi
	@if [ -z "$(CONTRACT_LENDING)" ]; then echo "Missing CONTRACT_LENDING=0x..."; exit 1; fi
	cast abi-encode "constructor(address)" $(CONTRACT_TRUST) > /tmp/ctor_trustscore.args
	cast abi-encode "constructor(address,address)" $(CONTRACT_TRUST) $(CONTRACT_SCORE) > /tmp/ctor_lending.args
	forge verify-contract $(CONTRACT_TRUST) contracts/TrustContract.sol:TrustContract --verifier blockscout --verifier-url https://celo-sepolia.blockscout.com/api --watch --chain-id 11142220 || true
	forge verify-contract $(CONTRACT_SCORE) contracts/TrustScore.sol:TrustScore --constructor-args $(shell cat /tmp/ctor_trustscore.args) --verifier blockscout --verifier-url https://celo-sepolia.blockscout.com/api --watch --chain-id 11142220 || true
	forge verify-contract $(CONTRACT_LENDING) contracts/LendingPool.sol:LendingPool --constructor-args $(shell cat /tmp/ctor_lending.args) --verifier blockscout --verifier-url https://celo-sepolia.blockscout.com/api --watch --chain-id 11142220 || true

