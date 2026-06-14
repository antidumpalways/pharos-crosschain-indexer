# Gemini CLI — Usage Guide

> **Skill**: `pharos-crosschain-indexer` v0.1.0
> **Gemini CLI**: https://github.com/google-gemini/gemini-cli

## Quick Setup

```bash
# 1. Clone the skill into your project
git clone https://github.com/antidumpalways/pharos-crosschain-indexer
cd pharos-crosschain-indexer
bash install.sh

# 2. Start Gemini CLI in this directory
gemini
```

## How Gemini Uses This Skill

1. **Gemini reads `SKILL.md`** on startup — it sees the `activation.triggers`, `Capability Index`, and the mapping of natural-language intents to shell commands.

2. **When you ask a question**, Gemini matches it against the trigger phrases:

```
You: "Check my balance on all chains"
Gemini: [reads SKILL.md → sees trigger "balance on all chains"]
        [reads Capability Index → "Multi-chain balance" → references/balance.md]
        [executes: ./scripts/indexer balance <your-address>]
        [returns formatted table]
```

3. **No special config needed.** Gemini auto-discovers the skill from the current directory.

## Example Conversations in Gemini

### Example 1 — Multi-chain balance
```
> Check my balance on all chains for 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266

[Gemini reads SKILL.md → references/balance.md]
[Gemini runs: ./scripts/indexer balance 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266]

atlantic-testnet    14.9555 PHRS
pacific-mainnet      0.0    PROS
... (15 chains total)
```

### Example 2 — Gas price comparison
```
> Which chain has the cheapest gas right now?

[Gemini runs: ./scripts/indexer gas]
ethereum-sepolia    1.05 gwei
base-sepolia        0.01 gwei  ← cheapest
polygon-amoy       30.0  gwei  ← most expensive
```

### Example 3 — Find a transaction
```
> Where is tx 0x33a1600e7caccbba921526c3fd9dc23ea5e836f7c7f77f89c0a7ef3b55fe1906?

[Gemini runs: ./scripts/indexer tx 0x33a1...]
✓ Found on arbitrum-sepolia — block 12345678
```

### Example 4 — Check which chains are up
```
> Which chains are online right now?

[Gemini runs: ./scripts/indexer health]
14/15 LIVE (celo-alfajores DOWN)
```

### Example 5 — Add a new chain
```
> Add Polygon mainnet to the indexer

[Gemini reads references/add-chain.md]
[Gemini runs: jq '.networks += [{name:"polygon", chainId:137, ...}]' assets/networks.json]
Chain added and verified.
```

## All Commands Available

| Command | Alias | What it does |
|---|---|---|
| `balance <addr>` | `bal` | Multi-chain native balance |
| `tx <hash>` | `find` | Cross-chain tx lookup |
| `portfolio <addr>` | `port`, `pf` | All tokens across chains |
| `label <addr>` | `lab`, `who` | Address identity |
| `verify <addr>` | `ver` | Contract verification |
| `health` | `ping`, `status` | RPC health check (14/15 LIVE) |
| `gas` | `price` | Gas prices across 15 chains |
| `top <addr> <token>` | `rank` | Rank chains by token balance |

All commands support `--json` for machine-readable output.

## Pre-checks Gemini Must Run First

Before executing any command, Gemini should verify:

1. `which jq` — if not found, tell user to `apt-get install jq`
2. `ls assets/networks.json` — confirm the config file exists
3. `bash test.sh` — run the test suite (22 tests) to verify everything works
