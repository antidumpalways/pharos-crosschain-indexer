# Portfolio Overview

> **Network Configuration**: read from `../assets/networks.json`
> **All read-only** — no wallet, no private key, no gas

---

## Overview
Query ALL token balances for an address across ALL chains. Combines native balance + ERC-20 token balances (from `assets/tokens.json` + on-chain discovery). Returns a unified table.

## Command Template
```bash
bash scripts/indexer portfolio <address> [chain] [--all]
```

## Parameters
| Parameter | Type | Required | Description |
|---|---|---|---|
| address | address | Yes | EOA or contract address |
| chain | string | No | Filter to one chain; omit for all |

## Output
```
Chain             Token    Balance
────────────────────────────────────
atlantic-testnet   PHRS     14.9555
atlantic-testnet   USDC   5000.0000
pacific-mainnet    PROS    250.0000
```

## Error Handling
| Error | Cause | Fix |
|---|---|---|
| Token not found on a chain | `balanceOf` returns revert | Skip token for that chain |
| RPC down for a chain | Timeout | Skip chain; mark as "offline" |

> **Agent Guidelines**:
> 1. For each chain, query native balance first
> 2. Read `assets/tokens.json` for known tokens on that chain
> 3. `cast call <token> "balanceOf(address)(uint256)" <addr>`
> 4. Convert raw balance with `decimals` field
