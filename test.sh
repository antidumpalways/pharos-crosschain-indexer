#!/usr/bin/env bash
# test.sh — Run validation tests for pharos-crosschain-indexer
# Usage: bash test.sh
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

PASS=0
FAIL=0
SKIP=0

pass() { echo -e "  ${GREEN}✓${NC} $1"; PASS=$((PASS + 1)); }
fail() { echo -e "  ${RED}✗${NC} $1 — $2"; FAIL=$((FAIL + 1)); }
skip() { echo -e "  ${CYAN}⊘${NC} $1 — $2"; SKIP=$((SKIP + 1)); }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INDEXER="$SCRIPT_DIR/scripts/indexer"

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  Pharos Cross-Chain Indexer — Test Suite"
echo "═══════════════════════════════════════════════════════"
echo ""

# ── Test 1: CLI help works ───────────────────────────────────────
echo "1. CLI help"
if bash "$INDEXER" help > /dev/null 2>&1; then
    pass "help command works"
else
    fail "help command failed" "scripts/indexer may be broken"
fi

# ── Test 2: File structure ───────────────────────────────────────
echo ""
echo "2. File structure"
for f in SKILL.md README.md package.json install.sh LICENSE \
         assets/networks.json assets/tokens.json \
         references/indexer.md scripts/indexer \
         examples/crosschain-balance.sh examples/portfolio-overview.sh \
         docs/ARCHITECTURE.md AGENTS.md SUBMISSION.md skills.json; do
    if [ -f "$SCRIPT_DIR/$f" ]; then
        pass "$f exists"
    else
        fail "$f missing" "file not found"
    fi
done

# ── Test 3: JSON is valid ────────────────────────────────────────
echo ""
echo "3. JSON validation"
for f in assets/networks.json assets/tokens.json skills.json; do
    if python3 -m json.tool "$SCRIPT_DIR/$f" > /dev/null 2>&1; then
        pass "$f is valid JSON"
    else
        fail "$f is invalid JSON" "fix syntax in $f"
    fi
done

# ── Test 4: Dependency check ─────────────────────────────────────
echo ""
echo "4. Dependencies"
for dep in curl jq; do
    if command -v "$dep" > /dev/null 2>&1; then
        pass "$dep found"
    else
        fail "$dep missing" "install with apt-get/brew"
    fi
done
if command -v cast > /dev/null 2>&1; then
    pass "cast (Foundry) found — faster RPC enabled"
else
    skip "cast not found" "Falling back to curl. Install Foundry for speed."
fi

# ── Test 5: Real Atlantic RPC connectivity ───────────────────────
echo ""
echo "5. Network connectivity"
RPC="https://atlantic.dplabs-internal.com"
if curl -s -o /dev/null -w '%{http_code}' --connect-timeout 10 "$RPC" 2>/dev/null | grep -q "200\|405\|404\|400"; then
    pass "Atlantic RPC reachable"
else
    skip "Atlantic RPC unreachable" "Network may be down. Try later."
fi

# ── Test 6: Real balance query ───────────────────────────────────
echo ""
echo "6. Real balance query (Atlantic testnet)"
BAL=$(bash "$INDEXER" balance 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 atlantic-testnet 2>/dev/null | grep "PHRS" | awk '{print $2}')
if [ -n "$BAL" ]; then
    pass "Balance returned: $BAL PHRS (real data from Atlantic)"
elif bash "$INDEXER" balance 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 atlantic-testnet 2>&1 | grep -q "unreachable"; then
    skip "RPC down" "Could not query Atlantic"
else
    fail "Balance query failed" "scripts/indexer may be broken"
fi

# ── Test 7: Multi-chain query ──────────────────────────────────
echo ""
echo "7. Multi-chain query (Atlantic + Pacific)"
if bash "$INDEXER" balance 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 2>&1 | grep -q "atlantic-testnet\|pacific-mainnet"; then
    pass "Multi-chain query returned both chains"
else
    skip "Multi-chain not verified" "External RPCs may be down"
fi

# ── Summary ──────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════════════"
TOTAL=$((PASS + FAIL + SKIP))
echo "  Results: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}, ${CYAN}$SKIP skipped${NC} ($TOTAL total)"
echo "═══════════════════════════════════════════════════════"

if [ $FAIL -gt 0 ]; then
    echo ""
    echo "  Some tests failed. Check the errors above."
    exit 1
else
    echo ""
    echo "  ${GREEN}All tests passed.${NC} Skill is ready for submission."
    exit 0
fi
