# Claude Code — Pharos Cross-Chain Indexer

This skill is auto-discovered by Claude Code via `activation.triggers` in `SKILL.md`.

## Install

```bash
gh skill install antidumpalways/pharos-crosschain-indexer
```

Or manually:
```bash
git clone https://github.com/antidumpalways/pharos-crosschain-indexer ~/.claude/skills/pharos-crosschain-indexer
cd ~/.claude/skills/pharos-crosschain-indexer && bash install.sh
```

## Usage in Claude Code

Start Claude Code in any project directory with the skill installed:

```
> Check my balance on all chains
> Analyze my portfolio across 112 chains
> Show Vitalik's full portfolio with ERC-20 tokens
> Compare gas prices — where's cheapest to transact?
> Export my portfolio to CSV
> Monitor my wallet and alert me on balance changes
```

Claude Code reads `SKILL.md` -> `activation.triggers` -> `Capability Index` -> executes the right command.

## Windows note

The indexer is a **bash** script. On Windows, run Claude Code from **Git Bash**
or **WSL** and always invoke with the `bash` prefix (`bash scripts/indexer ...`).
Without it, `./scripts/indexer` fails (no shebang exec on Windows) and Claude
may waste retries trying `python`/`./`. For the Python helpers, `python3` may be
called as `python` on Windows. This skill is read-only: no wallet, no gas, no
state changes.

## All 14 operations

> **Default scope = top 15 chains** (fast). Add `--all` only when the user
> explicitly asks for "all/every chain". Pick **one** command per intent — never
> run several speculatively. Form: `bash scripts/indexer <cmd>` or
> `python3 scripts/<name>.py`.

| Trigger phrase | Command executed |
|---|---|
| "balance on all chains" | `bash scripts/indexer bal <addr>` |
| "where is this tx" | `bash scripts/indexer tx <hash>` |
| "show my portfolio" | `python3 scripts/multi.py <addr>` |
| "who is this address" | `bash scripts/indexer lab <addr>` |
| "is this verified" | `bash scripts/indexer ver <contract>` |
| "which chains are online" | `bash scripts/indexer health` |
| "compare gas prices" | `bash scripts/indexer gas` |
| "rank chains by USDC" | `bash scripts/indexer top <addr> USDC` |
| "analyze my portfolio" | `python3 scripts/suggest.py <addr>` |
| "export portfolio" | `python3 scripts/export.py <addr> csv\|html` |
| "snapshot my balance" | `python3 scripts/diff.py save <addr>` |
| "compare balance changes" | `python3 scripts/diff.py diff <addr>` |
| "track balance history" | `python3 scripts/history.py record <addr>` |
| "alert me" | `python3 scripts/alert.py <addr>` |
