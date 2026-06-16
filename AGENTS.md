# Agent Usage — Step-by-Step Examples

> **Target agents:** Claude Code, Gemini CLI, Cursor, OpenCode, Codex, Windsurf
> **Skill:** `pharos-crosschain-indexer` v0.1.0
> **Parent:** `pharos-skill-engine` (base)

---

## CRITICAL: Session Memory — Address Required

**This skill REQUIRES an address for most operations.** The agent MUST follow these rules:

1. **If no address provided** — ASK the user: "Which address should I look up? (0x...)"
2. **Once user provides an address** — REMEMBER it for the entire session. Do not ask again.
3. **If user says "my wallet" or "my portfolio"** — use the remembered address.
4. **If a different address is needed** — user will provide it explicitly.
5. **Never use a demo/fake address** — only use addresses the user has explicitly provided.

### Session memory pattern

```
User: "Check my balance on all chains"
Agent: "Which address should I look up? (0x...)"
User: "0xFF11f4Be26169166A4edb3290De7a0f7aF5D544c"
Agent: [executes balance query for 0xFF11f4Be...]
       [REMEMBERS: session_address = 0xFF11f4Be...]

User: "Now show my portfolio"
Agent: [uses remembered address 0xFF11f4Be... without asking again]
       [executes portfolio query]

User: "Compare gas prices"
Agent: [gas command doesn't need address, executes directly]

User: "Check Vitalik's balance too"
Agent: [uses the NEW address 0xd8dA6BF2... for this query]
       [BUT keeps 0xFF11f4Be... as session default for "my" queries]
```

---

## How the Agent Discovers This Skill

### Step 1 — Agent reads `SKILL.md`

When a user mentions "cross-chain", "balance everywhere", "portfolio", or any trigger phrase, the agent opens `SKILL.md`:

The agent sees:

```yaml
activation:
  triggers:
    - check my balance everywhere
    - balance on all chains
    - multi-chain balance
    - show my portfolio
    ...
```

Agent knows: "This is the cross-chain data skill. Trigger on any of these phrases."

### Step 2 — Agent reads `references/<operation>.md`

The `Capability Index` in `SKILL.md` points to specific sections:

| User Need | Capability | Detailed Instructions |
|---|---|---|
| "Check balance across all chains" | `pharos-indexer balance` | `references/balance.md` |
| "Show my full portfolio" | `pharos-indexer portfolio` | `references/portfolio.md` |

Agent opens the relevant reference file, finds the exact command template.

### Step 3 — Agent checks for address

Agent checks its session memory for the user's address. If not present, asks the user.

### Step 4 — Agent executes the command

Agent runs exactly what the reference says, with the user's real address.

---

## Real Conversation Examples

### Example 1 — First Query (No Address Yet)

```
User: "Check my balance on every chain"

Agent:
  • Reads SKILL.md -> trigger: "balance on all chains"
  • No address in session memory
  • Asks: "Which address should I look up? (0x...)"

User: "0xFF11f4Be26169166A4edb3290De7a0f7aF5D544c"

Agent:
  • Saves to session: user_address = 0xFF11f4Be...
  • Reads references/balance.md -> command template
  • Executes: ./scripts/indexer bal 0xFF11f4Be...

  Atlantic testnet    0.0 PHRS
  Pacific mainnet     0.0 PROS
  Sepolia             0.0 ETH
  ... (112 chains total)

  No balance on any chain. Need gas? Apply the Atlantic faucet.
```

### Example 2 — Portfolio (Address Remembered)

```
User: "Show my full portfolio"

Agent:
  • Reads SKILL.md -> trigger: "show my portfolio"
  • Has session address: 0xFF11f4Be...
  • Executes: python3 scripts/multi.py 0xFF11f4Be...

  Chain          Token    Balance
  ───────────────────────────────
  (shows all native + ERC-20 tokens)
```

### Example 3 — Different Address (Explicit Override)

```
User: "Now check Vitalik's portfolio"

Agent:
  • "my" portfolio = session default (0xFF11f4Be...)
  • "Vitalik's" = explicit different address (0xd8dA6BF2...)
  • Keeps both in context
  • Executes: python3 scripts/multi.py 0xd8dA6BF2...

  ethereum-sepolia    58.24 ETH
  ethereum-sepolia   800.27 USDC
  blast-sepolia    18006.95 ETH
  ...
```

---

## Agent Trigger Phrases

The agent should load `pharos-crosschain-indexer` when the user says ANY of:

| Trigger phrase | Maps to |
|---|---|
| "check balance on all chains" / "balance everywhere" | `indexer bal` |
| "show my portfolio" / "all tokens" | `python3 scripts/multi.py` |
| "where is this transaction" / "find tx" | `indexer tx` |
| "who is this address" / "label" | `indexer lab` |
| "is this verified" / "verify contract" | `indexer ver` |
| "which chains are online" / "network status" | `indexer health` |
| "compare gas prices" / "cheapest chain" | `indexer gas` |
| "rank chains by USDC" / "top token" | `indexer top` |
| "analyze my portfolio" / "suggest actions" | `python3 scripts/suggest.py` |
| "export portfolio" / "generate report" | `python3 scripts/export.py` |
| "snapshot my balance" / "record state" | `python3 scripts/diff.py save` |
| "compare balance" / "what changed" | `python3 scripts/diff.py diff` |
| "track history" / "balance over time" | `python3 scripts/history.py` |
| "alert me" / "monitor wallet" | `python3 scripts/alert.py` |

## Agent Pre-checks (Before Executing)

1. **Address check** — If the operation needs an address AND none is in session memory AND user didn't provide one → ASK. Do not proceed without an address.
2. **Dependency check** — `which jq`. If missing, tell user to `apt-get install jq`.
3. **Network check** — `bash test.sh` to verify connectivity.
4. **Session memory** — After first address query, remember it. Use `session_address` in context.

## Agent Error Handling

| Situation | Agent Response |
|---|---|
| User says "my balance" but no address provided | "Which address should I look up? (0x...)" |
| User says "my portfolio" with remembered address | Use the remembered address silently |
| User provides a different address mid-session | Use the new address but keep old as default |
| `No balance found` | "No balance on any chain. If you expected funds, check the address." |
| `Transaction not found` | "Tx not found on any indexed chain." |
| `cast: command not found` | "Falling back to curl (slightly slower). Install Foundry for speed." |

## Session Context Example

```json
{
  "session_address": "0xFF11f4Be26169166A4edb3290De7a0f7aF5D544c",
  "session_chain_preference": "atlantic-testnet",
  "last_operation": "balance",
  "known_addresses": {
    "vitalik": "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045",
    "treasury": "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
  }
}
```
