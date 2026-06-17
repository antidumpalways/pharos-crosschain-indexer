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

> **Windows users — read this first.** The indexer is a **bash** script.
> Run Gemini from **Git Bash** or **WSL** (not raw PowerShell). Always invoke
> commands with the `bash` prefix (e.g. `bash scripts/indexer balance ...`).
> Without `bash`, Gemini may try `./scripts/indexer` (fails: no shebang exec on
> Windows) or `python scripts/indexer` (fails: it is bash, not Python) and burn
> several retries before succeeding. For Python scripts, `python3` may be
> invoked as `python` on Windows.

## How Gemini Uses This Skill

1. **Gemini reads `SKILL.md`** on startup — it sees the `activation.triggers`, `Capability Index`, and the mapping of natural-language intents to shell commands.

2. **When you ask a question**, Gemini matches it against the trigger phrases:

```
You: "Check my balance on all chains"
Gemini: [reads SKILL.md -> trigger "balance on all chains"]
        [reads Capability Index -> "Multi-chain balance" -> references/balance.md]
        [executes: bash scripts/indexer balance <your-address>]
        [returns formatted table]
```

3. **No special config needed.** Gemini auto-discovers the skill from the current directory.

## Example Conversations in Gemini

> Tip: give your address up front so Gemini does not go hunting for a `.env` file.
> Once given, the agent remembers it for the whole session.

### Example 1 — Multi-chain balance
```
> My address is <YOUR_ADDRESS>. Check my balance on all chains.

[Gemini reads SKILL.md -> references/balance.md]
[Gemini runs: bash scripts/indexer balance <YOUR_ADDRESS>]

atlantic-testnet    14.9555 PHRS
pacific-mainnet      0.0    PROS
... (112 chains total)
```

### Example 2 — Gas price comparison
```
> Which chain has the cheapest gas right now?

[Gemini runs: bash scripts/indexer gas]
ethereum-sepolia    1.05 gwei
base-sepolia        0.01 gwei  <- cheapest
polygon-amoy       30.0  gwei  <- most expensive
```

### Example 3 — Find a transaction
```
> Where is tx 0x33a1600e7caccbba921526c3fd9dc23ea5e836f7c7f77f89c0a7ef3b55fe1906?

[Gemini runs: bash scripts/indexer tx 0x33a1...]
[OK] Found on arbitrum-sepolia - block 12345678
```

### Example 4 — Check which chains are up
```
> Which chains are online right now?

[Gemini runs: bash scripts/indexer health]
~101/110 EVM chains LIVE (a few may show DOWN)
```

### Example 5 — Add a new chain
```
> Add Polygon mainnet to the indexer

[Gemini reads references/add-chain.md]
[Gemini runs: jq '.networks += [{name:"polygon", chainId:137, ...}]' assets/networks.json]
Chain added and verified.
```

## All 14 Capabilities

> **Default scope = top 15 chains** (fast, seconds). Add `--all` ONLY when the user
> explicitly says "all/every chain". Pick **one** command per intent — never try
> several. Correct form is always `bash scripts/indexer <cmd>` (or
> `python3 scripts/<name>.py` for the Python tools).

| Trigger phrase | Command executed |
|---|---|
| "balance on all chains" | `bash scripts/indexer balance <addr>` |
| "where is this tx" | `bash scripts/indexer tx <hash>` |
| "show my portfolio" | `bash scripts/indexer portfolio <addr>` |
| "who is this address" | `bash scripts/indexer label <addr>` |
| "is this verified" | `bash scripts/indexer verify <addr>` |
| "which chains are online" | `bash scripts/indexer health` |
| "compare gas prices" | `bash scripts/indexer gas` |
| "rank chains by USDC" | `bash scripts/indexer top <addr> USDC` |
| "analyze my portfolio" | `bash scripts/indexer suggest <addr>` |
| "export portfolio" | `python3 scripts/export.py <addr> csv\|html` |
| "snapshot my balance" | `python3 scripts/diff.py save <addr>` |
| "compare balance changes" | `python3 scripts/diff.py diff <addr>` |
| "track balance history" | `python3 scripts/history.py record <addr>` |
| "alert me on balance changes" | `python3 scripts/alert.py <addr>` |

All CLI commands support `--json` (machine-readable) and `--usd` (USD values).

### Command aliases
`bal`=balance, `find`=tx, `port`/`pf`=portfolio, `lab`/`who`=label,
`ver`=verify, `ping`/`status`=health, `price`=gas, `rank`=top, `rec`=suggest.

## Pre-checks Gemini Must Run First

Before executing any command, Gemini should verify:

1. `which jq` — if not found, tell user to install (`winget install jqlang.jq` / `apt-get install jq` / `brew install jq`)
2. `which curl` and `which python3` — required dependencies
3. `ls assets/networks.json` — confirm the config file exists
4. `bash test.sh` — run the test suite (7 tests) to verify everything works

## Reducing approval prompts

Gemini asks for approval on every shell command (the `? Shell` prompts). To cut
down on them:

- Run commands prefixed with `bash` so they succeed first try (no retries).
- Type `/yolo` to auto-approve all commands (safe here — this skill is read-only:
  no wallet, no private key, no gas, no state changes).
- Or approve once and choose "always allow" for the shell tool.
