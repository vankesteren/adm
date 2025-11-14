#!/usr/bin/env bash
##  Backup a user's home directory
##
##  Usage:
##    adm user backup <username>
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

if [ $# -ne 1 ]; then
  echo "Usage: sudo adm user backup <username>" >&2
  exit 1
fi

username="$1"
homedir="/data/$username"
backupfile="$(pwd)/${username}.tar.gz"

# Check if user exists
if ! id "$username" &>/dev/null; then
  echo "❌ User '$username' does not exist." >&2
  exit 1
fi

# Check if home directory exists
if [ ! -d "$homedir" ]; then
  echo "❌ Home directory not found: $homedir" >&2
  exit 1
fi

echo "📦 Creating backup of $homedir → $backupfile ..."
tar -czf "$backupfile" -C /data "$username" --checkpoint=.1000

echo ""
echo "✅ Backup complete: $backupfile"
