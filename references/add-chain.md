# Add a Chain to the Indexer

> **Skill**: pharos-crosschain-indexer
> **This is a configuration operation** — the agent edits `assets/networks.json` and `assets/tokens.json`. No RPC calls needed.

---

## Overview

The cross-chain indexer auto-discovers chains from `assets/networks.json`. To add a new chain, the agent appends a JSON entry to the `networks` array. If the chain has known ERC-20 tokens, optionally add them to `assets/tokens.json`.

After adding, run `bash test.sh` to verify the new chain queries correctly.

---

## Chain Entry Format

Add this to the `"networks"` array in `assets/networks.json`:

```json
{
  "name": "<chain-name>",
  "rpcUrl": "<rpc-url>",
  "chainId": <chain-id-integer>,
  "explorerUrl": "<explorer-url>",
  "explorerApiUrl": "<explorer-api-url>",
  "nativeToken": "<SYMBOL>",
  "type": "<pharos|etherscan|blockscout|zksync>"
}
```

### Parameters

| Parameter | Type | Required | Description |
|---|---|---|---|
| `name` | string | Yes | Unique kebab-case name — used as filter in `--chain` flag |
| `rpcUrl` | string | Yes | Public RPC endpoint |
| `chainId` | integer | Yes | EVM chain ID |
| `explorerUrl` | string | No | Human-facing explorer URL |
| `explorerApiUrl` | string | Yes | Explorer API base URL (for tx, label, verify queries) |
| `nativeToken` | string | Yes | Symbol of native gas token (ETH, MATIC, BNB, etc.) |
| `type` | string | Yes | `pharos` for Pharos chains, `etherscan` for Etherscan-compatible, `blockscout`, or `zksync` |

### Common Chain Configurations (copy-paste ready)

#### Optimism Mainnet
```json
{ "name": "optimism", "rpcUrl": "https://mainnet.optimism.io", "chainId": 10, "explorerUrl": "https://optimistic.etherscan.io/", "explorerApiUrl": "https://api-optimistic.etherscan.io/api", "nativeToken": "ETH", "type": "etherscan" }
```

#### Polygon Mainnet
```json
{ "name": "polygon", "rpcUrl": "https://polygon-rpc.com", "chainId": 137, "explorerUrl": "https://polygonscan.com/", "explorerApiUrl": "https://api.polygonscan.com/api", "nativeToken": "POL", "type": "etherscan" }
```

#### BSC Mainnet
```json
{ "name": "bsc", "rpcUrl": "https://bsc-dataseed.bnbchain.org", "chainId": 56, "explorerUrl": "https://bscscan.com/", "explorerApiUrl": "https://api.bscscan.com/api", "nativeToken": "BNB", "type": "etherscan" }
```

#### Avalanche C-Chain
```json
{ "name": "avalanche", "rpcUrl": "https://api.avax.network/ext/bc/C/rpc", "chainId": 43114, "explorerUrl": "https://snowtrace.io/", "explorerApiUrl": "https://api.snowtrace.io/api", "nativeToken": "AVAX", "type": "etherscan" }
```

#### Fantom
```json
{ "name": "fantom", "rpcUrl": "https://rpcapi.fantom.network", "chainId": 250, "explorerUrl": "https://ftmscan.com/", "explorerApiUrl": "https://api.ftmscan.com/api", "nativeToken": "FTM", "type": "etherscan" }
```

#### Gnosis Mainnet
```json
{ "name": "gnosis", "rpcUrl": "https://rpc.gnosischain.com", "chainId": 100, "explorerUrl": "https://gnosisscan.io/", "explorerApiUrl": "https://api.gnosisscan.io/api", "nativeToken": "XDAI", "type": "etherscan" }
```

#### Moonbeam
```json
{ "name": "moonbeam", "rpcUrl": "https://rpc.api.moonbeam.network", "chainId": 1284, "explorerUrl": "https://moonscan.io/", "explorerApiUrl": "https://api-moonbeam.moonscan.io/api", "nativeToken": "GLMR", "type": "etherscan" }
```

#### Celo Mainnet
```json
{ "name": "celo", "rpcUrl": "https://forno.celo.org", "chainId": 42220, "explorerUrl": "https://celoscan.io/", "explorerApiUrl": "https://api.celoscan.io/api", "nativeToken": "CELO", "type": "etherscan" }
```

#### Scroll Mainnet
```json
{ "name": "scroll", "rpcUrl": "https://rpc.scroll.io", "chainId": 534352, "explorerUrl": "https://scrollscan.com/", "explorerApiUrl": "https://api.scrollscan.com/api", "nativeToken": "ETH", "type": "etherscan" }
```

#### Linea Mainnet
```json
{ "name": "linea", "rpcUrl": "https://rpc.linea.build", "chainId": 59144, "explorerUrl": "https://lineascan.build/", "explorerApiUrl": "https://api.lineascan.build/api", "nativeToken": "ETH", "type": "etherscan" }
```

---

## How the Agent Adds a Chain

### Step 1 — Append to `assets/networks.json`

Use `jq` to add an entry to the `networks` array:

```bash
# Add Optimism Mainnet
jq '.networks += [{
  "name": "optimism",
  "rpcUrl": "https://mainnet.optimism.io",
  "chainId": 10,
  "explorerUrl": "https://optimistic.etherscan.io/",
  "explorerApiUrl": "https://api-optimistic.etherscan.io/api",
  "nativeToken": "ETH",
  "type": "etherscan"
}]' assets/networks.json > /tmp/networks.json && mv /tmp/networks.json assets/networks.json
```

### Step 2 — Optionally add tokens

If the chain has known ERC-20 contracts, add them to the appropriate network key in `assets/tokens.json`:

```bash
# Add USDC on Optimism
jq '.optimism = [{
  "symbol": "USDC",
  "name": "USD Coin",
  "decimals": 6,
  "address": "0x0b2C639c533813f4Aa9D7837CAf62653d097Ff85"
}]' assets/tokens.json > /tmp/tokens.json && mv /tmp/tokens.json assets/tokens.json
```

### Step 3 — Verify

```bash
# Test the new chain works
./scripts/indexer balance <address> <chain-name>

# Or run full test suite
bash test.sh
```

---

## Removing a Chain

```bash
jq 'del(.networks[] | select(.name == "<chain-name>"))' assets/networks.json > /tmp/networks.json && mv /tmp/networks.json assets/networks.json
```

---

## Error Handling

| Error | Cause | Fix |
|---|---|---|
| `json: parse error` | JSON syntax error in the added entry | Validate with `python3 -m json.tool assets/networks.json` |
| `(unreachable)` after adding | RPC URL wrong or unreachable | Check RPC URL at https://chainlist.org |
| Chain not appearing in output | `name` field mismatch | Verify name matches what you used in `--chain` flag |
| Explorer queries fail | Wrong `explorerApiUrl` | Verify at the chain's block explorer docs |

> **Agent Guidelines**:
> 1. Ask the user which chain they want to add (name + mainnet/testnet)
> 2. Look up the correct chain ID, RPC URL, and explorer API URL
> 3. Append the entry to `assets/networks.json` using `jq` (single command)
> 4. If tokens are known, also add to `assets/tokens.json`
> 5. Run `python3 -m json.tool assets/networks.json` to validate JSON
> 6. Test with `./scripts/indexer balance <address> <new-chain-name>`
> 7. Tell the user the chain is added and ready
