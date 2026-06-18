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
        windows)
            # On Git Bash, auto-install jq to $HOME/bin for portability
            JQ_DEST="$HOME/bin/jq.exe"
            JQ_URL="https://github.com/jqlang/jq/releases/download/jq-1.7.1/jq-win64.exe"
            if [ ! -x "$JQ_DEST" ]; then
                mkdir -p "$HOME/bin" 2>/dev/null || true
                if command -v curl &>/dev/null; then
                    echo "    Auto-downloading jq to $JQ_DEST ..."
                    if curl -sSL -o "$JQ_DEST" "$JQ_URL" && [ -s "$JQ_DEST" ]; then
                        echo "    [OK] jq auto-installed at $JQ_DEST"
                        echo "    Tip: add $HOME/bin to your PATH:  export PATH=\"\$HOME/bin:\$PATH\""
                        MISSING=""  # rescued
                        # Make it available for this session
                        export PATH="$HOME/bin:$PATH"
                    else
                        echo "    Install: winget install jqlang.jq OR choco install jq"
                        MISSING="$MISSING jq"
                    fi
                else
                    echo "    Install: winget install jqlang.jq OR choco install jq"
                    MISSING="$MISSING jq"
                fi
            fi
            ;;
    esac
else
    echo "  [OK] jq ($(jq --version 2>&1))"
fi

if command -v cast &>/dev/null; then
    echo "  [OK] cast (Foundry) — faster RPC queries enabled"
else
    echo "  [OPT] cast not found — falling back to curl for RPC (slower but works)"
    echo "    Install Foundry: curl -L https://foundry.paradigm.xyz | bash"
fi

if command -v python &>/dev/null; then
    echo "  [OK] python (fallback for RPC queries without cast)"
else
    echo "  [OPT] python not found — needed as fallback when cast is missing"
    case "$OS" in
        linux)   echo "    Install: sudo apt-get install python";;
        macos)   echo "    python is pre-installed on macOS";;
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

# Quick self-test (indexer help — no address needed, just proves bash + jq + python work)
echo ""
echo "  --- Quick self-test ---"
bash "$SCRIPT_DIR/scripts/indexer" help 2>&1 | head -6 || echo "  (skipped — run manually for verification)"

echo ""
echo "================================================================"
echo "  Installation complete"
echo "================================================================"
echo ""
echo "  Quick start (replace <YOUR_ADDRESS> with your 0x... address):"
echo "    bash scripts/indexer help"
echo "    bash scripts/indexer balance <YOUR_ADDRESS>"
echo "    bash scripts/indexer portfolio <YOUR_ADDRESS>"
echo "    bash scripts/indexer health"
echo "    bash scripts/indexer gas"
echo ""
echo "  On Windows (Git Bash), if 'jq' is missing, ensure \$HOME/bin is on PATH:"
echo "    export PATH=\"\$HOME/bin:\$PATH\""
echo ""
echo "  Demo scripts:"
echo "    bash examples/crosschain-balance.sh <address>"
echo "    bash examples/portfolio-overview.sh <address>"
echo ""
