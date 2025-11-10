#!/usr/bin/env bash
##  Short description here
##
##  Usage:
##    adm folder command [options]
##
##  Options:
##    -h, --help       Show this help message and exit

#------------------------------ CONFIGURATION ----------------------------------
SCRIPT_NAME="$(basename "$0")"

set -euo pipefail

# Check for sudo privileges (remove if not required)
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

# Parse arguments
for arg in "$@"; do
  case "$arg" in
    -h|--help) show_help; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; echo; show_help; exit 1 ;;
  esac
done
