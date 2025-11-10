#!/usr/bin/env bash
##  Show the disk usage per user
##
##  Usage:
##    adm disk usage [options]
##
##  Options:
##    -h, --help       Show this help message and exit
##    --sort    Sort by size descending
##    --total   Show total size at the end

#------------------------------ CONFIGURATION ----------------------------------
REQUIRE_SUDO=true   # Set to true if this script requires sudo privileges
SCRIPT_NAME="$(basename "$0")"

set -euo pipefail

# Check for sudo privileges if required
if [ "$REQUIRE_SUDO" = "true" ] && [ "$(id -u)" -ne 0 ]; then
    echo "[ERROR] This script must be run with sudo or as root." >&2
    exit 1
fi

#------------------------------ FUNCTIONS --------------------------------------

# Print help message (only lines starting with ##)
show_help() {
    grep '^##' "$0" | sed 's/^##[ ]\{0,1\}//'
}


#------------------------------ SCRIPT LOGIC -----------------------------------
DATA_DIR="/data"
SORT=0
TOTAL=0

# Parse arguments
for arg in "$@"; do
  case "$arg" in
    -h|--help) show_help; exit 0 ;;
    --sort)  SORT=1 ;;
    --total) TOTAL=1 ;;
    *) echo "Unknown option: $arg" >&2; echo; show_help; exit 1 ;;
  esac
done

if [[ ! -d "$DATA_DIR" ]]; then
  echo "Error: data directory '$DATA_DIR' not found." >&2
  exit 1
fi

if [[ "$SORT" -eq 1 ]]; then
  du -sh "${DATA_DIR}"/* 2>/dev/null | sort -hr
else
  du -sh "${DATA_DIR}"/* 2>/dev/null
fi

if [[ "$TOTAL" -eq 1 ]]; then
  echo
  echo "Total size of all user directories:"
  du -sh "$DATA_DIR" 2>/dev/null
fi
