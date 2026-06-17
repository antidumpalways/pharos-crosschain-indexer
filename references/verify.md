# Contract Verification

> **Network Configuration**: read from `../assets/networks.json`
> **All read-only** — no wallet, no private key, no gas

---

## Overview
Check whether a contract at a given address is verified (source code published) on any chain's explorer. Queries PharosScan, Etherscan, Blockscout, and zkSync explorers. Returns yes/no + the explorer link.

## Command Template
```bash
bash scripts/indexer verify <contract-address> [chain]
```

## Parameters
| Parameter | Type | Required | Description |
|---|---|---|---|
| address | address | Yes | Contract address to check |
| chain | string | No | Single chain; omit for auto-detect |

## Output
| Field | Description |
|---|---|
| chain | Chain where verified |
| verified | true / false |
| sourceUrl | Link to verified source on the explorer |

## Error Handling
| Error | Cause | Fix |
|---|---|---|
| Not verified on any chain | Source not published | Normal — deploy + verify via `forge verify-contract` |
| API rate limit | Too many requests | Set EXPLORER_API_KEY env var |

> **Agent Guidelines**:
> 1. Read `assets/networks.json`
> 2. For each chain with an `explorerApiUrl`, call the `getsourcecode` endpoint
> 3. Return first `verified: true`, or `verified: false` on all
