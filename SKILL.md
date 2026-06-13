---
name: pharos-crosschain-indexer
description: >
  REQUIRED for any multi-chain data query on Pharos. This skill adds 5 cross-chain
  query capabilities on top of pharos-skill-engine: multi-chain balance lookup,
  cross-chain transaction tracking, portfolio overview, address labeling, and
  contract verification across 15 EVM chains (Pharos + 13 external testnets).
  Use whenever a task involves data from BOTH Atlantic and Pacific, or when
  checking an address/token/tx across multiple chains. Do NOT use for on-chain
  writes (use pharos-skill-engine's transaction.md), nor for single-chain
  queries (use pharos-skill-engine's query.md directly).
version: 0.1.0
requires:
  skills:
    - pharos-skill-engine
  anyBins:
    - curl
    - jq
---

# Pharos Cross-Chain Indexer

> **Extends [`pharos-skill-engine`](https://github.com/PharosNetwork/pharos-skill-engine).** This skill inherits all network configuration from the base engine. Read that SKILL.md first.

**One command. Every chain. Real data.** No contract deploy. No gas. Pure data queries across Atlantic testnet, Pacific mainnet, and any Etherscan-compatible chain.

## Prerequisites

1. **Base engine installed** — `pharos-skill-engine` is the parent skill
2. **`curl` + `jq`** — both pre-installed on most systems (`which jq` to check; if missing: `apt-get install jq` / `brew install jq`)
3. **Optional API keys** — free-tier access works without a key for public endpoints; for higher rate limits, get keys at:
   - PharosScan: https://api.socialscan.io
   - Etherscan-compatible chains: free tier API key per chain

## Network Configuration

**Inherited from base engine's `assets/networks.json`.** The indexer extends this with additional Etherscan-compatible chains for cross-chain queries.

For convenience, the networks used by this skill are:

| Network | Chain ID | RPC | Explorer API |
|---|---|---|---|
| Atlantic (testnet, default) | `688689` | `https://atlantic.dplabs-internal.com` | `https://api.socialscan.io/pharos-atlantic-testnet` |
| Pacific (mainnet) | `1672` | `https://rpc.pharos.xyz` | `https://api.socialscan.io/pharos-mainnet` |
| Ethereum Sepolia | `11155111` | — | `https://api-sepolia.etherscan.io/api` |
| Base Sepolia | `84532` | — | `https://api-sepolia.basescan.org/api` |
| Arbitrum Sepolia | `421614` | — | `https://api-sepolia.arbiscan.io/api` |

Read `assets/networks.json` for the complete config. The indexer queries all chains in the config that have an `explorerApiUrl` — add or remove chains by editing the JSON.

## Capability Index

| User Need | Capability | Detailed Instructions |
|---|---|---|
| "Check balance across all chains" / "what do I have on every chain?" | `pharos-indexer balance` | → `references/indexer.md#multi-chain-balance` |
| "Find this transaction" / "where is this tx?" / "tx lookup" | `pharos-indexer tx` | → `references/indexer.md#cross-chain-tx-lookup` |
| "Show my full portfolio" / "all tokens everywhere" | `pharos-indexer portfolio` | → `references/indexer.md#portfolio-overview` |
| "Who is this address?" / "label" / "identity" | `pharos-indexer label` | → `references/indexer.md#address-label` |
| "Is this contract verified?" / "verify" | `pharos-indexer verify` | → `references/indexer.md#contract-verification` |

## General Error Handling

| Error | Cause | Fix |
|---|---|---|
| `jq: command not found` | `jq` not installed | `apt-get install jq` / `brew install jq` |
| Empty response from explorer API | API key missing or rate-limited | Get a free API key and set `EXPLORER_API_KEY` |
| `Cannot connect to RPC` | RPC URL changed or network down | Check Pharos Discord `#atlantic-status` |
| `assets/networks.json` not found | Not in the skill root directory | Run commands from `pharos-crosschain-indexer/` |

## Write Operation Pre-checks

**Not applicable.** All 5 operations are read-only. No wallet, no private key, no gas.

## Examples

```bash
# Check ETH balance across all chains
./scripts/indexer balance 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045

# Find a transaction (auto-detects the chain)
./scripts/indexer tx 0x33a1600e7caccbba921526c3fd9dc23ea5e836f7c7f77f89c0a7ef3b55fe1906

# Full portfolio (all tokens, all chains)
./scripts/indexer portfolio 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266

# Who is this address?
./scripts/indexer label 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045

# Is this contract verified?
./scripts/indexer verify 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
```

See `examples/` for full demo scripts.
