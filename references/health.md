# RPC Health Check

> **Network Configuration**: read from `../assets/networks.json`
> **All read-only** — no wallet, no private key, no gas

---

## Overview
Ping all configured chain RPCs and report which are online vs offline. Returns real-time block height and chain ID for each live chain.

## Command Template
```bash
bash scripts/indexer health [chain] [--json] [--all]
```

## Parameters
| Parameter | Type | Required | Description |
|---|---|---|---|
| chain | string | No | Filter to a specific chain; omit for all 15 |
| --json | flag | No | Machine-readable JSON output for agent consumption |

## Output Parsing

**Human-readable (default):**
```
  atlantic-testnet  688689  LIVE  24135882
  pacific-mainnet     1672  LIVE  10049249
  celo-alfajores      44787  DOWN  -
```

**JSON (with `--json`):**
```json
[
  {"chain":"atlantic-testnet","chainId":688689,"status":"LIVE","block":"24135882","rpc":"https://..."}
]
```

| Field | Description |
|---|---|
| chain | Network name from `networks.json` |
| chainId | EVM chain ID |
| status | `LIVE` (RPC responded with a valid block) or `DOWN` (timeout / unreachable) |
| block | Latest block number (decimal) when LIVE; `-` when DOWN |
| rpc | The RPC URL that was pinged |

## Error Handling
| Error | Cause | Fix |
|---|---|---|
| Chain shows `DOWN` | RPC unreachable or timeout | Check RPC URL; update `assets/networks.json` |
| All chains DOWN | Network connectivity issue | Check internet connection first |

> **Agent Guidelines**:
> 1. Call `eth_blockNumber` on each chain's RPC
> 2. If response has valid block number, mark LIVE
> 3. If timeout or empty response, mark DOWN
> 4. Use `--json` for programmatic consumption by other skills
