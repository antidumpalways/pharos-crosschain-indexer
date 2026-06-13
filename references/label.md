# Address Label

> **Network Configuration**: read from `../assets/networks.json`
> **All read-only** — no wallet, no private key, no gas

---

## Overview
Look up the label, name, or social profile associated with an address. Uses PharosScan's social graph API for Pharos chains, and falls back to verified contract names on Etherscan-compatible chains.

## Command Template
```bash
./scripts/indexer label <address>
```

## Parameters
| Parameter | Type | Required | Description |
|---|---|---|---|
| address | address | Yes | The address to label |

## Output
| Field | Description |
|---|---|
| label | Human-readable label (ENS, social name, contract name) |
| chain | Chain where the label was found |
| source | Source (PharosScan social, Etherscan verified contract) |

## Error Handling
| Error | Cause | Fix |
|---|---|---|
| No label found | Address has no label | Normal for unlabeled addresses |

> **Agent Guidelines**:
> 1. For Pharos: `/social/label/<addr>` on SocialScan API
> 2. For Etherscan: check verified contract name via `getsourcecode`
> 3. Return first label found, or "No label found"
