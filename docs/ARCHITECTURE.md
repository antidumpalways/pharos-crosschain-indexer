# Architecture

## Overview

The Pharos Cross-Chain Indexer follows the standard 3-layer Pharos Skill Engine architecture.

```
┌──────────────────────────────────────────────────────────────┐
│                  AI Agent Runtime                            │
│  (Claude Code · Cursor · OpenCode · Hermes · Codex · MCP)   │
└──────────────────────────────┬───────────────────────────────┘
                               │ reads SKILL.md
                               ▼
┌──────────────────────────────────────────────────────────────┐
│           pharos-skill-engine (BASE, by Pharos)              │
│  primitives: query · send · deploy · verify · airdrop       │
└──────────────────────────────┬───────────────────────────────┘
                               │ extends
                               ▼
┌──────────────────────────────────────────────────────────────┐
│          pharos-crosschain-indexer (THIS SKILL)              │
│  multi-chain queries: balance · tx · portfolio · label      │
│  ref: SKILL.md + assets/{networks,tokens}.json +             │
│       references/*.md + scripts/               │
└──────────────────────────────┬───────────────────────────────┘
                               │ queries via curl / cast
                               ▼
┌──────────────────────────────────────────────────────────────┐
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐   │
│  │ PharosScan   │  │  Etherscan   │  │     RPC Nodes    │   │
│  │ (Atlantic +  │  │  (Ethereum + │  │  (PHRS, PROS,   │   │
│  │  Pacific)    │  │   L2s)       │  │   ETH, etc.)     │   │
│  └──────────────┘  └──────────────┘  └──────────────────┘   │
└──────────────────────────────────────────────────────────────┘
```

## Key design decisions

### 1. Why bash + curl + jq instead of a heavy SDK

- **Zero install.** Every system has bash, curl, and jq (or can install in 1 command).
- **Agent-friendly.** The agent can read `references/*.md` (one file per operation) and run the exact bash commands listed. No code generation.
- **Matches the base engine's philosophy.** The base skill engine is CLI-first. We extend it with the same paradigm.

### 2. Why one reference file per operation

The base engine has 4 reference files for 4 distinct domains (query, tx, contract, script-gen). We follow the same one-file-per-operation pattern with 9 reference files (`balance.md`, `tx.md`, `portfolio.md`, `label.md`, `verify.md`, `health.md`, `gas.md`, `top.md`, `add-chain.md`), each covering a single cross-chain data operation. The Python-powered capabilities (suggest, export, diff, history, alert, multi) are self-documenting scripts documented in the README.

### 3. Why no contracts

Cross-chain data querying is a pure read problem. Deploying a contract adds deploy overhead and gas cost with zero benefit. The data already exists on explorers and RPCs — we just aggregate it.

### 4. Why `cast` is optional

`cast balance` and `cast call` are faster for RPC queries (2-5x faster than raw curl). But forcing Foundry as a hard dependency limits the user base. The fallback keeps it functional without Foundry.

## Data flow per operation

### Multi-chain balance

```
Agent reads SKILL.md → Capability Index points to indexer.md#balance
Agent reads indexer.md → command template: scripts/indexer balance <addr>
indexer reads assets/networks.json → iterates over chains with rpcUrl
For each chain:
  → cast balance <addr> --rpc-url <rpc> --ether
  → OR curl eth_getBalance → python hex-to-decimal
  → Print: <chain> <balance> <symbol>
```

### Cross-chain tx lookup

```
Agent calls: scripts/indexer tx <hash>
indexer reads networks.json → iterates over chains with explorerApiUrl
For each chain:
  → curl explorerApi?module=transaction&action=gettxinfo&txhash=<hash>
  → If status=1 → Found! Print: chain, block, explorer link
  → If not found → continue to next chain
Stops on first match.
```

### Portfolio overview

```
Agent calls: scripts/indexer portfolio <addr>
indexer reads networks.json + tokens.json
For each chain:
  → Native balance (cast balance)
  → For each token in tokens.json[chain]:
      cast call <token> balanceOf(address)(uint256) <addr>
  → Convert raw to human (using decimals field)
  → Print table: chain, token, balance
```

### Address label

```
Agent calls: scripts/indexer label <addr>
For Pharos chains:
  → curl api.socialscan.io/social/label/<addr>
  → If label found → print
For Etherscan chains:
  → Check if address is a verified contract (has a name)
  → Print the verified contract name as the label
```

### Contract verification

```
Agent calls: scripts/indexer verify <addr>
For each chain with explorerApiUrl:
  → curl explorerApi?module=contract&action=getsourcecode&address=<addr>
  → If SourceCode is non-empty → verified!
  → Print: chain, explorer link
```

## Extensibility

To add a new chain (e.g. Optimism):

```json
// Add to assets/networks.json
{
  "name": "optimism",
  "rpcUrl": "https://mainnet.optimism.io",
  "chainId": 10,
  "explorerUrl": "https://optimistic.etherscan.io/",
  "explorerApiUrl": "https://api-optimistic.etherscan.io/api",
  "nativeToken": "ETH",
  "type": "etherscan"
}
```

```json
// Add tokens (optional) to assets/tokens.json
"optimism": [
  { "symbol": "USDC", "name": "USD Coin", "decimals": 6, "address": "0x..." }
]
```

No code changes needed. The indexer auto-discovers new chains.

## Security

- **Read-only.** No private keys, no wallet, no sign. Zero risk of fund loss.
- **API keys stored in env vars.** Set `EXPLORER_API_KEY` for Etherscan-compatible chains. Set `PHAROSSCAN_API_KEY` for PharosScan (though public endpoints work without it).
- **No state persistence.** The indexer doesn't store queries, addresses, or results. Ephemeral.
