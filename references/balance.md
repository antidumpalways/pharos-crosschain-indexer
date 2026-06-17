# Multi-Chain Balance

> **Network Configuration**: read from `../assets/networks.json`
> **All read-only** — no wallet, no private key, no gas

---

## Overview
Query native token balance across all configured chains for a single address. Returns a table with chain name, balance, and native token symbol.

## Command Template
```bash
bash scripts/indexer balance <address> [chain] [--all]
```

> **Default scope:** top 15 chains (fast). Add `--all` only when the user
> explicitly asks for "all/every chain".

## Parameters
| Parameter | Type | Required | Description |
|---|---|---|---|
| address | address | Yes | EOA or contract address (0x + 40 hex) |
| chain | string | No | Filter to a specific chain name; omit for top 15 |
| --all | flag | No | Scan ALL configured chains instead of the top 15 |

## Output Parsing
| Field | Description |
|---|---|
| chain | Network name from `networks.json` |
| balance | Native token balance in human-readable units |
| symbol | Native token symbol (PHRS, PROS, ETH, POL, BNB, AVAX, CELO, XDAI) |

## Error Handling
| Error | Cause | Fix |
|---|---|---|
| `invalid address` | Address malformed | Confirm 0x + 40 hex chars |
| `connection refused` | RPC down | Check Pharos Discord; try fallback RPC |
| `(unreachable)` next to chain | RPC timeout | Update `assets/networks.json` with current RPC |

> **Agent Guidelines**:
> 1. Read `assets/networks.json` for the list of chains
> 2. For each chain with an `rpcUrl`, call `cast balance <addr> --rpc-url <rpcUrl> --ether`
> 3. If a chain returns an error, skip it and mark as "unavailable"
> 4. Format output as a table: `<chain> <balance> <symbol>`
