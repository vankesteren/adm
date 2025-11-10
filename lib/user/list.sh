#!/usr/bin/env bash
##  List users and their emails
##
##  Usage:
##    adm user list [options]
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

# Parse arguments
case "${1-}" in
    -h|--help) show_help ; exit 0;;
esac


if [ ! -d /data ]; then
    echo "[ERROR] Data root /data not found." >&2
    exit 1
fi


printf '%-20s %s\n' "USER" "EMAIL"
printf '%0.s-' $(seq 1 60); echo

for d in /data/*; do
    [ -d "$d" ] || continue
    user="$(basename "$d")"
     if entry="$(getent passwd "$user")"; then
      gecos="$(awk -F: '{print $5}' <<<"$entry")"
      printf '%-20s %s\n' "$user" "$gecos"
    fi
done