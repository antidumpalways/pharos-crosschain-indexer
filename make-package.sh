#!/usr/bin/env bash
# make-package.sh â€” Create distributable zip for pharos-crosschain-indexer
# Usage: bash make-package.sh
# Output: pharos-crosschain-indexer-v0.1.0.zip
set -euo pipefail

VERSION="${1:-v0.1.0}"
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
PKG_NAME="pharos-crosschain-indexer-${VERSION}"
OUTPUT="${ROOT_DIR}/${PKG_NAME}.zip"
TEMP_DIR="$(mktemp -d)"

echo "Packaging ${PKG_NAME}..."

# Copy files to temp
mkdir -p "${TEMP_DIR}/${PKG_NAME}/assets"
mkdir -p "${TEMP_DIR}/${PKG_NAME}/references"
mkdir -p "${TEMP_DIR}/${PKG_NAME}/scripts"
mkdir -p "${TEMP_DIR}/${PKG_NAME}/examples"
mkdir -p "${TEMP_DIR}/${PKG_NAME}/docs"

cp "${ROOT_DIR}/SKILL.md"        "${TEMP_DIR}/${PKG_NAME}/"
cp "${ROOT_DIR}/README.md"       "${TEMP_DIR}/${PKG_NAME}/"
cp "${ROOT_DIR}/SUBMISSION.md"   "${TEMP_DIR}/${PKG_NAME}/"
cp "${ROOT_DIR}/install.sh"      "${TEMP_DIR}/${PKG_NAME}/"
cp "${ROOT_DIR}/assets/networks.json"  "${TEMP_DIR}/${PKG_NAME}/assets/"
cp "${ROOT_DIR}/assets/tokens.json"    "${TEMP_DIR}/${PKG_NAME}/assets/"
cp -r "${ROOT_DIR}/references/."        "${TEMP_DIR}/${PKG_NAME}/references/"
cp "${ROOT_DIR}/scripts/indexer"          "${TEMP_DIR}/${PKG_NAME}/scripts/"
cp "${ROOT_DIR}/examples/"*.sh            "${TEMP_DIR}/${PKG_NAME}/examples/"
cp "${ROOT_DIR}/docs/ARCHITECTURE.md"    "${TEMP_DIR}/${PKG_NAME}/docs/"

# Create zip
cd "$TEMP_DIR"
zip -rq "$OUTPUT" "$PKG_NAME"
cd "$ROOT_DIR"
rm -rf "$TEMP_DIR"

echo ""
echo "âœ… Package created: ${PKG_NAME}.zip"
ls -lh "$OUTPUT"
echo ""
echo "Distribute to developers:"
echo "  unzip ${PKG_NAME}.zip"
echo "  cd ${PKG_NAME}"
echo "  bash install.sh"
echo "  ./scripts/indexer help"
