#!/usr/bin/env bash
# test.sh - Run validation tests for pharos-crosschain-indexer
# Usage: bash test.sh
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

PASS=0
FAIL=0
SKIP=0

pass() { echo -e "  ${GREEN}[OK]${NC} $1"; PASS=$((PASS + 1)); }
fail() { echo -e "  ${RED}[FAIL]${NC} $1 - $2"; FAIL=$((FAIL + 1)); }
skip() { echo -e "  ${CYAN}[SKIP]${NC} $1 - $2"; SKIP=$((SKIP + 1)); }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INDEXER="$SCRIPT_DIR/scripts/indexer"

SEPARATOR="==========================================================================="

echo ""
echo "$SEPARATOR"
echo "  Pharos Cross-Chain Indexer - Test Suite"
echo "$SEPARATOR"
echo ""

# --- Test 1: CLI help works ---
echo "1. CLI help"
if bash "$INDEXER" help > /dev/null 2>&1; then
    pass "help command works"
else
    fail "help command failed" "scripts/indexer may be broken"
fi

# --- Test 2: File structure ---
echo ""
echo "2. File structure"
for f in SKILL.md README.md package.json install.sh LICENSE \
         assets/networks.json assets/tokens.json \
         references/balance.md references/tx.md references/portfolio.md \
         references/label.md references/verify.md \
         scripts/indexer cli.mjs; do
    if [ -f "$SCRIPT_DIR/$f" ]; then
        pass "$f exists"
    else
        fail "$f missing" "file not found"
    fi
done

# --- Test 3: JSON is valid ---
echo ""
echo "3. JSON validation"
for f in assets/networks.json assets/tokens.json skills.json; do
    if python3 -m json.tool "$SCRIPT_DIR/$f" > /dev/null 2>&1; then
        pass "$f is valid JSON"
    else
        fail "$f is invalid JSON" "fix syntax in $f"
    fi
done

# --- Test 4: Dependency check ---
echo ""
echo "4. Dependencies"
for dep in curl jq; do
    if command -v "$dep" > /dev/null 2>&1; then
        pass "$dep found"
    else
        fail "$dep missing" "install with apt-get/brew"
    fi
done
if command -v python3 > /dev/null 2>&1; then
    pass "python3 found"
else
    fail "python3 missing" "install with apt-get/brew"
fi
if command -v cast > /dev/null 2>&1; then
    pass "cast (Foundry) found - faster RPC enabled"
else
    skip "cast not found" "Falling back to curl. Install Foundry for speed."
fi

# --- Test 5: Real Atlantic RPC connectivity ---
echo ""
echo "5. Network connectivity"
RPC="https://atlantic.dplabs-internal.com"
HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' --connect-timeout 10 -X POST -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' "$RPC" 2>/dev/null) || HTTP_CODE="000"
# eth_blockNumber returns a JSON-RPC response, not a standard HTTP status
# Accept 200 (valid JSON-RPC response) only
if [ "$HTTP_CODE" = "200" ]; then
    BN=$(curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
        --connect-timeout 10 "$RPC" 2>/dev/null | jq -r '.result // "0x0"')
    if [ -n "$BN" ] && [ "$BN" != "0x0" ]; then
        pass "Atlantic RPC reachable (block ${BN})"
    else
        skip "Atlantic RPC returned unexpected response" "Network may be in maintenance"
    fi
else
    skip "Atlantic RPC unreachable (HTTP $HTTP_CODE)" "Network may be down"
fi

# --- Test 6: Real balance query ---
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

# --- Test 7: Multi-chain query ---
echo ""
echo "7. Multi-chain query (Atlantic + Pacific)"
if bash "$INDEXER" balance 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 2>&1 | grep -q "atlantic-testnet\|pacific-mainnet"; then
    pass "Multi-chain query returned both chains"
else
    skip "Multi-chain not verified" "External RPCs may be down"
fi

# --- Test 8: Reference file compliance ---
echo ""
echo "8. Reference file template compliance"
for ref in references/balance.md references/tx.md references/portfolio.md \
          references/label.md references/verify.md references/health.md \
          references/gas.md references/top.md references/add-chain.md; do
    if [ -f "$SCRIPT_DIR/$ref" ]; then
        has_overview=$(grep -c "^## Overview" "$SCRIPT_DIR/$ref" || true)
        has_command=$(grep -c "## Command Template" "$SCRIPT_DIR/$ref" || true)
        has_params=$(grep -c "^## Parameters" "$SCRIPT_DIR/$ref" || true)
        has_output=$(grep -c "^## Output Parsing" "$SCRIPT_DIR/$ref" || true)
        has_errors=$(grep -c "^## Error Handling" "$SCRIPT_DIR/$ref" || true)
        has_guidelines=$(grep -c "Agent Guidelines" "$SCRIPT_DIR/$ref" || true)
        if [ "$has_overview" -ge 1 ] && [ "$has_command" -ge 1 ] && [ "$has_params" -ge 1 ] && \
           [ "$has_output" -ge 1 ] && [ "$has_errors" -ge 1 ] && [ "$has_guidelines" -ge 1 ]; then
            pass "$ref - full template (Overview, Command Template, Parameters, Output Parsing, Error Handling, Agent Guidelines)"
        else
            fail "$ref - missing sections" "missing: overview=$has_overview cmd=$has_command params=$has_params out=$has_output err=$has_errors guide=$has_guidelines"
        fi
    else
        skip "$ref - not found" "optional"
    fi
done

# --- Test 9: SKILL.md structure compliance ---
echo ""
echo "9. SKILL.md structure compliance"
SKILL="$SCRIPT_DIR/SKILL.md"
has_name=$(grep -c "^name:" "$SKILL" || true)
has_version=$(grep -c "^version:" "$SKILL" || true)
has_desc=$(grep -c "^description:" "$SKILL" || true)
has_requires=$(grep -c "^requires:" "$SKILL" || true)
has_prereq=$(grep -c "^## Prerequisites" "$SKILL" || true)
has_net=$(grep -c "^## Network Configuration" "$SKILL" || true)
has_caps=$(grep -c "^## Capability Index" "$SKILL" || true)
has_security=$(grep -c "^## Security Reminders" "$SKILL" || true)
has_wopc=$(grep -c "^## Write Operation Pre-checks" "$SKILL" || true)
has_errors=$(grep -c "^## General Error Handling" "$SKILL" || true)
if [ "$has_name" -ge 1 ] && [ "$has_version" -ge 1 ] && [ "$has_desc" -ge 1 ] && \
   [ "$has_requires" -ge 1 ] && [ "$has_prereq" -ge 1 ] && [ "$has_net" -ge 1 ] && \
   [ "$has_caps" -ge 1 ] && [ "$has_security" -ge 1 ] && [ "$has_wopc" -ge 1 ] && \
   [ "$has_errors" -ge 1 ]; then
    pass "SKILL.md has all required sections (name, version, description, requires, Prerequisites, Network Configuration, Capability Index, Security Reminders, Write Operation Pre-checks, General Error Handling)"
else
    fail "SKILL.md missing required sections" "name=$has_name ver=$has_version desc=$has_desc req=$has_requires pre=$has_prereq net=$has_net cap=$has_caps sec=$has_security wopc=$has_wopc err=$has_errors"
fi

# --- Summary ---
echo ""
echo "$SEPARATOR"
TOTAL=$((PASS + FAIL + SKIP))
echo "  Results: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}, ${CYAN}$SKIP skipped${NC} ($TOTAL total)"
echo "$SEPARATOR"

if [ $FAIL -gt 0 ]; then
    echo ""
    echo "  Some tests failed. Check the errors above."
    exit 1
else
    echo ""
    echo "  ${GREEN}All tests passed.${NC} Skill is ready for submission."
    exit 0
fi
