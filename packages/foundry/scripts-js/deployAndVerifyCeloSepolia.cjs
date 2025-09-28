#!/usr/bin/env node
/*
Deploys TrustContract, TrustScore, LendingPool to Celo Sepolia and verifies them on Blockscout.
Writes deployed addresses and tx hashes to packages/nextjs/README_LENDING.md under a new section.

Usage:
  PRIVATE_KEY=0x... node packages/foundry/scripts-js/deployAndVerifyCeloSepolia.js
Optional env:
  RPC_URL=https://rpc.sepolia.celo.org
*/

const { execSync } = require("child_process");
const fs = require("fs");
const path = require("path");

function run(cmd, opts = {}) {
  try {
    const out = execSync(cmd, { stdio: ["ignore", "pipe", "pipe"], encoding: "utf8", ...opts });
    return out.trim();
  } catch (e) {
    const msg = e.stdout ? e.stdout.toString() : e.message;
    const err = e.stderr ? e.stderr.toString() : "";
    throw new Error(`Command failed: ${cmd}\n${msg}\n${err}`);
  }
}

function runJSON(cmd) {
  const out = run(cmd);
  try {
    return JSON.parse(out);
  } catch (e) {
    // forge sometimes prints extra lines; try to extract JSON
    const start = out.indexOf("{\n");
    const end = out.lastIndexOf("}\n");
    if (start >= 0 && end >= start) {
      const jsonStr = out.substring(start, end + 2);
      return JSON.parse(jsonStr);
    }
    throw new Error(`Failed to parse JSON from output. Raw output:\n${out}`);
  }
}

function nowISO() {
  return new Date().toISOString();
}

(async () => {
  const PRIVATE_KEY = process.env.PRIVATE_KEY || process.argv.find(a => a.startsWith("--key="))?.split("=")[1];
  const RPC_URL = process.env.RPC_URL || process.argv.find(a => a.startsWith("--rpc="))?.split("=")[1] || "https://rpc.ankr.com/celo_sepolia";
  const CHAIN_ID = 11142220; // Celo Sepolia
  const BLOCKSCOUT_API = process.env.BLOCKSCOUT_API || "https://celo-sepolia.blockscout.com/api";

  if (!PRIVATE_KEY) {
    console.error("Missing PRIVATE_KEY env or --key flag.");
    process.exit(1);
  }

  console.log(`Using RPC: ${RPC_URL}`);

  // Ensure Foundry tools available
  try {
    const forgeV = run("forge --version");
    console.log(forgeV.split("\n")[0]);
  } catch {
    console.error("forge not found. Install Foundry: https://book.getfoundry.sh/getting-started/installation");
    process.exit(1);
  }

  const root = path.resolve(__dirname, "..", "..");
  const foundryDir = path.join(root, "foundry");
  const nextReadme = path.join(root, "nextjs", "README_LENDING.md");

  // Build
  console.log("Building contracts...");
  run(`forge build`, { cwd: foundryDir });

  const results = { network: "celo-sepolia", chainId: CHAIN_ID, timestamp: nowISO(), contracts: {} };

  // Deploy TrustContract
  console.log("Deploying TrustContract...");
  const trustCreate = runJSON(
    `forge create --json contracts/TrustContract.sol:TrustContract --rpc-url ${RPC_URL} --private-key ${PRIVATE_KEY}`,
  );
  const trustAddress = trustCreate.deployedTo || trustCreate.address || trustCreate.contractAddress;
  const trustTx = trustCreate.transactionHash || trustCreate.receipt?.transactionHash;
  if (!trustAddress) throw new Error("Failed to read TrustContract address from forge output");
  results.contracts.TrustContract = { address: trustAddress, tx: trustTx };

  // Deploy TrustScore(trustAddress)
  console.log("Deploying TrustScore...");
  const trustScoreCreate = runJSON(
    `forge create --json contracts/TrustScore.sol:TrustScore --rpc-url ${RPC_URL} --private-key ${PRIVATE_KEY} --constructor-args ${trustAddress}`,
  );
  const trustScoreAddress = trustScoreCreate.deployedTo || trustScoreCreate.address || trustScoreCreate.contractAddress;
  const trustScoreTx = trustScoreCreate.transactionHash || trustScoreCreate.receipt?.transactionHash;
  if (!trustScoreAddress) throw new Error("Failed to read TrustScore address from forge output");
  results.contracts.TrustScore = { address: trustScoreAddress, tx: trustScoreTx };

  // Deploy LendingPool(trustAddress, trustScoreAddress)
  console.log("Deploying LendingPool...");
  const lendingCreate = runJSON(
    `forge create --json contracts/LendingPool.sol:LendingPool --rpc-url ${RPC_URL} --private-key ${PRIVATE_KEY} --constructor-args ${trustAddress} ${trustScoreAddress}`,
  );
  const lendingAddress = lendingCreate.deployedTo || lendingCreate.address || lendingCreate.contractAddress;
  const lendingTx = lendingCreate.transactionHash || lendingCreate.receipt?.transactionHash;
  if (!lendingAddress) throw new Error("Failed to read LendingPool address from forge output");
  results.contracts.LendingPool = { address: lendingAddress, tx: lendingTx };

  // Authorize LendingPool in TrustContract
  console.log("Authorizing LendingPool in TrustContract...");
  const authOut = run(
    `cast send ${trustAddress} "addAuthorizedLender(address)" ${lendingAddress} --rpc-url ${RPC_URL} --private-key ${PRIVATE_KEY}`,
  );
  const authTxMatch = authOut.match(/transaction hash: (0x[0-9a-fA-F]+)/);
  results.contracts.TrustContractAuthorizeLenderTx = authTxMatch ? authTxMatch[1] : null;

  // Verify on Blockscout (no API key required)
  function verifyCmd(address, fullyQualified) {
    return `forge verify-contract ${address} ${fullyQualified} --verifier blockscout --verifier-url ${BLOCKSCOUT_API} --watch --chain-id ${CHAIN_ID}`;
  }

  console.log("Verifying TrustContract...");
  try { run(verifyCmd(trustAddress, "contracts/TrustContract.sol:TrustContract"), { cwd: foundryDir }); } catch (e) { console.warn("Verify TrustContract failed:", e.message); }

  console.log("Verifying TrustScore...");
  try {
    const ctorArgs = run(`cast abi-encode "constructor(address)" ${trustAddress}`);
    run(`${verifyCmd(trustScoreAddress, "contracts/TrustScore.sol:TrustScore")} --constructor-args ${ctorArgs}`, { cwd: foundryDir });
  } catch (e) { console.warn("Verify TrustScore failed:", e.message); }

  console.log("Verifying LendingPool...");
  try {
    const ctorArgs = run(`cast abi-encode "constructor(address,address)" ${trustAddress} ${trustScoreAddress}`);
    run(`${verifyCmd(lendingAddress, "contracts/LendingPool.sol:LendingPool")} --constructor-args ${ctorArgs}`, { cwd: foundryDir });
  } catch (e) { console.warn("Verify LendingPool failed:", e.message); }

  // Write to README
  const lines = [];
  lines.push("\n## Deployments – Celo Sepolia (chainId 11142220)");
  lines.push("");
  lines.push(`- Timestamp: ${results.timestamp}`);
  lines.push(`- Network RPC: ${RPC_URL}`);
  lines.push("");
  lines.push("- TrustContract:");
  lines.push(`  - Address: ${trustAddress}`);
  lines.push(`  - Deploy Tx: ${trustTx ? `[${trustTx}](${`https://celo-sepolia.blockscout.com/tx/${trustTx}`})` : "<unknown>"}`);
  lines.push("");
  lines.push("- TrustScore:");
  lines.push(`  - Address: ${trustScoreAddress}`);
  lines.push(`  - Deploy Tx: ${trustScoreTx ? `[${trustScoreTx}](${`https://celo-sepolia.blockscout.com/tx/${trustScoreTx}`})` : "<unknown>"}`);
  lines.push("");
  lines.push("- LendingPool:");
  lines.push(`  - Address: ${lendingAddress}`);
  lines.push(`  - Deploy Tx: ${lendingTx ? `[${lendingTx}](${`https://celo-sepolia.blockscout.com/tx/${lendingTx}`})` : "<unknown>"}`);
  lines.push("");
  if (results.contracts.TrustContractAuthorizeLenderTx) {
    const tx = results.contracts.TrustContractAuthorizeLenderTx;
    lines.push("- Post‑Deploy Admin:");
    lines.push(`  - addAuthorizedLender Tx: [${tx}](${`https://celo-sepolia.blockscout.com/tx/${tx}`})`);
  }

  try {
    const original = fs.readFileSync(nextReadme, "utf8");
    const updated = original + "\n" + lines.join("\n") + "\n";
    fs.writeFileSync(nextReadme, updated);
    console.log(`Updated README with deployment info → ${nextReadme}`);
  } catch (e) {
    console.warn("Failed to update README:", e.message);
  }

  // Print summary
  console.log("\nDeployment Summary (Celo Sepolia):");
  console.log(JSON.stringify(results, null, 2));
})();
