#!/usr/bin/env bash
# install.sh — Install pharos-crosschain-indexer
# Works on: Linux, macOS, Windows (Git Bash / WSL)
# Usage: bash install.sh
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "================================================================"
echo "  Pharos Cross-Chain Indexer v0.1.0 — Install"
echo "================================================================"
echo ""

# Detect OS for package-manager hints
OS="linux"
if [[ "$OSTYPE" == "darwin"* ]]; then OS="macos"; fi
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then OS="windows"; fi
echo "  Detected OS: $OS"
echo ""

# Check dependencies
MISSING=""

if ! command -v curl &>/dev/null; then
    echo "  [MISSING] curl"
    MISSING="$MISSING curl"
else
    echo "  [OK] curl"
fi

if ! command -v jq &>/dev/null; then
    echo "  [MISSING] jq"
    case "$OS" in
        linux)   echo "    Install: sudo apt-get install jq";;
        macos)   echo "    Install: brew install jq";;
        windows) echo "    Install: winget install jqlang.jq OR choco install jq";;
    esac
    MISSING="$MISSING jq"
else
    echo "  [OK] jq ($(jq --version 2>&1))"
fi

if command -v cast &>/dev/null; then
    echo "  [OK] cast (Foundry) — faster RPC queries enabled"
else
    echo "  [OPT] cast not found — falling back to curl for RPC (slower but works)"
    echo "    Install Foundry: curl -L https://foundry.paradigm.xyz | bash"
fi

if command -v python3 &>/dev/null; then
    echo "  [OK] python3 (fallback for RPC queries without cast)"
else
    echo "  [OPT] python3 not found — needed as fallback when cast is missing"
    case "$OS" in
        linux)   echo "    Install: sudo apt-get install python3";;
        macos)   echo "    python3 is pre-installed on macOS";;
        windows) echo "    Install: winget install Python.Python.3";;
    esac
fi

if [ -n "$MISSING" ]; then
    echo ""
    echo "  Missing dependencies: $MISSING"
    echo "  Install with your package manager and re-run: bash install.sh"
    exit 1
fi

# Make scripts executable
if [ -f "$SCRIPT_DIR/scripts/indexer" ]; then
    chmod +x "$SCRIPT_DIR/scripts/indexer" 2>/dev/null || true
    echo "  [OK] scripts/indexer executable"
fi

for f in "$SCRIPT_DIR/examples/"*.sh; do
    [ -f "$f" ] && chmod +x "$f" 2>/dev/null || true
done
echo "  [OK] examples executable"

# Quick self-test (Atlantic testnet balance)
echo ""
echo "  --- Quick self-test ---"
bash "$SCRIPT_DIR/scripts/indexer" balance 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 atlantic-testnet 2>/dev/null | head -6 || echo "  (skipped — run manually for verification)"

echo ""
echo "================================================================"
echo "  Installation complete"
echo "================================================================"
echo ""
echo "  Quick start:"
echo "    ./scripts/indexer help"
echo "    ./scripts/indexer balance 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045"
echo "    ./scripts/indexer portfolio 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
echo "    ./scripts/indexer health"
echo "    ./scripts/indexer gas"
echo ""
echo "  Demo scripts:"
echo "    bash examples/crosschain-balance.sh <address>"
echo "    bash examples/portfolio-overview.sh <address>"
echo ""
