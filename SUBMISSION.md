# Submission — Pharos Cross-Chain Indexer

> **Note:** `SUBMISSION-DORAHACKS.md` is a plain-text version of this
> submission, ready to paste into DoraHacks, hackathon forms, or any
> BBS that doesn't render Mermaid / HTML / some GFM features.
> Both files are kept in sync.

## Hackathon

- **Name:** Skill-to-Agent Dual Cascade Hackathon by Pharos x Anvita Flow
- **Prize pool:** 50,000 PROS (Phase 1: 20K across 40 winners)
- **Phase 1 deadline:** June 17, 2026 (extended from June 15)
- **Track:** Skill publishing — extends official `pharos-skill-engine`

## What we are submitting

`pharos-crosschain-indexer` — a cross-chain data query skill that
extends `pharos-skill-engine` with **14 multi-chain read operations**.
No contract deploy. No gas. No wallet. No mock data. No API keys.
Pure data, live from public RPCs.

A single command (`bash scripts/indexer <command>`) queries any
address across **110 EVM chains + Solana + Near** and returns a
unified table. The default top-15 scope answers in 4-10 seconds;
add `--all` for the full scan.

Built for the AI agent economy: `SKILL.md` auto-loads in Claude
Code, OpenCode, Cursor, Gemini CLI, Codex, and Windsurf. The user
asks in plain English; the agent invokes the right command; the
indexer returns real on-chain data.

## The problem

Pharos operates multiple chains (Atlantic testnet + Pacific mainnet)
and bridges to external chains (Sepolia, Base Sepolia, Arbitrum
Sepolia via CCIP / CCTP / LayerZero). Today, there is no single
tool to answer:

- What is my balance on EVERY chain?
- Where is this transaction?
- Show me my full portfolio across chains.

Developers open 5 different block explorers and run 5 different
RPC queries to answer one question. This skill replaces that with
one command.

## The solution

`pharos-crosschain-indexer` is a single bash CLI (`scripts/indexer`
with 9 commands) plus 6 Python tools (`multi.py`, `export.py`,
`diff.py`, `history.py`, `alert.py`, `suggest.py`) that:

- Read 112 chains from `assets/networks.json` (110 EVM + Solana + Near)
- Default to top 15 chains (Pharos + 13 mainnet heavy-hitters) for
  sub-10-second answers
- Query live public RPCs directly via `eth_getBalance`,
  `eth_getTransactionByHash`, `eth_blockNumber`, `eth_gasPrice`
- Return unified tables: chain, token, balance, USD value
- Optionally export to CSV/HTML, snapshot for later diff, monitor
  for alerts, suggest bridge/deploy actions

All wrapped in `SKILL.md` with `activation.triggers` so any agent
auto-discovers and uses it.

## 14 operations (verified — 16/16 integration tests pass)

| # | Operation | How it works | Reference |
|---|---|---|---|
| 1 | `balance <addr>` | `eth_getBalance` on each RPC; hex→ether | `references/balance.md` |
| 2 | `tx <hash>` | `eth_getTransactionByHash` on each RPC; match by chainId | `references/tx.md` |
| 3 | `portfolio <addr>` | Native + ERC-20 via `balanceOf(address)(uint256)` from `tokens.json` | `references/portfolio.md` |
| 4 | `label <addr>` | SocialScan for Pharos; verified contract name for Etherscan | `references/label.md` |
| 5 | `verify <addr>` | `getsourcecode` on each explorer; non-empty `SourceCode` = verified | `references/verify.md` |
| 6 | `health` | `eth_blockNumber` on each RPC; LIVE if result ≠ `0x0` | `references/health.md` |
| 7 | `gas` | `eth_gasPrice` on each RPC; wei→gwei | `references/gas.md` |
| 8 | `top <addr> <TOKEN>` | Like portfolio but sorted desc by token balance | `references/top.md` |
| 9 | `suggest <addr>` | Native + USDC + gas combined; 4 categories of recommendation | `references/health.md#portfolio-suggestions` |
| 10 | `multi.py <addr...>` | Aggregate N addresses × 110 chains in one table | standalone script |
| 11 | `export.py <addr> csv\|html` | Dump full portfolio to `data/portfolio.csv` or `.html` | standalone script |
| 12 | `diff.py save\|diff <addr>` | Snapshot balances; later compare for per-chain deltas | standalone script |
| 13 | `history.py record\|show\|count` | Time-series of balance snapshots in `data/history/` | standalone script |
| 14 | `alert.py <addr> [chain] [thr] [int]` | Loop forever; print `[UP]+` / `[DN]-` on balance changes | standalone script |

## Verified test results (16/16 PASS on Windows Git Bash)

A full integration test with a real address hitting live public RPCs:

1. `balance` — PASS — atlantic 3.18 PHRS, ethereum 0.0155 ETH, base 0.0018 ETH
2. `balance atlantic-testnet` — PASS — 3.18 PHRS
3. `balance --usd` — PASS — PROS $0.55, ETH $27.12, AVAX $0.37, zkSync $0.13
4. `tx 0x80367b0...` — PASS — Found on Pharos Pacific in 4 seconds
5. `portfolio` — PASS — 15 chains
6. `label` — PASS
7. `verify` — PASS
8. `health` — PASS — all top-15 chains LIVE
9. `gas` — PASS — 0.01 to 10 gwei
10. `top USDC` — PASS
11. `suggest` — PASS — GAS/BRIDGE/DEPLOY recommendations
12. `multi.py` — PASS — 49 lines
13. `export.py csv` — PASS — `data/portfolio.csv` (43 chains)
14. `diff.py diff` — PASS
15. `history.py show` — PASS
16. `alert.py` — PASS — 13 chains monitored

Reproduce with: `bash test_all_14.sh`

## How to verify (for judges)

```bash
git clone https://github.com/antidumpalways/pharos-crosschain-indexer
cd pharos-crosschain-indexer
bash install.sh

# Real Atlantic testnet query (returns live data)
bash scripts/indexer balance <YOUR_ADDRESS> atlantic-testnet

# Multi-chain default scope (Pharos + 13 mainnet, sub-10s)
bash scripts/indexer balance <YOUR_ADDRESS>

# Find a transaction (any EVM chain, ~4s)
bash scripts/indexer tx 0x80367b036e15831e340d061c4bbfc019f10c50d7978d404c5df6d8924f3ffd86
# Output: Found on pacific-mainnet (chainId 1672), block 0x9df43f
```

The last command finds a real Pharos Pacific mainnet transaction
in about 4 seconds and returns the block, sender, recipient, value,
and a pharosscan.xyz link.

## Honest disclosure

- **Zero mocks.** Every number comes from a live `eth_getBalance` or
  `eth_getTransactionByHash` call to a public RPC. No fake data.
- **Zero contracts.** Pure read operations. No deploy, no gas, no
  wallet, no private key, no signing.
- **Zero fake addresses.** All token addresses in `tokens.json`
  sourced from official Pharos docs and public token registries.
- **No API keys required.** Default top-15 scope works with public
  free-tier RPCs. Etherscan V1 is deprecated so the indexer uses
  direct `eth_*` JSON-RPC instead.
- **No npm deps for the core.** The npm wrapper (`cli.mjs`) is a
  38-line shim that just calls `bash scripts/indexer`.
- **Windows-first.** `install.sh` auto-downloads `jq.exe` to
  `$HOME/bin` if missing. The indexer auto-detects `python3` vs
  `python` (Windows hijacks `python3` as a Microsoft Store
  redirector).
- **Single contributor.** Solo project, built for the hackathon.
- **16/16 integration tests pass** on Windows Git Bash with real
  live data from public RPCs.

## Why this submission stands out

| Typical submission | This submission |
|---|---|
| 1-2 operations | 14 operations across chains |
| Single-chain | 110 EVM + Solana + Near |
| Requires contract deploy | Pure read, zero deploy |
| Hard to demo | One command, 4-second demo |
| Reinvents the wheel | Extends official `pharos-skill-engine` |
| Heavy SDK dependency | Pure bash + curl + jq + Python stdlib |
| Needs signup/API key | Zero config, zero keys |
| Third-party server | Runs on user's own machine |

## Architecture (plain text)

Three layers, one direction of data flow:

1. **AI Agent Runtime** (Claude Code, OpenCode, Cursor, Gemini CLI)
   reads `SKILL.md` to find the right command.
2. **Skill Layer** (`SKILL.md`, `references/*.md`, `AGENTS.md`) maps
   user intent to the right bash or Python command.
3. **Runtime** (`scripts/indexer` with 9 bash commands, plus 6
   Python tools) reads config from `assets/networks.json`,
   `assets/tokens.json`, `assets/priceFeeds.json`, then calls live
   public RPCs.
4. **Config and Data** (`assets/`) holds the 112-chain registry,
   per-chain ERC-20 token list, and CoinGecko price feed map.
5. **Live Public Chains** (Pharos Atlantic + Pacific, 110 EVM
   mainnets and testnets, Solana, Near) answer every `eth_*` call.

Every box is small enough to read in a sitting. Every arrow is
`curl` + `jq` + `bash` + a few hundred lines of Python.

## File structure

```
pharos-crosschain-indexer/

  SKILL.md                  agent entry point (auto-discovered)
  AGENTS.md                 14 mandatory rules (R1 to R14)
  README.md                 main documentation
  SUBMISSION.md             this file
  SUBMISSION-DORAHACKS.md   plain-text version for BBS / form paste
  install.sh                dependency check + Windows jq auto-install
  test.sh                   7 unit tests
  test_all_14.sh            16 integration tests (live RPCs)

  assets/
    networks.json           112 chains (RPCs, chainIds, explorers)
    tokens.json             per-chain ERC-20 token registry
    priceFeeds.json         CoinGecko symbol to cg_id map

  references/               one md per bash operation
    balance.md
    tx.md
    portfolio.md
    label.md
    verify.md
    health.md
    gas.md
    top.md
    add-chain.md

  scripts/
    indexer                 1 bash file with 9 commands
    multi.py                aggregate multiple addresses
    export.py               CSV or HTML export
    diff.py                 snapshot and diff balances
    history.py              time-series history
    alert.py                real-time balance alerts
    suggest.py              portfolio analysis

  examples/
    crosschain-balance.sh
    portfolio-overview.sh

  docs/
    ARCHITECTURE.md
    BUILD.md                full technical walkthrough
    DEMO-SCRIPT.md
```

Total: roughly 1500 lines of bash + 1200 lines of Python.
Reviewable in a sitting.

## Compliance with Pharos Skill Engine checklist

| Requirement | Status |
|---|---|
| SKILL.md with `activation.triggers` | YES — 60+ natural-language triggers |
| Capability Index in SKILL.md | YES — 14 capabilities mapped to references/*.md |
| Reference files complete | YES — 9 files with command + params + output + error + agent guidelines |
| Agent Guidelines per operation | YES — each reference has numbered steps |
| Assets folder configured | YES — networks.json + tokens.json + priceFeeds.json |
| No contracts to deploy | N/A — this is read-only |
| Test suite | YES — 7 unit tests + 16 integration tests passing |
| No mock data | YES — every query is live |

## License

MIT License. Open source. Free to use, modify, and redistribute.

## Links

- GitHub: <https://github.com/antidumpalways/pharos-crosschain-indexer>
- Hackathon: <https://dorahacks.io/hackathon/pharos-phase1/>
- Pharos docs: <https://docs.pharos.xyz/tooling-and-infrastructure/pharos-skill-engine-guide>
- Pharos agent center: <https://www.pharos.xyz/agent-center>
