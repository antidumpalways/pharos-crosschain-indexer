---
name: pharos-crosschain-indexer
version: 0.1.0
description: >
  Adds 14 multi-chain READ-ONLY data operations on top of pharos-skill-engine:
  multi-chain balance, tx lookup, portfolio overview, address labeling, contract
  verification, RPC health check, gas comparison, chain ranking, portfolio
  suggestions, CSV/HTML export, balance snapshot/diff, multi-address portfolio,
  history tracking, and balance alerts. Queries 112 EVM chains + Solana + Near
  via public RPCs and Etherscan-compatible explorer APIs. Use this skill
  whenever a task involves DATA from multiple chains. Do NOT use for on-chain
  writes — defer those to pharos-skill-engine (cast send / forge script).
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
  - opencode
  - codex
  - windsurf
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
    - add a chain
    - configure new chain
    - add optimism to indexer
    - add polygon to indexer
    - add bsc to indexer
    - add avalanche to indexer
    - add fantom to indexer
    - check rpc health
    - which chains are online
    - network status
    - ping all chains
    - compare gas prices
    - gas across chains
    - cheapest chain for gas
    - gas price comparison
    - where is my USDC
    - rank chains by token
    - which chain has most tokens
    - top USDC chains
    - analyze my portfolio
    - suggest actions
    - where should I bridge
    - export portfolio
    - export to CSV
    - generate HTML report
    - snapshot my balance
    - record current state
    - compare balance changes
    - how much did my balance change
    - track my balance over time
    - show balance history
    - alert me if balance changes
    - monitor my wallet
    - scan all chains
    - full portfolio
    - all tokens everywhere
requires:
  skills:
    - pharos-skill-engine
  anyBins:
    - curl
    - jq
    - python3
  optionalBins:
    - cast
---

# Pharos Cross-Chain Indexer

> **Extends [`pharos-skill-engine`](https://github.com/PharosNetwork/pharos-skill-engine) as a read-only child skill.** The parent covers on-chain WRITE operations (`cast send` / `forge script`). This skill covers multi-chain READ operations (balance, tx, portfolio, label, verify, health, gas). Together they form a complete data → action pipeline for Pharos agents.

**One command. Every chain. Real data.** No contract deploy. No gas. Pure data queries across Atlantic testnet, Pacific mainnet, and 110+ Etherscan-compatible chains.

## Relationship to pharos-skill-engine (parent)

| Layer | pharos-skill-engine (parent) | pharos-crosschain-indexer (this skill) |
|---|---|---|
| Operation type | **WRITE** — send tx, deploy, verify, airdrop | **READ** — query balances, txs, labels, gas, health |
| Required bins | `cast`, `forge` (Foundry) | `curl`, `jq`, `python3` (no Foundry needed) |
| Asset folder | `assets/networks.json` (2 chains) | `assets/networks.json` (112 chains) |
| Reference files | `query.md`, `transaction.md`, `contract.md`, `script-gen.md` | `balance.md`, `tx.md`, `portfolio.md`, `label.md`, `verify.md`, `health.md`, `gas.md`, `top.md`, `add-chain.md` |

The indexer is a **sibling-style extension** — it does not import or call into the parent at runtime. It can be installed independently and used as a read-only complement. If both are loaded, the parent handles writes, this skill handles reads.

## Prerequisites

1. **`curl` + `jq` + `python3`** — required. The agent must run `which curl` / `which jq` / `which python3` once and install any missing tool before running commands:
   - Linux: `apt-get install -y curl jq python3`
   - macOS: `brew install curl jq python3`
   - Windows: `winget install jqlang.jq` + `winget install Python.Python.3`
2. **Optional `cast` (Foundry)** — if present, the indexer uses it for faster RPC calls; otherwise it falls back to `curl` + `python3` (slower but works).
3. **Optional API keys** — free tier works without a key for public endpoints; for higher rate limits:
   - PharosScan: https://api.socialscan.io
   - Etherscan-compatible chains: free tier API key per chain
4. **Base engine (recommended)** — `pharos-skill-engine` is declared as a required skill in YAML so agents that support skill composition load both. The indexer still works without it (it ships its own `assets/networks.json`).

## Network Configuration

Network information is stored in `assets/networks.json`. The indexer ships a self-contained list of 112 chains (110 EVM + Solana + Near) because the parent's 2-chain config is too narrow for cross-chain queries.

- **Default Network**: Atlantic testnet (`atlantic-testnet`). Used when the user does not specify a chain.
- **Switching Networks**: Pass a chain name as the second argument (`bash scripts/indexer balance <addr> <chain>`), or use `--all` to scan every chain.
- **Default Scope**: top 15 chains (fast). Add `--all` to scan all 112.

```bash
# Example: reading network configuration
RPC_URL=$(jq -r '.networks[] | select(.name=="atlantic-testnet") | .rpcUrl' assets/networks.json)
```

The 4 most-used chains:

| Network | Chain ID | RPC | Explorer API |
|---|---|---|---|
| Atlantic (testnet, default) | `688689` | `https://atlantic.dplabs-internal.com` | `https://api.socialscan.io/pharos-atlantic-testnet` |
| Pacific (mainnet) | `1672` | `https://rpc.pharos.xyz` | `https://api.socialscan.io/pharos-mainnet` |
| Ethereum Sepolia | `11155111` | `https://ethereum-sepolia-rpc.publicnode.com` | `https://api-sepolia.etherscan.io/api` |
| Base Sepolia | `84532` | `https://sepolia.base.org` | `https://api-sepolia.basescan.org/api` |

Read `assets/networks.json` for the complete config. The indexer queries all chains that have an `rpcUrl`; add or remove chains by editing the JSON (see `references/add-chain.md`).

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

Load the corresponding reference file based on user needs to get full command templates, parameter tables, output parsing rules, and error handling. The "User Need" column captures natural-language phrasings the agent should match against, including synonyms.

### Group A — Read-Only Data Queries (bash indexer)

| User Need (natural language) | Capability | Detailed Instructions |
|------------------------------|------------|----------------------|
| Check my balance / native balance / how much X do I have / balance on chain X | `bash scripts/indexer balance <addr> [chain]` | → `references/balance.md` |
| Show my portfolio / all my tokens / what do I own / cross-chain holdings | `bash scripts/indexer portfolio <addr> [chain]` | → `references/portfolio.md` |
| Where is this transaction / find this tx / which chain has this hash / tx lookup | `bash scripts/indexer tx <tx-hash>` | → `references/tx.md` |
| Who is this address / label this address / what contract is this / identify an EOA | `bash scripts/indexer label <addr>` | → `references/label.md` |
| Is this contract verified / verify contract / source code available | `bash scripts/indexer verify <addr>` | → `references/verify.md` |
| Where is my USDC / which chain has most WETH / rank chains by token / top tokens | `bash scripts/indexer top <addr> <TOKEN>` | → `references/top.md` |
| Compare gas prices / which chain is cheapest / gas across chains / gwei comparison | `bash scripts/indexer gas [chain]` | → `references/gas.md` |
| Which chains are online / RPC health check / network status / ping all chains | `bash scripts/indexer health [chain]` | → `references/health.md` |
| Analyze my portfolio / suggest actions / where should I bridge / recommendations | `bash scripts/indexer suggest <addr>` | → `references/health.md#portfolio-suggestions` |
| Add a chain / configure new chain / add <name> to indexer | `jq` append to `assets/networks.json` | → `references/add-chain.md` |

### Group B — Python Tooling (read + persist + visualize)

| User Need | Capability | Detailed Instructions |
|-----------|------------|----------------------|
| Export portfolio to CSV / export to HTML / download report for compliance | `python3 scripts/export.py <addr> [csv\|html]` | → `references/portfolio.md#export` |
| Snapshot my balance / record current state / save balances for later | `python3 scripts/diff.py save <addr>` | → `references/portfolio.md#snapshot` |
| Compare balance changes / what changed since my last snapshot / balance diff | `python3 scripts/diff.py diff <addr>` | → `references/portfolio.md#diff` |
| Track my balance over time / show balance history / time-series | `python3 scripts/history.py record\|show\|count <addr>` | → `references/portfolio.md#history` |
| Alert me if balance changes / monitor my wallet / watch for movement | `python3 scripts/alert.py <addr> [chain] [threshold] [interval]` | → `references/portfolio.md#alert` |
| Aggregate multiple addresses / combined portfolio view | `python3 scripts/multi.py <addr1> <addr2> ...` | → `references/portfolio.md#multi-address` |

### Group C — Composable Actions (read → suggest → write)

The indexer is read-only by design. When the user wants to ACT on a discovered state (bridge, deploy, send), the agent must defer to **`pharos-skill-engine`** for write operations:

| Discovered via this skill | Then defer to parent skill |
|---------------------------|----------------------------|
| `[BRIDGE] USDC on X → Y` from `suggest` | `pharos-skill-engine` → `references/transaction.md` |
| `[DEPLOY] lowest gas chain Z` from `suggest` | `pharos-skill-engine` → `references/contract.md` |
| `[USDC] Available on N chains` from `suggest` | `pharos-skill-engine` → `references/transaction.md` |

## Default Scope: Top 15 Chains (IMPORTANT for agents)

**By default every multi-chain command scans only the top 15 (highest-priority)
chains** — Pharos Atlantic/Pacific first, then Ethereum/Base/Arbitrum/Optimism/
Polygon/BSC/Avalanche/Solana/Near/etc. This returns in seconds.

Only add `--all` when the user **explicitly** asks for "all chains", "every
chain", "all 112", or says the asset is on an unusual chain.

| User says | Use |
|---|---|
| "check my balance" / "what do I have" (default) | `bash scripts/indexer balance <addr>` (top 15) |
| "check my balance on **all** chains" / "every chain" | `bash scripts/indexer balance <addr> --all` |
| "balance on <specific chain>" | `bash scripts/indexer balance <addr> <chain>` (single chain) |

Applies to: `balance`, `portfolio`, `health`, `gas`, `top`, `suggest`. All accept `--all`.

## How to pick the command (agent cheat-sheet)

Pick **one** command based on the user's intent — do not try multiple:

| Intent (what the user wants) | Run this, nothing else |
|---|---|
| Native balance across chains | `bash scripts/indexer balance <addr>` |
| All tokens (native + ERC-20) across chains | `bash scripts/indexer portfolio <addr>` |
| Find which chain a tx is on | `bash scripts/indexer tx <hash>` |
| Who/what is an address | `bash scripts/indexer label <addr>` |
| Is a contract verified | `bash scripts/indexer verify <addr>` |
| Which chains are online | `bash scripts/indexer health` |
| Compare gas prices | `bash scripts/indexer gas` |
| Where is most of a token | `bash scripts/indexer top <addr> <TOKEN>` |
| Suggest bridge/deploy actions | `bash scripts/indexer suggest <addr>` |

If unsure, ask the user which intent they mean. **Never** run several commands
speculatively.

## Security Reminders

The indexer is **read-only by design**, but the agent should still observe these rules to protect the user:

- **Never echo private keys.** If the user pastes a private key, warn them: "Your key is now in the chat transcript. Rotate this key immediately." Do not echo the key. Do not store it. The indexer does not need it.
- **Never invent an address.** If the user says "my balance" / "my portfolio" without providing an address, ASK before running any query. The session may remember a previously-given address — use that. Otherwise request a real `0x...` value.
- **No file writes outside the skill folder.** The only persistent file writes are the Python tooling outputs (`data/portfolio.csv`, `data/snapshot.json`, etc.) and `assets/networks.json` when the user explicitly asks to add a chain. Do not modify parent skill files.
- **Rate-limit awareness.** Public RPCs and Etherscan-compatible APIs enforce rate limits (typically 5-10 req/sec). The indexer uses sequential requests with 100ms delays; if a 429 is returned, the chain is skipped silently.
- **Testnet by default.** All queries default to `atlantic-testnet` unless the user specifies otherwise. If the user says "mainnet", warn: "This queries mainnet. Data is live and queries may be rate-limited." Do not block — just confirm.
- **API key handling.** `EXPLORER_API_KEY` is optional. If set via environment variable, never echo or log it. PharosScan works without a key.
- **Privacy of results.** Multi-chain balance output can reveal all of a user's holdings. Confirm with the user before saving snapshots, exporting reports, or piping to other skills.

## Write Operation Pre-checks

**Not applicable.** All 14 capabilities of this skill are read-only:

| Operation | Touches state? | Needs `$PRIVATE_KEY`? | Touches `--rpc-url` for writes? |
|-----------|---------------|----------------------|--------------------------------|
| `balance`, `portfolio`, `top` | No | No | No (read-only `eth_getBalance`, `eth_call`) |
| `tx`, `label`, `verify` | No | No | No (read-only explorer API calls) |
| `health`, `gas` | No | No | No (read-only `eth_blockNumber`, `eth_gasPrice`) |
| `suggest` | No | No | No (composes read results only) |
| `export`, `diff`, `history`, `alert`, `multi` | No (writes to local `data/` files only) | No | No |

The four pre-checks from the parent skill (`pharos-skill-engine`) — Private Key, Address Derivation, Network Confirmation, Balance Check — apply **only when the user wants to write** (send tx, deploy contract, run airdrop). In that case the agent must:

1. Switch skills: load `pharos-skill-engine` SKILL.md and follow its Write Operation Pre-checks.
2. Use `cast send` / `forge script` with `--private-key $PRIVATE_KEY` (env var is NOT auto-read).
3. Confirm the target network (testnet vs mainnet) with the user.
4. Never call `scripts/indexer` with a `--write` or `--send` flag — that flag does not exist by design.

## General Error Handling

Before executing commands, the Agent should perform pre-checks; when commands fail, provide user-friendly error messages based on stderr output.

| Error Scenario | CLI Error Signature | Handling |
|---------------|--------------------|----------|
| Missing required bin | `jq: command not found` | Install: `apt-get install jq` / `brew install jq` / `winget install jqlang.jq` |
| Missing required bin | `curl: command not found` | Install: `apt-get install curl` (pre-installed on macOS) |
| Missing required bin | `python3: command not found` | Install: `apt-get install python3` / `brew install python3` |
| Optional bin missing | `cast: command not found` | Optional — fall back to curl. For speed: `curl -L https://foundry.paradigm.xyz \| bash && foundryup` |
| Invalid address format | `invalid address` (in `cast` output) | Confirm address is `0x` + 40 hex characters (42 chars total) |
| Connection refused | `curl: (7) Failed to connect` | Check Pharos Discord `#atlantic-status`; try the next chain in `networks.json` |
| RPC timeout | `(unreachable)` next to a chain | 10-15s timeout — chain is skipped; result marked DOWN |
| API rate limit | HTTP 429 from explorer | Set `EXPLORER_API_KEY` env var; chain is skipped silently |
| Empty explorer response | `{"status":"0","message":"NOTOK"}` | API key missing or invalid; pass `&apikey=$EXPLORER_API_KEY` |
| Asset not in scope | `Contract not verified on any indexed chain` | Normal — verify manually, or check parent skill's `references/contract.md` |
| No balance anywhere | `No balance found on any chain` | Normal for unfunded addresses; verify with `cast wallet address` |
| Address label missing | `No label found on any indexed chain` | Normal for unlabeled addresses; try `0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045` (vitalik.eth) as a sanity test |
| `assets/networks.json` not found | `jq: error: ... is not a valid JSON` | Run from inside the `pharos-crosschain-indexer` directory |
| Tx not on any chain | `Transaction not found on any indexed chain` | Hash may be on a chain not in `networks.json` (add via `references/add-chain.md`) |
| User asks for a chain not in scope | `Chain 'X' not found` | Add it via `bash scripts/indexer add-chain` or by editing `assets/networks.json` |
| User asks for write op | (none — this skill is read-only) | Defer to `pharos-skill-engine` and follow its Write Operation Pre-checks |

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
GET https://docs.pharos.xyz/tooling-and-infrastructure/pharos-skill-engine-guide.md?ask=<question>
```

---

## Publishing Checklist (per official `pharos-skill-engine-guide` Part 4)

| Check | What to Verify | Status |
|-------|----------------|--------|
| `SKILL.md` YAML frontmatter | `name`, `version`, `description`, `requires` per official schema | Yes |
| Capability Index | Every operation mapped to a `references/<name>.md` with natural-language phrasings + synonyms | Yes (15 entries) |
| Reference file template | Overview → Command Template → Parameters → Output Parsing → Error Handling → Agent Guidelines | Yes (9 reference files) |
| Network Configuration | Stored in `assets/networks.json` with `rpcUrl`, `chainId`, `explorerUrl`, `explorerApiUrl`, `nativeToken`, `type` | Yes |
| General Error Handling | Table of error signatures → cause → fix | Yes |
| Security Reminders | Section present with key-protection, address-handling, rate-limit rules | Yes |
| Write Operation Pre-checks | Marked Not Applicable for read-only skills (with deferral pointer to parent) | Yes |
| Live data verified | Atlantic testnet returns `14.95 PHRS` from `atlantic.dplabs-internal.com` | Yes |
| Live data verified | Solana mainnet returns `1.85 SOL` from `api.mainnet-beta.solana.com` | Yes |
| Live data verified | Near mainnet returns `2911 NEAR` from `api.nearblocks.io` | Yes |
| Live data verified | Vitalik address returns `58.24 ETH` on `api-sepolia.etherscan.io` | Yes |
| CI / automated test | `bash test.sh` runs on every push via `.github/workflows/test.yml` | Yes |
| Composable | Read results from this skill can feed `pharos-skill-engine` write operations | Yes |

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
bash scripts/indexer balance 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045

# Find a transaction (auto-detects the chain)
bash scripts/indexer tx 0x33a1600e7caccbba921526c3fd9dc23ea5e836f7c7f77f89c0a7ef3b55fe1906

# Full portfolio (all tokens, all chains)
bash scripts/indexer portfolio 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266

# Who is this address?
bash scripts/indexer label 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045

# Is this contract verified?
bash scripts/indexer verify 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
```

See `examples/` for full demo scripts.
