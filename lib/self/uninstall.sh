#!/usr/bin/env bash
##  Uninstall adm from this system
##
##  Usage:
##    adm self uninstall [--yes|-y] [--dry-run]
##
##  Options:
##    -h, --help       Show this help message and exit
##    -y, --yes        Do not prompt for confirmation
##    --dry-run        Show what would be removed, but don’t remove it

set -euo pipefail

show_help() { grep '^##' "$0" | sed 's/^##[ ]\{0,1\}//'; }

# --- Parse flags ---
YES=0
DRY=0
while (( $# )); do
  case "$1" in
    -h|--help) show_help; exit 0 ;;
    -y|--yes)  YES=1 ;;
    --dry-run) DRY=1 ;;
    *) echo "[ERROR] Unknown option: $1" >&2; echo; show_help; exit 1 ;;
  esac
  shift
done

# --- Require root (uninstalling from /usr/local usually needs it) ---
if [ "$(id -u)" -ne 0 ]; then
  echo "[ERROR] This script must be run with sudo or as root." >&2
  exit 1
fi

# --- Resolve install locations from this script path ---
SELF="$0"
case "$SELF" in /*) SCRIPT="$SELF" ;; *) SCRIPT="$(pwd)/$SELF" ;; esac
LIB_ROOT="$(cd "$(dirname "$SCRIPT")/.." && pwd)"                   # e.g., /usr/local/lib/adm
PREFIX_DEFAULT="$(dirname "$(dirname "$LIB_ROOT")")"                # e.g., /usr/local
PREFIX="${PREFIX:-$PREFIX_DEFAULT}"
BIN_DIR="${BIN_DIR:-$PREFIX/bin}"
LIB_DIR="${LIB_DIR:-$LIB_ROOT}"

BIN_PATH="$BIN_DIR/adm"

# --- Safety checks on LIB_DIR ---
if [ ! -d "$LIB_DIR" ]; then
  echo "[WARN] Library directory not found: $LIB_DIR"
fi

# Sentinel: only purge LIB_DIR if it appears to be an adm install
IS_SAFE=0
if [ -f "$LIB_DIR/self/VERSION" ] || [ -d "$LIB_DIR/user" ] || [ -d "$LIB_DIR/disk" ]; then
  IS_SAFE=1
fi

echo "This will remove:"
echo "  - $BIN_PATH"
echo "  - $LIB_DIR"
if [ "$IS_SAFE" -ne 1 ]; then
  echo
  echo "[ERROR] Refusing to remove '$LIB_DIR' — it doesn't look like an adm install." >&2
  echo "        (no 'self/VERSION' or expected subfolders found)"
  echo "        If your install is elsewhere, set LIB_DIR and BIN_DIR env vars."
  exit 1
fi

# --- Confirm unless --yes ---
if [ "$YES" -ne 1 ]; then
  echo
  read -r -p "Proceed with uninstall? [y/N]: " ans
  case "$ans" in [Yy]*) ;; *) echo "Cancelled."; exit 0 ;; esac
fi

# --- Dry-run?
if [ "$DRY" -eq 1 ]; then
  echo
  echo "[DRY-RUN] Would run:"
  echo "  rm -f \"$BIN_PATH\""
  echo "  rm -rf \"$LIB_DIR\""
  exit 0
fi

# --- Remove files ---
if [ -e "$BIN_PATH" ]; then
  rm -f "$BIN_PATH"
  echo "Removed: $BIN_PATH"
else
  echo "[INFO] Binary not found: $BIN_PATH"
fi

if [ -d "$LIB_DIR" ]; then
  rm -rf "$LIB_DIR"
  echo "Removed: $LIB_DIR"
else
  echo "[INFO] Library dir not found: $LIB_DIR"
fi

echo
echo "✅ adm has been uninstalled."
