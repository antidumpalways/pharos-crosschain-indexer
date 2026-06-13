# Cross-Chain Indexer — Operation Reference

> **Network Configuration**: read from `../assets/networks.json`
> **All read-only** — no wallet, no private key, no gas
> **For write operations**: use the base engine's `references/transaction.md`

---

## Multi-Chain Balance

### Overview
Query native token balance across all configured chains for a single address. Returns a table with chain name, balance, and native token symbol.

### Command Template
```bash
# Single chain
cast balance <address> --rpc-url <rpc> --ether

# All chains at once (via scripts/indexer)
./scripts/indexer balance <address>
```

### Parameters
| Parameter | Type | Required | Description |
|---|---|---|---|
| address | address | Yes | EOA or contract address (0x + 40 hex) |
| chain | string | No | Filter to a specific chain name from networks.json; omit for "all" |

### Output Parsing
| Field | Description |
|---|---|
| chain | Network name from `networks.json` |
| balance | Native token balance in human-readable units |
| symbol | Native token symbol (PHRS, PROS, ETH) |
| rpc | RPC URL used for the query |

### Manual per-chain example
```bash
# Atlantic testnet
cast balance 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045 \
  --rpc-url https://atlantic.dplabs-internal.com --ether

# Pacific mainnet
cast balance 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045 \
  --rpc-url https://rpc.pharos.xyz --ether
```

### Error Handling
| Error | Cause | Fix |
|---|---|---|
| `invalid address` | Address malformed | Confirm 0x + 40 hex chars |
| `connection refused` | RPC down | Check Pharos Discord for network status; try fallback RPC |
| Empty return | RPC unreachable | Skip this chain and continue with the next |

> **Agent Guidelines**:
> 1. Read `assets/networks.json` for the list of chains
> 2. For each chain with an `rpcUrl`, call `cast balance <addr> --rpc-url <rpcUrl> --ether`
> 3. If a chain returns an error, skip it and mark it as "unavailable" in the output
> 4. Format output as a table: `<chain> <balance> <symbol>`
> 5. If the user specifies a single chain, query only that one

---

## Cross-Chain Tx Lookup

### Overview
Find a transaction hash across chains. The indexer queries every configured explorer API until it finds the tx. Returns the receipt, block number, status, and chain.

### Command Template
```bash
# Auto-detect which chain the tx is on
./scripts/indexer tx <tx-hash>
```

### Manual
```bash
# Try Atlantic first (PharosScan API)
curl -s "https://api.socialscan.io/pharos-atlantic-testnet?module=transaction&action=gettxinfo&txhash=<hash>"

# Try Pacific next
curl -s "https://api.socialscan.io/pharos-mainnet?module=transaction&action=gettxinfo&txhash=<hash>"

# Try Etherscan-compatible chains
curl -s "https://api.etherscan.io/api?module=proxy&action=eth_getTransactionByHash&txhash=<hash>"
```

### Parameters
| Parameter | Type | Required | Description |
|---|---|---|---|
| tx-hash | bytes32 | Yes | Transaction hash (0x + 64 hex) |

### Output Parsing
| Field | Description |
|---|---|
| chain | Network where the tx was found |
| blockNumber | Block the tx was included in |
| from / to | Sender and recipient |
| status | `1` (success) or `0` (failed) |
| explorerUrl | Link to view on the chain's explorer |

### Error Handling
| Error | Cause | Fix |
|---|---|---|
| `transaction not found` on all chains | Hash doesn't exist on any indexed chain | Confirm the hash; allow extra time for indexing |
| `transaction not found` on some chains | Expected — the tx is only on one chain | Continue probing other chains |

> **Agent Guidelines**:
> 1. Read `assets/networks.json`
> 2. For each chain with an `explorerApiUrl`, call the tx lookup endpoint
> 3. Stop on first non-empty result
> 4. Format: `<chain> block <block> status <ok|fail> from <from> to <to>`
> 5. Include the explorer URL so the user can click through

---

## Portfolio Overview

### Overview
Query ALL token balances for an address across ALL chains. Combines native balance + ERC-20 token balances (from `assets/tokens.json` + on-chain discovery). Returns a unified table.

### Command Template
```bash
./scripts/indexer portfolio <address>
```

### How it works
1. For each chain with an RPC, query native balance
2. For each chain, read `assets/tokens.json` for known ERC-20 addresses
3. For each token, call `balanceOf(addr)` via `cast call`
4. Convert raw balance to human units using the token's `decimals`
5. Print as a unified table

### Parameters
| Parameter | Type | Required | Description |
|---|---|---|---|
| address | address | Yes | EOA or contract address |
| chain | string | No | Filter to one chain; omit for all |

### Output (example)
```
Chain        Token    Balance         USD (est)
atlantic      PHRS    100.5           $—
atlantic      USDC    5000.0          $5000.00
pacific       PROS    250.0           $—
ethereum      ETH       0.5           $1500.00
ethereum      USDC    2000.0          $2000.00
base          USDC     100.0          $100.00
```

### Error Handling
| Error | Cause | Fix |
|---|---|---|
| Token not found on a chain | `balanceOf` returns revert or `0x` code | Skip token for that chain; continue with next |
| RPC down for a chain | Timeout or connection refused | Skip chain; mark as "offline" |

> **Agent Guidelines**:
> 1. For each chain, query native balance first
> 2. Read `assets/tokens.json` for known tokens on that chain
> 3. For each token, `cast call <token> "balanceOf(address)(uint256)" <addr> --rpc-url <rpc>`
> 4. If `cast call` fails (no code at address, wrong chain), skip the token
> 5. Convert raw balance with `decimals` field
> 6. Print as a table with columns: Chain, Token, Balance, USD-estimate

---

## Address Label

### Overview
Look up the label, name, or social profile associated with an address. Uses PharosScan's social graph API for Pharos chains, and falls back to public tag databases (Etherscan labels, OpenSea collections, ENS).

### Command Template
```bash
./scripts/indexer label <address>
```

### For Pharos chains (SocialScan)
```bash
curl -s "https://api.socialscan.io/pharos-atlantic-testnet/social/label/<address>"
```

### For Etherscan-compatible chains
```bash
# Etherscan account endpoint (returns any verified labels)
curl -s "https://api.etherscan.io/api?module=account&action=txlist&address=<addr>&apikey=<key>"
# (labels are inferred from contract names / verified contracts)
```

### Parameters
| Parameter | Type | Required | Description |
|---|---|---|---|
| address | address | Yes | The address to label |

### Output
| Field | Description |
|---|---|
| chain | Chain where the label was found |
| label | Human-readable label or social name |
| source | Source (PharosScan social, ENS, verified contract) |

### Error Handling
| Error | Cause | Fix |
|---|---|---|
| 404 from SocialScan | Address has no label on that chain | Return "No label found" |
| API key required | Etherscan endpoint needs API key | Set `ETHERSCAN_API_KEY` env var or skip |

> **Agent Guidelines**:
> 1. For Pharos chains: call `/social/label/<addr>` on the SocialScan API
> 2. For Etherscan chains: check if the address is a verified contract (has a name)
> 3. For any chain: try reverse-ENS lookup if available
> 4. Return the first label found, or "No label found"
> 5. Cite the source

---

## Contract Verification

### Overview
Check whether a contract at a given address is verified (source code published) on any chain's explorer. Returns yes/no + the explorer link.

### Command Template
```bash
./scripts/indexer verify <contract-address>
```

### Manual
```bash
# Pharos chains
curl -s "https://api.socialscan.io/pharos-atlantic-testnet?module=contract&action=getsourcecode&address=<addr>"

# Etherscan-compatible
curl -s "https://api.etherscan.io/api?module=contract&action=getsourcecode&address=<addr>"
```

### Parameters
| Parameter | Type | Required | Description |
|---|---|---|---|
| address | address | Yes | Contract address to check |
| chain | string | No | Single chain to check; omit for "auto-detect" |

### Output
| Field | Description |
|---|---|
| chain | Chain where verified |
| verified | `true` or `false` |
| sourceUrl | Link to the verified source on the explorer |

### Error Handling
| Error | Cause | Fix |
|---|---|---|
| `Contract source code not verified` | Not verified on that chain | Return `verified: false`; try other chains |
| API error | Rate limit or missing key | Wait and retry, or set API key |

> **Agent Guidelines**:
> 1. Read `assets/networks.json`
> 2. For each chain with an `explorerApiUrl`, call the `getsourcecode` endpoint
> 3. Return the first chain where `verified: true`
> 4. If no chain has verification, return `verified: false` on all chains
> 5. Include the explorer source URL when verified

---

## End-to-End Example (3 commands)

```bash
# 1. Check balances across all chains
./scripts/indexer balance 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266

# 2. Look up where a transaction is
./scripts/indexer tx 0x33a1600e7caccbba921526c3fd9dc23ea5e836f7c7f77f89c0a7ef3b55fe1906

# 3. Get the full portfolio
./scripts/indexer portfolio 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
```
