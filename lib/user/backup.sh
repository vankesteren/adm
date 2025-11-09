#!/usr/bin/env bash
# Simple user home backup
# Usage: sudo backupuser <username>

set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: sudo $0 <username>" >&2
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
