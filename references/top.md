# Top Chains by Token Balance

> **Network Configuration**: read from `assets/networks.json`
> **All read-only** — no wallet, no private key, no gas

---

## Overview
Query a specific ERC-20 token balance across all chains and rank chains from highest to lowest. Answers "where is my USDC?" or "which chain has my WETH?"

## Command Template
```bash
bash scripts/indexer top <address> [token-symbol] [--json] [--all]
```

## Parameters
| Parameter | Type | Required | Description |
|---|---|---|---|
| address | address | Yes | EOA or contract address |
| token-symbol | string | No | Token symbol from `tokens.json` (default: USDC) |

## Output
```
  atlantic-testnet         5000.0
  pacific-mainnet          1000.0
  ethereum-sepolia             0.0
```

## Error Handling
| Error | Cause | Fix |
|---|---|---|
| Token not found on any chain | Symbol not in `tokens.json` for any chain | Check `assets/tokens.json` for available tokens |
| All zero | Address has no balance of this token | Normal for unfunded addresses |

> **Agent Guidelines**:
> 1. Read `assets/tokens.json` for token addresses matching the symbol on each chain
> 2. For each chain, call `balanceOf(addr)` on the token contract
> 3. Collect results, sort descending by balance
> 4. This helps agents decide where to bridge/swap from
