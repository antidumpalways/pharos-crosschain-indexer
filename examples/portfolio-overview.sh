#!/usr/bin/env bash
# examples/portfolio-overview.sh â€” Demo: full portfolio across all chains
# Usage: bash examples/portfolio-overview.sh <address>
set -euo pipefail

ADDR="${1:-0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INDEXER="$SCRIPT_DIR/../scripts/indexer"

echo "â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•"
echo "  Pharos Cross-Chain Indexer â€” Portfolio Demo"
echo "â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•"
echo ""
echo "Address: $ADDR"
echo ""

# 1. Full portfolio
bash "$INDEXER" portfolio "$ADDR"
echo ""

# 2. Try to label the address
bash "$INDEXER" label "$ADDR"
echo ""

# 3. Check if there are any recent transactions
echo "â”€â”€ Cross-chain tx check (latest known) â”€â”€"
echo "  (use the tx command with a known tx hash)"
echo ""

echo "â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•"
echo "  Done. Try your own address:"
echo "  bash examples/portfolio-overview.sh 0xYOUR_ADDRESS"
echo "â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•"
