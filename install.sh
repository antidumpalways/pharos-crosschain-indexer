#!/usr/bin/env bash
# install.sh — Install pharos-crosschain-indexer
# Usage: bash install.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  Pharos Cross-Chain Indexer v0.1.0 — Install"
echo "═══════════════════════════════════════════════════════"
echo ""

# Check dependencies
MISSING=""

if ! command -v curl &>/dev/null; then
    echo "  ✗ curl not found"
    MISSING="$MISSING curl"
else
    echo "  ✓ curl"
fi

if ! command -v jq &>/dev/null; then
    echo "  ✗ jq not found — install with: apt-get install jq / brew install jq"
    MISSING="$MISSING jq"
else
    echo "  ✓ jq"
fi

if command -v cast &>/dev/null; then
    echo "  ✓ cast (Foundry) — faster RPC queries enabled"
else
    echo "  ⚠ cast not found — falling back to curl for RPC (slightly slower)"
    echo "    Install Foundry for better performance: curl -L https://foundry.paradigm.xyz | bash"
fi

if [ -n "$MISSING" ]; then
    echo ""
    echo "  Missing: $MISSING"
    echo "  Install with your package manager and re-run bash install.sh"
    exit 1
fi

# Make indexer executable
if [ -f "$SCRIPT_DIR/scripts/indexer" ]; then
    chmod +x "$SCRIPT_DIR/scripts/indexer"
    echo "  ✓ scripts/indexer executable"
fi

# Make examples executable
for f in "$SCRIPT_DIR/examples/"*.sh; do
    [ -f "$f" ] && chmod +x "$f"
done
echo "  ✓ examples executable"

# Quick self-test
echo ""
echo "  ── Quick self-test ──"
bash "$SCRIPT_DIR/scripts/indexer" balance 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 atlantic-testnet 2>/dev/null | head -5 || true

echo ""
echo "═══════════════════════════════════════════════════════"
echo "  ✅ Installation complete"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "  Quick start:"
echo "    ./scripts/indexer help"
echo "    ./scripts/indexer balance 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045"
echo "    ./scripts/indexer portfolio 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
echo ""
echo "  Demo scripts:"
echo "    bash examples/crosschain-balance.sh <address>"
echo "    bash examples/portfolio-overview.sh <address>"
echo ""
