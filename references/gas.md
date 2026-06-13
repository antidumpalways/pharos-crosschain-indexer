# Cross-Chain Gas Price Comparison

> **Network Configuration**: read from `assets/networks.json`
> **All read-only** — no wallet, no private key, no gas

---

## Overview
Compare current gas prices across all configured chains. Calls `eth_gasPrice` on each chain's RPC and returns a sortable table. Useful for agents deciding which chain to transact on.

## Command Template
```bash
./scripts/indexer gas [chain] [--json]
```

## Parameters
| Parameter | Type | Required | Description |
|---|---|---|---|
| chain | string | No | Filter to one chain; omit for all 15 |

## Output
```
  atlantic-testnet      688689    10.0 gwei
  ethereum-sepolia    11155111     1.05 gwei
  polygon-amoy          80002    30.0 gwei
```

## Error Handling
| Error | Cause | Fix |
|---|---|---|
| `— DOWN` | RPC unreachable | Check `health` command to confirm RPC status |

> **Agent Guidelines**:
> 1. Call `eth_gasPrice` on each chain's RPC
> 2. Convert hex wei to gwei (÷ 1e9)
> 3. Agent can use this to decide which chain is cheapest for a transaction
> 4. Use `--json` for programmatic consumption
