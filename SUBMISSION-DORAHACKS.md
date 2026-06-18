# Submission — Pharos Cross-Chain Indexer

> Plain-text version for hackathon submission forms (DoraHacks, etc.)
> that don't render Mermaid diagrams or some GitHub-Flavored Markdown.
> All syntax here is safe to paste into any BBS, forum, or web form.

---

## Hackathon

- Name: Skill-to-Agent Dual Cascade Hackathon by Pharos x Anvita Flow
- Prize pool: 50,000 PROS (Phase 1: 20K across 40 winners)
- Phase 1 deadline: June 17, 2026 (extended from June 15)
- Track: Skill publishing (extends official pharos-skill-engine)
- Repo: https://github.com/antidumpalways/pharos-crosschain-indexer

---

## What we are submitting

pharos-crosschain-indexer: a cross-chain data query skill that extends
pharos-skill-engine with 14 multi-chain read operations. No contract
deploy. No gas. No wallet. Pure data.

A single command (bash scripts/indexer <command>) queries any
address across 110 EVM chains plus Solana and Near and returns a
unified table. Zero mock data, zero API keys required for the
default top-15 scope, zero npm dependencies for the core.

Built for the AI agent economy: SKILL.md auto-loads in Claude Code,
OpenCode, Cursor, and other agent CLIs. The user asks in plain
English; the agent invokes the right command; the indexer returns
real on-chain data in seconds.

---

## The problem

Pharos operates multiple chains (Atlantic testnet and Pacific mainnet)
and bridges to external testnets (Sepolia, Base Sepolia, Arbitrum
Sepolia via CCIP/CCTP/LayerZero). But there is no single tool to
answer simple questions like:

- What is my balance on EVERY chain?
- Where is this transaction — Atlantic or Pacific or somewhere else?
- Show me my full portfolio across chains.

Today, developers open 5 different block explorers and run 5
different RPC queries to answer one question. This skill replaces
that with one command.

---

## The solution

pharos-crosschain-indexer is a single bash CLI (scripts/indexer)
plus six Python tools (multi.py, export.py, diff.py, history.py,
alert.py, suggest.py) that:

- Read 112 chains from assets/networks.json (110 EVM + Solana + Near)
- Default to top 15 chains (Pharos + 13 mainnet heavy-hitters) for
  sub-10-second answers
- Query live public RPCs directly via eth_getBalance,
  eth_getTransactionByHash, eth_blockNumber, eth_gasPrice
- Return unified tables: chain, token, balance, USD value
- Optionally export to CSV/HTML, snapshot for later diff, monitor
  for alerts, suggest bridge/deploy actions

All wrapped in a SKILL.md with activation.triggers so any agent
auto-discovers and uses it.

---

## 14 operations (verified, 16/16 integration tests passing)

### Group A: bash commands in scripts/indexer

1. balance - multi-chain native balance
2. tx - cross-chain transaction lookup
3. portfolio - native + ERC-20 tokens per chain
4. label - address identity (PharosScan + verified contract)
5. verify - contract source-code verification check
6. health - RPC health check across all chains
7. gas - gas price comparison
8. top - rank chains by token balance
9. suggest - portfolio analysis and recommendations

### Group B: Python tools in scripts/

10. multi.py - aggregate multiple addresses
11. export.py - export portfolio to CSV or HTML
12. diff.py - balance snapshot and diff
13. history.py - time-series balance history
14. alert.py - real-time balance alerts

Each operation has a dedicated reference file at references/<op>.md
with command template, parameter table, output format, error table,
and numbered agent guidelines.

---

## Verified test results (16/16 PASS on Windows Git Bash)

1. balance - PASS - atlantic 3.18 PHRS, ethereum 0.0155 ETH
2. balance atlantic-testnet - PASS - 3.18 PHRS
3. balance --usd - PASS - PROS 0.55 USD, ETH 27.12 USD, AVAX 0.37 USD
4. tx - PASS - Pharos Pacific tx found in 4 seconds
5. portfolio - PASS - all tokens across 15 chains
6. label - PASS - PharosScan + Etherscan lookup
7. verify - PASS - contract source verification
8. health - PASS - all top 15 chains LIVE
9. gas - PASS - 0.01 to 10 gwei across 13 mainnet
10. top - PASS - USDC ranking per chain
11. suggest - PASS - GAS/BRIDGE/DEPLOY recommendations
12. multi.py - PASS - 49 lines, all tokens across 110 chains
13. export.py - PASS - data/portfolio.csv with 43 chains
14. diff.py - PASS - runs cleanly
15. history.py - PASS - runs cleanly
16. alert.py - PASS - 13 chains monitored

Reproduce with: bash test_all_14.sh (after git clone + bash install.sh).

---

## How to verify (for judges)

```
git clone https://github.com/antidumpalways/pharos-crosschain-indexer
cd pharos-crosschain-indexer
bash install.sh

bash scripts/indexer balance <YOUR_ADDRESS> atlantic-testnet
bash scripts/indexer balance <YOUR_ADDRESS>
bash scripts/indexer portfolio <YOUR_ADDRESS>
bash scripts/indexer tx 0x80367b036e15831e340d061c4bbfc019f10c50d7978d404c5df6d8924f3ffd86
```

The last command finds a real Pharos Pacific mainnet transaction
in about 4 seconds and returns the block, sender, recipient, value,
and a pharosscan.xyz link.

---

## Honest disclosure

- Zero mocks. Every number comes from a live eth_getBalance or
  eth_getTransactionByHash call to a public RPC. No fake data.
- Zero contracts. Pure read operations. No deploy, no gas, no wallet.
- Zero fake addresses. All token addresses in tokens.json sourced
  from official Pharos docs and public token registries.
- No API keys required. Default top-15 scope works with public
  free-tier RPCs. Etherscan V1 is deprecated so the indexer uses
  direct eth_* JSON-RPC instead.
- No npm dependencies for the core. The npm wrapper (cli.mjs) is
  a 38-line shim that just calls bash scripts/indexer.
- Windows-first. install.sh auto-downloads jq.exe to $HOME/bin if
  missing. The indexer auto-detects python3 vs python (Windows
  hijacks python3 as a Microsoft Store redirector).
- Single contributor. Solo project, built for the hackathon.
- 16/16 integration tests pass on Windows Git Bash with real
  live data from public RPCs.

---

## Why this submission stands out

Compared to typical hackathon submissions:

- 1 to 2 operations vs our 14 operations across chains
- Single-chain vs our 110 EVM + Solana + Near
- Requires contract deploy vs our pure read, zero deploy
- Hard to demo vs our one-command, four-second demo
- Reinvents the wheel vs our extends official pharos-skill-engine

Compared to other data indexers:

- Open source, MIT, no API keys, no signup
- Runs on the user's own machine, no third-party server
- Pure bash + curl + jq + Python stdlib, no heavy SDK
- Agent-native: SKILL.md format auto-loads in any modern agent
- 100% read-only: no fund custody, no signing, no gas risk

---

## Architecture in plain text

Three layers, one direction of data flow:

1. AI Agent Runtime (Claude Code, OpenCode, Cursor, Gemini CLI)
   reads SKILL.md to find the right command.

2. Skill Layer (SKILL.md, references/*.md, AGENTS.md) maps user
   intent to the right bash or Python command.

3. Runtime (scripts/indexer with 9 bash commands, plus 6 Python
   tools) reads config from assets/networks.json, assets/tokens.json,
   and assets/priceFeeds.json, then calls live public RPCs.

4. Config and Data (assets/) holds the 112-chain registry,
   per-chain ERC-20 token list, and CoinGecko price feed map.

5. Live Public Chains (Pharos Atlantic + Pacific, 110 EVM mainnets
   and testnets, Solana, Near) answer every eth_* call.

Every box is small enough to read in a sitting. Every arrow is
curl plus jq plus bash plus a few hundred lines of Python.

---

## File structure

```
pharos-crosschain-indexer/

  SKILL.md                  agent entry point (auto-discovered)
  AGENTS.md                 14 mandatory rules (R1 to R14)
  README.md                 main documentation
  SUBMISSION.md             hackathon submission
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

Total: roughly 1500 lines of bash plus 1200 lines of Python. Reviewable
in a sitting.

---

## Compliance with Pharos Skill Engine checklist

- SKILL.md with activation.triggers: YES, 60+ natural-language triggers
- Capability Index: YES, 14 capabilities mapped to references/*.md
- Reference files: YES, 9 files with command + params + output + error
- Agent Guidelines: YES, each reference has numbered steps
- Assets folder: YES, networks.json + tokens.json + priceFeeds.json
- No contracts to deploy: N/A, this is read-only
- No contract to verify: N/A
- Test suite: YES, 7 unit tests + 16 integration tests passing

---

## License

MIT License. Open source. Free to use, modify, and redistribute.

---

## Links

- GitHub: https://github.com/antidumpalways/pharos-crosschain-indexer
- Hackathon: https://dorahacks.io/hackathon/pharos-phase1/
- Pharos docs: https://docs.pharos.xyz/tooling-and-infrastructure/pharos-skill-engine-guide
- Pharos agent center: https://www.pharos.xyz/agent-center

---

## Contact

Built by antidumpalways for the Pharos x Anvita Flow Skill-to-Agent
Dual Cascade Hackathon, June 2026.
