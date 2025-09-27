#!/usr/bin/env node
/*
Parse Foundry broadcast for deployments/deployments on Celo Sepolia and update README with addresses & tx hashes.
Optionally runs verification via Makefile when --verify is passed.

Usage:
  node packages/foundry/scripts-js/updateReadmeFromBroadcast.cjs [--chain 11142220] [--verify]
*/

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

function run(cmd, cwd) {
  return execSync(cmd, { stdio: ['ignore', 'pipe', 'pipe'], cwd, encoding: 'utf8' }).trim();
}

function updateReadme({ trustAddress, trustTx, scoreAddress, scoreTx, lendingAddress, lendingTx, authTx, chainId }) {
  const repoRoot = path.resolve(__dirname, '..', '..');
  const readmePath = path.join(repoRoot, 'nextjs', 'README_LENDING.md');
  let content = fs.readFileSync(readmePath, 'utf8');

  const startMarker = '<!-- START: CELO_SEPOLIA_DEPLOYS -->';
  const endMarker = '<!-- END: CELO_SEPOLIA_DEPLOYS -->';
  const blockscoutTx = (tx) => `https://celo-sepolia.blockscout.com/tx/${tx}`;
  const blockscoutAddress = (addr) => `https://celo-sepolia.blockscout.com/address/${addr}`;

  const section = [
    startMarker,
    '',
    '## Deployments – Celo Sepolia (chainId 11142220)',
    '',
    `- TrustContract: [${trustAddress}](${blockscoutAddress(trustAddress)})`,
    `  - Deploy Tx: ${trustTx ? `[${trustTx}](${blockscoutTx(trustTx)})` : '<unknown>'}`,
    '',
    `- TrustScore: [${scoreAddress}](${blockscoutAddress(scoreAddress)})`,
    `  - Deploy Tx: ${scoreTx ? `[${scoreTx}](${blockscoutTx(scoreTx)})` : '<unknown>'}`,
    '',
    `- LendingPool: [${lendingAddress}](${blockscoutAddress(lendingAddress)})`,
    `  - Deploy Tx: ${lendingTx ? `[${lendingTx}](${blockscoutTx(lendingTx)})` : '<unknown>'}`,
    '',
    authTx ? `- Post‑Deploy: addAuthorizedLender Tx: [${authTx}](${blockscoutTx(authTx)})` : '',
    '',
    endMarker,
    ''
  ].join('\n');

  if (content.includes(startMarker) && content.includes(endMarker)) {
    const before = content.split(startMarker)[0];
    const after = content.split(endMarker)[1] || '';
    content = before + section + after;
  } else {
    content += '\n' + section + '\n';
  }

  fs.writeFileSync(readmePath, content);
  console.log(`Updated ${readmePath} with Celo Sepolia deployment info.`);
}

(function main() {
  const args = process.argv.slice(2);
  const chainId = Number(args.find(a => a.startsWith('--chain='))?.split('=')[1] || '11142220');
  const verify = args.includes('--verify');

  const foundryRoot = path.resolve(__dirname, '..');
  // Try both possible broadcast layouts
  let runLatest = path.join(foundryRoot, 'broadcast', 'deployments', 'DeployCeloSepolia.s.sol', String(chainId), 'run-latest.json');
  if (!fs.existsSync(runLatest)) {
    runLatest = path.join(foundryRoot, 'broadcast', 'DeployCeloSepolia.s.sol', String(chainId), 'run-latest.json');
  }
  if (!fs.existsSync(runLatest)) {
    console.error(`Broadcast file not found in expected locations. Did you run the deploy?`);
    console.error(`Checked: \n - ${path.join(foundryRoot, 'broadcast', 'deployments', 'DeployCeloSepolia.s.sol', String(chainId), 'run-latest.json')}\n - ${path.join(foundryRoot, 'broadcast', 'DeployCeloSepolia.s.sol', String(chainId), 'run-latest.json')}`);
    process.exit(1);
  }

  const data = JSON.parse(fs.readFileSync(runLatest, 'utf8'));
  const txs = data.transactions || [];
  const receipts = data.receipts || [];

  const byName = {};
  for (let i = 0; i < txs.length; i++) {
    const tx = txs[i];
    const rc = receipts[i] || {};
    if (tx.transactionType === 'CREATE' && tx.contractName) {
      byName[tx.contractName] = {
        address: rc.contractAddress || tx.contractAddress,
        tx: rc.transactionHash || tx.hash,
      };
    }
    if (tx.transactionType === 'CALL' && tx.function === 'addAuthorizedLender(address)') {
      byName.__auth = { tx: (receipts[i] || {}).transactionHash };
    }
  }

  if (!byName.TrustContract || !byName.TrustScore || !byName.LendingPool) {
    console.error('Could not find all contract deployments in broadcast. Found keys:', Object.keys(byName));
    process.exit(1);
  }

  updateReadme({
    trustAddress: byName.TrustContract.address,
    trustTx: byName.TrustContract.tx,
    scoreAddress: byName.TrustScore.address,
    scoreTx: byName.TrustScore.tx,
    lendingAddress: byName.LendingPool.address,
    lendingTx: byName.LendingPool.tx,
    authTx: byName.__auth?.tx,
    chainId,
  });

  if (verify) {
    const cmd = `make verify-celo-sepolia CONTRACT_TRUST=${byName.TrustContract.address} CONTRACT_SCORE=${byName.TrustScore.address} CONTRACT_LENDING=${byName.LendingPool.address}`;
    console.log('Running:', cmd);
    try {
      console.log(run(cmd, foundryRoot));
    } catch (e) {
      console.warn('Verification returned non-zero exit:', e.message);
    }
  }
})();
