# Demo Script — Pharos Cross-Chain Indexer (7 Minutes)

> **No CLI typed. No commands memorized. Pure NLP.** The agent reads `SKILL.md`,
> maps user intent to the right operation, executes, and returns formatted results.

---

## SCENE 0 — Setup (30 seconds)

```
LO: "Install the Pharos cross-chain indexer skill"

AGENT: [clones repo, runs install.sh]
       [OK] curl, jq, python3 — all dependencies found
       [OK] 112 chains configured (110 EVM + Solana + Near)
       Installation complete.
```

---

## SCENE 1 — Portfolio Analysis (60 seconds)

```
LO: "Analyze my portfolio on every chain"

AGENT: [Reads SKILL.md -> activation.triggers: 'analyze my portfolio']
       [Maps to Capability Index -> suggest -> references/suggest.md]
       [Executes: python3 scripts/suggest.py 0xf39Fd6...]
       [Queries 112 RPCs for balances, gas prices, token availability]

=========================================================
|  Portfolio Suggestions                                    |
|------------------------------------------------------|
|  Address: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266  |
=========================================================

  [GAS] Gas prices across 101 live chains:
    base-sepolia        0.01 gwei <<< CHEAPEST
    ethereum            0.07 gwei
    bsc                 0.05 gwei
    atlantic-testnet   10.00 gwei
    pacific-mainnet    10.00 gwei
    polygon-amoy       30.00 gwei
    polygon           282.54 gwei
    celo              202.50 gwei

  [BALANCE] Chains where you can pay gas:
    atlantic-testnet        14.955517 PHRS
    avalanche-fuji           0.000230 AVAX
    blast-sepolia            0.000000 ETH
    zksync-sepolia           0.000024 ETH
    fantom                   0.000010 FTM

  [BRIDGE] You have 14.9555 PHRS on atlantic-testnet
           Gas on atlantic-testnet: 10.00 gwei
           Gas on base-sepolia: 0.01 gwei
  -> Consider bridging to base-sepolia for cheaper tx

  [USDC] Available on 15 chains:
    atlantic-testnet, pacific-mainnet, ethereum-sepolia,
    base-sepolia, arbitrum-sepolia...

  4 suggestions generated.
```

---

## SCENE 2 — Cross-Chain Balance with USD (45 seconds)

```
LO: "Check my balance on all chains and show me dollar values"

AGENT: [Reads SKILL.md -> trigger: 'balance on all chains']
       [Maps to Capability Index -> balance -> references/balance.md]
       [Executes: ./scripts/indexer bal 0xf39Fd6... --usd]
       [Fetches live CoinGecko prices: ETH=$1676, AVAX=$28, SOL=$180]

  atlantic-testnet   14.9555 PHRS        (N/A - no price feed)
  pacific-mainnet     0.0000 PROS        ($0.00)
  ethereum-sepolia    0.0000 ETH         ($0.00)
  avalanche-fuji      0.0002 AVAX        ($0.01)
  zksync-sepolia      0.0000 ETH         ($0.04)
  solana              0.0000 SOL         ($0.00)
  near                0.0000 NEAR        ($0.00)

  Queried 30 chains. You have gas on Atlantic + AVAX on Fuji.
  PROS = $0.59 via CoinGecko (pharos-network).
```

---

## SCENE 3 — Vitalik's Portfolio (60 seconds)

```
LO: "Show me Vitalik's portfolio across all chains"

AGENT: [Reads SKILL.md -> trigger: 'show my portfolio']
       [Executes: python3 scripts/multi.py 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045]

  Multi-Address Balance (1 address x 112 chains)

  0xd8dA6BF2...6045   ethereum-sepolia    58.240427 ETH        ($97,000)
  0xd8dA6BF2...6045   blast-sepolia    18006.951748 ETH    ($30,200,000)
  0xd8dA6BF2...6045   bsc-testnet         7.083038 BNB         ($4,600)
  0xd8dA6BF2...6045   base-sepolia        5.534431 ETH         ($9,277)
  0xd8dA6BF2...6045   avalanche-fuji      4.098270 AVAX          ($114)
  0xd8dA6BF2...6045   optimism-sepolia    1.944315 ETH         ($3,259)
  0xd8dA6BF2...6045   arbitrum-sepolia    0.942800 ETH         ($1,580)
  0xd8dA6BF2...6045   atlantic-testnet    0.277844 PHRS           (N/A)
  0xd8dA6BF2...6045   scroll-sepolia      0.039400 ETH            ($66)
  0xd8dA6BF2...6045   zksync-sepolia      0.104110 ETH           ($174)
  0xd8dA6BF2...6045   gnosis-chiado       0.000200 XDAI          ($0.00)

  Found 11 chains with balances. Vitalik has ~$30M on Blast Sepolia.
```

---

## SCENE 4 — RPC Health Check + Gas Comparison (45 seconds)

```
LO: "Which chains are online right now?"

AGENT: [Reads SKILL.md -> trigger: 'which chains are online']
       [Executes: python3 scripts/suggest.py 0xf39Fd6... | head -35]

  101/110 EVM chains LIVE (90%). Only 9 DEAD.
  Plus 2 non-EVM: Solana + Near (both LIVE).

LO: "Compare gas prices — where's cheapest to deploy a contract?"

AGENT: [Reads SKILL.md -> trigger: 'compare gas prices']
       [Executes: ./scripts/indexer gas]

  base-sepolia        0.01 gwei     <<< CHEAPEST
  base                0.01 gwei
  avalanche           0.01 gwei
  arbitrum            0.02 gwei
  scroll              0.02 gwei
  linea               0.04 gwei
  bsc                 0.05 gwei
  ethereum            0.07 gwei
  ethereum-sepolia    1.01 gwei
  fantom              1.08 gwei
  atlantic-testnet   10.00 gwei
  pacific-mainnet    10.00 gwei
  polygon-amoy       30.00 gwei
  moonbeam           31.25 gwei
  celo              202.50 gwei     <<< MOST EXPENSIVE
  polygon           282.54 gwei

  Cheapest: base-sepolia at 0.01 gwei. Most expensive: polygon at 282 gwei.
```

---

## SCENE 5 — Export + History + Alert (60 seconds)

```
LO: "Export my portfolio to CSV for my accountant"

AGENT: [Reads SKILL.md -> trigger: 'export portfolio to CSV']
       [Executes: python3 scripts/export.py 0xf39Fd6... csv]

  CSV exported: data/portfolio_0xf39Fd6e5.csv — 34 chains
  (opens file in Excel/Google Sheets)

LO: "Also generate an HTML report of Vitalik's holdings"

AGENT: [Executes: python3 scripts/export.py 0xd8dA6BF2... html]

  HTML exported: data/portfolio_0xd8dA6BF2.html — 65 chains
  (opens in browser — dark theme, responsive table)

LO: "Record a snapshot of my balance now"

AGENT: [Reads SKILL.md -> trigger: 'snapshot my balance']
       [Executes: python3 scripts/diff.py save 0xf39Fd6...]

  Snapshot saved: 33 chains with balance at Tue Jun 16 04:26:45 2026
  File: data/snapshot.json

LO: "Set up an alert — tell me if my balance changes by more than 1 PHRS"

AGENT: [Reads SKILL.md -> trigger: 'alert me if balance changes']
       [Executes: python3 scripts/alert.py 0xf39Fd6... atlantic-testnet 1.0 60]

  Monitoring atlantic-testnet every 60s (threshold ±1.0 PHRS)
  [04:27:00] No change.
  [04:28:00] No change.
  (press Ctrl+C to stop)
```

---

## SCENE 6 — What Makes This Different (30 seconds)

```
LO: "Why is this better than checking each explorer manually?"

AGENT:
  - 112 chains in 1 command vs 112 browser tabs
  - AI agent auto-discovers the skill via SKILL.md + activation.triggers
  - Extends pharos-skill-engine (the official standard)
  - Works with Claude Code, Gemini CLI, Cursor, OpenCode, Codex
  - Live data only. No mock. No fake addresses.
  - All token addresses from official Pharos docs + public registries
  - CI/CD via GitHub Actions auto-test on every push
  - 25 commits, 14 operations, 10 reference files
```

---

## TOTAL: 7 minutes. Zero CLI typing. Pure NLP.
