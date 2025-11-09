#!/usr/bin/env bash
# lib/self/update.sh — update adm by re-running the online installer
# Usage:
#   adm self update [ref]
#     ref   Git ref (branch/tag/commit). Defaults to "main".
#
# Env overrides:
#   REPO_URL  (default: https://github.com/vankesteren/adm.git)
#   BRANCH    (fallback if no [ref] given; default: main)
#   PREFIX    (auto-detected; e.g., /usr/local)
#   BIN_DIR   (auto-detected; e.g., /usr/local/bin)
#   LIB_DIR   (auto-detected; e.g., /usr/local/lib/adm)

set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/vankesteren/adm.git}"
DEFAULT_BRANCH="${BRANCH:-main}"

# Determine paths based on this script's location: .../lib/adm/self/update.sh
SELF="$0"
# Resolve relative path
case "$SELF" in
  /*) SCRIPT="$SELF" ;;
  *)  SCRIPT="$(pwd)/$SELF" ;;
esac

# LIB_ROOT=/usr/local/lib/adm
LIB_ROOT="$(cd "$(dirname "$SCRIPT")/.." && pwd)"
# PREFIX=/usr/local ; BIN_DIR=/usr/local/bin ; LIB_DIR=/usr/local/lib/adm
PREFIX="${PREFIX:-"$(dirname "$(dirname "$LIB_ROOT")")"}"
BIN_DIR="${BIN_DIR:-$PREFIX/bin}"
LIB_DIR="${LIB_DIR:-$LIB_ROOT}"

# Optional ref argument (branch/tag); default to DEFAULT_BRANCH
REF="${1:-$DEFAULT_BRANCH}"

# We fetch install.sh from raw.githubusercontent.com for the chosen ref
INSTALL_URL="https://raw.githubusercontent.com/vankesteren/adm/${REF}/install.sh"

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Error: required command '$1' not found." >&2
    exit 1
  }
}

# Prefer curl, fallback to wget
FETCH_CMD=""
if command -v curl >/dev/null 2>&1; then
  FETCH_CMD="curl -fsSL"
elif command -v wget >/dev/null 2>&1; then
  FETCH_CMD="wget -qO-"
else
  echo "Error: neither 'curl' nor 'wget' found." >&2
  exit 1
fi

need sh

echo "→ Updating adm from ${REPO_URL} (ref: ${REF})"
echo "   PREFIX=${PREFIX}"
echo "   BIN_DIR=${BIN_DIR}"
echo "   LIB_DIR=${LIB_DIR}"
echo "   Installer: ${INSTALL_URL}"
echo

# Pipe the installer and pass environment so it installs into the same locations
# The installer itself will decide whether to sudo for protected paths.
# shellcheck disable=SC2086
$FETCH_CMD "$INSTALL_URL" | env \
  PREFIX="$PREFIX" \
  BIN_DIR="$BIN_DIR" \
  LIB_DIR="$LIB_DIR" \
  BRANCH="$REF" \
  REPO_URL="$REPO_URL" \
  sh

echo
echo "✅ adm update complete."
echo "adm version: $(adm --version)"
