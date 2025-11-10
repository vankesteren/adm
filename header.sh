#!/usr/bin/env bash
##  <Brief summary of what this script does.>
##
##  Usage:
##    adm <folder> <script> [options]
##
##  Options:
##    -h, --help       Show this help message and exit
##    <other options>
##
##  Notes:
##    <Any caveats or dependencies.>

#------------------------------ CONFIGURATION ----------------------------------
REQUIRE_SUDO=false   # Set to true if this script requires sudo privileges
SCRIPT_NAME="$(basename "$0")"

set -euo pipefail

#------------------------------ FUNCTIONS --------------------------------------

# Print help message (only lines starting with ##)
show_help() {
    grep '^##' "$0" | sed 's/^##[ ]\{0,1\}//'
}

# Check for sudo privileges if required
check_sudo() {
    if [ "$REQUIRE_SUDO" = "true" ] && [ "$(id -u)" -ne 0 ]; then
        echo "[ERROR] This script must be run with sudo or as root." >&2
        exit 1
    fi
}

#------------------------------ SCRIPT LOGIC -----------------------------------

for arg in "$@"; do
    case "$arg" in
        -h|--help) show_help; exit 0;;
    esac
done

check_sudo

