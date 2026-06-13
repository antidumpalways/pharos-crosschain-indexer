---
name: pharos-crosschain-indexer
version: 0.1.0
description: >
  REQUIRED for any multi-chain data query on Pharos. This skill adds 5 cross-chain
  query capabilities on top of pharos-skill-engine: multi-chain balance lookup,
  cross-chain transaction tracking, portfolio overview, address labeling, and
  contract verification across 15 EVM chains (Pharos + 13 external testnets).
  Use whenever a task involves data from BOTH Atlantic and Pacific, or when
  checking an address/token/tx across multiple chains. Do NOT use for on-chain
  writes (use pharos-skill-engine's transaction.md), nor for single-chain
  queries (use pharos-skill-engine's query.md directly).
authors:
  - antidumpalways
license: MIT
tags:
  - pharos
  - cross-chain
  - data-indexer
  - multi-chain
  - balance
  - portfolio
  - pharosscan
  - claude-code
  - cursor
  - codex
  - evm
activation:
  triggers:
    - check my balance everywhere
    - balance on all chains
    - multi-chain balance
    - cross-chain balance
    - show my portfolio
    - all my tokens everywhere
    - what do I own on every chain
    - what tokens do I have
    - where is this transaction
    - find this tx
    - cross-chain tx
    - who is this address
    - label this address
    - is this contract verified
    - verify contract
    - pharos atlantic balance
    - pharos pacific balance
    - check on sepolia
    - check on base
    - check on arbitrum
    - check on optimism
    - check on polygon
    - check on bsc
    - check on avalanche
    - check on scroll
    - check on linea
    - check on blast
    - check on celo
    - check on gnosis
    - check on zksync
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

## Quick Install

```bash
# Claude Code (via gh CLI, v2.90.0+)
gh skill install antidumpalways/pharos-crosschain-indexer

# Manual (all agents — Claude Code, Cursor, OpenCode, Codex, Windsurf)
git clone https://github.com/antidumpalways/pharos-crosschain-indexer ~/.claude/skills/pharos-crosschain-indexer

# One-liner installer (all agents)
bash <(curl -fsSL https://raw.githubusercontent.com/antidumpalways/pharos-crosschain-indexer/main/install.sh)

# npm (all agents)
npm install -g pharos-crosschain-indexer

# npx (no install)
npx pharos-crosschain-indexer balance 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045
```

## Capability Index

| User Need | Capability | Detailed Instructions |
|---|---|---|
| "Check balance across all chains" / "balance everywhere" | `pharos-indexer balance` | → `references/balance.md` |
| "Find this transaction" / "where is this tx?" | `pharos-indexer tx` | → `references/tx.md` |
| "Show my full portfolio" / "all tokens everywhere" | `pharos-indexer portfolio` | → `references/portfolio.md` |
| "Who is this address?" / "label" / "identity" | `pharos-indexer label` | → `references/label.md` |
| "Is this contract verified?" / "verify" | `pharos-indexer verify` | → `references/verify.md` |

## General Error Handling

| Error | Cause | Fix |
|---|---|---|
| `jq: command not found` | `jq` not installed | `apt-get install jq` / `brew install jq` |
| Empty response from explorer API | API key missing or rate-limited | Get a free API key and set `EXPLORER_API_KEY` |
| `Cannot connect to RPC` | RPC URL changed or network down | Check Pharos Discord `#atlantic-status` |
| `assets/networks.json` not found | Not in the skill root directory | Run commands from `pharos-crosschain-indexer/` |

## Write Operation Pre-checks

**Not applicable.** All 5 operations are read-only. No wallet, no private key, no gas.

---

## Troubleshooting

| Error | Root Cause | Fix |
|---|---|---|
| `jq: command not found` | `jq` not installed | `apt-get install jq` (Linux) or `brew install jq` (macOS) |
| `curl: command not found` | `curl` not installed | `apt-get install curl` (Linux) — pre-installed on macOS |
| `cast: command not found` | Foundry not installed | `curl -L https://foundry.paradigm.xyz \| bash && foundryup` |
| `(unreachable)` next to a chain | RPC down or changed | Check Pharos Discord #atlantic-status; update `assets/networks.json` with current RPC URL |
| All chains return `0` | Address has no balance on any chain | Normal for unfunded addresses. Verify address with `cast wallet address` or explorer. |
| `No label found on any indexed chain` | Address has no public label | Normal for unlabeled addresses. Try a known labeled address like `0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045` (vitalik.eth) to verify. |
| `Contract not verified on any indexed chain` | Contract not verified anywhere | Verify it manually via explorer, or deploy + verify via `forge verify-contract` |
| `assets/networks.json` not found | Running from wrong directory | `cd pharos-crosschain-indexer` first |
| Explorer API returns empty | API key missing or rate-limited | Set `EXPLORER_API_KEY` env var for Etherscan-compatible chains. PharosScan works without a key. |
| Pacific mainnet returns `0.0 PROS` | Expected for most addresses | Most addresses don't hold PROS. Verify on https://www.pharosscan.xyz |
| External testnet (Sepolia/Amoy/Fuji/etc) returns `0` | Address has no assets there | Normal. Most addresses only have funds on 1-2 chains. |

---

## Live Documentation Query

Agents must query Pharos docs dynamically for any value not confirmed in this skill:

```text
GET https://docs.pharos.xyz/tooling-and-infrastructure/cross-chain.md?ask=<question>
GET https://docs.pharos.xyz/getting-started/network/atlantic-testnet.md?ask=<question>
GET https://docs.pharos.xyz/getting-started/network/pacific-mainnet.md?ask=<question>
```

---

## Registry Submission

This skill is submitted to:

- **DoraHacks** — Skill-to-Agent Dual Cascade Hackathon (Pharos Phase 1)
- **VoltAgent/awesome-agent-skills**
- **agentskills/agentskills**
- **anthropics/skills**

---

## Pharos Agent Center

This skill was built for the Pharos Agent Center Skill Builder Campaign. https://www.pharos.xyz/agent-center

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
