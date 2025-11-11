#!/usr/bin/env bash
##  Update adm to the latest version
##
##  Usage:
##    adm folder command [options]
##
##  Options:
##    -h, --help       Show this help message and exit

#------------------------------ CONFIGURATION ----------------------------------
set -euo pipefail

# Check for sudo privileges (remove if not required)
if [ "$(id -u)" -ne 0 ]; then
    echo "[ERROR] This script must be run with sudo or as root." >&2
    exit 1
fi

#------------------------------ FUNCTIONS --------------------------------------

# Print help message (only lines starting with ##)
show_help() {
    grep '^##' "$0" | sed 's/^##[ ]\{0,1\}//'
}

#------------------------------ SCRIPT LOGIC -----------------------------------

# Parse options / optional ref
case "${1-}" in
  -h|--help) show_help; exit 0 ;;
esac
REF="${1:-main}"

# Minimal deps
command -v curl >/dev/null 2>&1 || { echo "Error: curl not found." >&2; exit 1; }

# Resolve locations based on this script path: .../lib/adm/self/update.sh
SELF="$0"
case "$SELF" in /*) SCRIPT="$SELF" ;; *) SCRIPT="$(pwd)/$SELF" ;; esac
LIB_ROOT="$(cd "$(dirname "$SCRIPT")/.." && pwd)"                    # /usr/local/lib/adm
PREFIX="${PREFIX:-"$(dirname "$(dirname "$LIB_ROOT")")"}"           # /usr/local
BIN_DIR="${BIN_DIR:-$PREFIX/bin}"
LIB_DIR="${LIB_DIR:-$LIB_ROOT}"

REPO_URL="${REPO_URL:-https://github.com/vankesteren/adm}"          # no .git
INSTALL_URL="https://raw.githubusercontent.com/vankesteren/adm/${REF}/install.sh"

echo "→ Updating adm from ${REPO_URL} (ref: ${REF})"
echo

# Pipe the installer and pass environment so it installs into the same locations
# shellcheck disable=SC2086
curl -fsSL "$INSTALL_URL" | env \
  PREFIX="$PREFIX" \
  BRANCH="$REF" \
  REPO_URL="$REPO_URL" \
  sh

echo
echo "✅ adm update complete."
if [ -x "$BIN_DIR/adm" ]; then
  echo "✅ adm version: $("$BIN_DIR/adm" --version || true)"
else
  echo "Note: $BIN_DIR not on PATH or adm not found there."
fi
