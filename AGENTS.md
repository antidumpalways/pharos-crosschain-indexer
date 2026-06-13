# Agent Usage — Step-by-Step Examples

> **Target agents:** Claude Code, Cursor, OpenCode, Hermes Agent, Codex, Windsurf  
> **Skill:** `pharos-crosschain-indexer` v0.1.0  
> **Parent:** `pharos-skill-engine` (base)

---

## How the Agent Discovers This Skill

### Step 1 — Agent reads `SKILL.md`

When a user mentions "cross-chain", "balance everywhere", "portfolio", or any trigger phrase, the agent opens `SKILL.md`:

```
$ cat SKILL.md
```

The agent sees:

```yaml
---
name: pharos-crosschain-indexer
description: >
  REQUIRED for any multi-chain data query on Pharos. This skill adds 5 cross-chain
  query capabilities on top of pharos-skill-engine: multi-chain balance lookup,
  cross-chain transaction tracking, portfolio overview, address labeling, and
  contract verification across 15 EVM chains.
---
```

👉 Agent knows: "This is the cross-chain data skill. Trigger on balance/portfolio/tx/chain queries."

### Step 2 — Agent reads `references/indexer.md`

The `Capability Index` in `SKILL.md` points to specific sections:

| User Need | Capability | Detailed Instructions |
|---|---|---|
| "Check balance across all chains" | `pharos-indexer balance` | → `references/indexer.md#multi-chain-balance` |
| "Show my full portfolio" | `pharos-indexer portfolio` | → `references/indexer.md#portfolio-overview` |

Agent opens `references/indexer.md`, finds the exact command template:

```md
### Command Template
./scripts/indexer balance <address>
```

### Step 3 — Agent executes the command

Agent runs exactly what the reference says:

```bash
./scripts/indexer balance 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045
```

Agent reads output, formats it for the user, returns.

---

## Real Conversation Examples

### Example 1 — Multi-Chain Balance

```
👤 User: "Check my balance on every chain"

🤖 Agent:
  • Reads pharos-crosschain-indexer/SKILL.md
  • Capability Index → "Check balance across all chains" → references/indexer.md#balance
  • Reads balance section → command template
  • Executes: ./scripts/indexer balance 0xUSER_ADDRESS

╔══════════════════════════════════════╗
║  Multi-Chain Balance                 ║
╠══════════════════════════════════════╣
║  Address: 0xF39F...2266              ║
╚══════════════════════════════════════╝

  atlantic-testnet    14.9555 PHRS
  pacific-mainnet      0.0    PROS
  ethereum-sepolia     0.0    ETH
  base-sepolia         0.0    ETH
  arbitrum-sepolia     0.0    ETH
  optimism-sepolia     0.0    ETH
  polygon-amoy         0.0    POL
  bsc-testnet          0.0    BNB
  avalanche-fuji       0.0    AVAX
  scroll-sepolia       0.0    ETH
  linea-sepolia        0.0    ETH
  blast-sepolia        0.0    ETH
  celo-alfajores       0.0    CELO
  gnosis-chiado        0.0    XDAI
  zksync-sepolia       0.0    ETH

  📡 Queried 15 chains. You have PHRS on Atlantic.
```

### Example 2 — Full Portfolio

```
👤 User: "Show me everything I own everywhere"

🤖 Agent:
  • Reads SKILL.md → Capability Index → "Show my full portfolio"
  • Executes: ./scripts/indexer portfolio 0xUSER_ADDRESS
  • (Agent queries native balance + all ERC-20 tokens on all 15 chains)

  Chain             Token    Balance
  ────────────────────────────────────
  atlantic-testnet   PHRS     14.9555
  atlantic-testnet   USDC   5000.0000
  atlantic-testnet   WETH      2.0000
  pacific-mainnet    PROS    250.0000
  pacific-mainnet    USDC   1000.0000

  💡 Most of your assets are on Atlantic. Consider bridging
     USDC to Pacific if you need it there for x402 payments.
```

### Example 3 — Cross-Chain Tx Lookup

```
👤 User: "Where is transaction 0x33a1600e7caccbba921526c3fd9dc23ea5e836f7c7f77f89c0a7ef3b55fe1906?"

🤖 Agent:
  • Reads references/indexer.md#tx-lookup
  • Executes: ./scripts/indexer tx 0x33a1600e7caccbba921526c3fd9dc23ea5e836f7c7f77f89c0a7ef3b55fe1906
  • Agent queries every explorer API sequentially until found

  ✓ Found on arbitrum-sepolia — block 12345678
    https://sepolia.arbiscan.io/tx/0x33a1...

  This tx is on Arbitrum Sepolia (not Pharos). Status: confirmed.
```

### Example 4 — Address Label

```
👤 User: "Who is 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045?"

🤖 Agent:
  • Reads references/indexer.md#label
  • Executes: ./scripts/indexer label 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045
  • Agent queries PharosScan social graph + Etherscan labels

  vitalik.eth [ENS] — ethereum (Etherscan)
```

### Example 5 — Contract Verification

```
👤 User: "Is this contract verified? 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512"

🤖 Agent:
  • Reads references/indexer.md#verify
  • Executes: ./scripts/indexer verify 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512

  Contract not verified on any indexed chain.
```

---

## Agent Trigger Phrases

The agent should load `pharos-crosschain-indexer` when the user says ANY of:

| Trigger phrase | Maps to |
|---|---|
| "check balance on all chains" / "balance everywhere" | `indexer balance` |
| "multi-chain" / "cross-chain" / "every chain" | `indexer balance` |
| "portfolio" / "all my tokens" / "what do I own" | `indexer portfolio` |
| "where is this transaction" / "find tx" / "tx lookup" | `indexer tx` |
| "who is this address" / "label" / "identity" | `indexer label` |
| "verified contract" / "is this verified" / "check source" | `indexer verify` |
| "Pharos Atlantic" / "Pharos Pacific" + "balance" | `indexer balance` |
| "Sepolia" / "Amoy" / "Fuji" / "Alfajores" / "Chiado" (any chain name) | `indexer balance <chain-name>` |

## Agent Pre-checks (Before Executing)

The agent MUST verify these before calling any `scripts/indexer` command:

1. **Dependency check** — run `which jq`. If missing, tell the user to `apt-get install jq`.
2. **Network connectivity** — run `curl -s https://atlantic.dplabs-internal.com -o /dev/null -w '%{http_code}'`. If not 200, warn user that Atlantic RPC may be down.
3. **Skill installed** — the agent is already in the `pharos-crosschain-indexer/` directory. If not, run `git clone` first.

## Agent Error Handling

| Error from `scripts/indexer` | Agent tells user |
|---|---|
| `jq: command not found` | "jq not installed. Run: `apt-get install jq` or `brew install jq`" |
| `No balance found` | "No balance on any chain. If you expected funds, check the address." |
| `Transaction not found` | "Tx not found on any indexed chain. It may still be pending, or on a chain not in networks.json." |
| `No label found` | "No public label on any indexed chain." |
| `(unreachable)` next to a chain | "Chain `<name>` is currently unreachable. The RPC may be down." |
| `cast: command not found` | "`cast` not installed. Falling back to `curl` (slightly slower)." |

## Agent Composability Hints

After running a cross-chain query, the agent should suggest next actions:

| Query result | Suggested next action |
|---|---|
| "You have 5000 USDC on Atlantic" | "Want me to bridge some to Pacific via `pharos-bridge-cctp`?" |
| "You have 0 PHRS on Atlantic" | "Need gas? Apply the Atlantic faucet." |
| "Not verified on any chain" | "Need me to verify this contract using `forge verify-contract`?" |
| "Found on arbitrum-sepolia" | "Want me to check the receipt on `pharos-explorer`?" |
