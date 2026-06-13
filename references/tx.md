# Cross-Chain Tx Lookup

> **Network Configuration**: read from `../assets/networks.json`
> **All read-only** — no wallet, no private key, no gas

---

## Overview
Find a transaction hash across chains. The indexer queries every configured explorer API sequentially until it finds the tx. Returns receipt, block number, status, and chain.

## Command Template
```bash
./scripts/indexer tx <tx-hash>
```

## Parameters
| Parameter | Type | Required | Description |
|---|---|---|---|
| tx-hash | bytes32 | Yes | Transaction hash (0x + 64 hex) |

## Output Parsing
| Field | Description |
|---|---|
| chain | Network where the tx was found |
| blockNumber | Block the tx was included in |
| from / to | Sender and recipient |
| explorerUrl | Link to view on the chain's explorer |

## Error Handling
| Error | Cause | Fix |
|---|---|---|
| `transaction not found` on all chains | Hash doesn't exist on any indexed chain | Confirm the hash; allow extra time for indexing |
| API rate limit | Too many requests | Set EXPLORER_API_KEY env var or retry after delay |

> **Agent Guidelines**:
> 1. Read `assets/networks.json`
> 2. For each chain with an `explorerApiUrl`, call the tx lookup endpoint
> 3. Stop on first non-empty result
> 4. Format: `<chain> block <block> status <ok|fail>`
