#!/usr/bin/env bash
# examples/crosschain-balance.sh — Demo: multi-chain balance lookup
# Usage: bash examples/crosschain-balance.sh <address>
set -euo pipefail

ADDR="${1:-0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INDEXER="$SCRIPT_DIR/../scripts/indexer"

echo "═══════════════════════════════════════════════════════"
echo "  Pharos Cross-Chain Indexer — Balance Demo"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "Address: $ADDR"
echo ""

# 1. Multi-chain native balance
echo "── 1. Native balance across all chains ──"
bash "$INDEXER" balance "$ADDR"
echo ""

# 2. Atlantic-specific
echo "── 2. Atlantic testnet only ──"
bash "$INDEXER" balance "$ADDR" atlantic-testnet
echo ""

echo "═══════════════════════════════════════════════════════"
echo "  Done. Try your own address:"
echo "  bash examples/crosschain-balance.sh 0xYOUR_ADDRESS"
echo "═══════════════════════════════════════════════════════"
