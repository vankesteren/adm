#!/usr/bin/env bash
# adm user lastactivity — show the most recent file activity for all users
# Scans /data/<username> directories and prints the most recent file access/modification time.
#
# Usage:
#   adm user lastactivity [--help] [--days N]
#
# Options:
#   --help      Show this help message and exit
#   --days N    Limit to users active in the last N days (default: show all)
#
# Example:
#   adm user lastactivity
#   adm user lastactivity --days 7
#
# Output:
#   USER        LAST ACTIVITY           AGE
#   alice       2025-11-09 09:23:01     2 hours ago
#   bob         2025-11-08 18:44:10     17 hours ago
#   charlie     2025-11-05 22:14:32     3 days, 14 hours ago

set -euo pipefail

usage() {
  grep '^# ' "$0" | sed 's/^# //'
}

DATA_ROOT="/data"
DAYS_LIMIT=""
NOW=$(date +%s)

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --days)
      shift
      DAYS_LIMIT="$1"
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo
      usage
      exit 1
      ;;
  esac
  shift
done

if [[ ! -d "$DATA_ROOT" ]]; then
  echo "Error: data directory '$DATA_ROOT' not found." >&2
  exit 1
fi

human_elapsed() {
  local seconds="$1"
  local days=$(( seconds / 86400 ))
  local hours=$(( (seconds % 86400) / 3600 ))
  local minutes=$(( (seconds % 3600) / 60 ))

  local parts=()
  (( days > 0 )) && parts+=("${days} day$([[ $days -ne 1 ]] && echo s)")
  (( hours > 0 )) && parts+=("${hours} hour$([[ $hours -ne 1 ]] && echo s)")
  (( minutes > 0 && days == 0 )) && parts+=("${minutes} min$([[ $minutes -ne 1 ]] && echo s)")

  if [[ ${#parts[@]} -eq 0 ]]; then
    echo "just now"
  else
    (IFS=', '; echo "${parts[*]} ago")
  fi
}

printf "%-12s %-20s %-20s\n" "USER" "LAST ACTIVITY" "AGE"
printf "%0.s-" {1..60}; echo

# Iterate through users
for userdir in "$DATA_ROOT"/*; do
  [[ -d "$userdir" ]] || continue
  user=$(basename "$userdir")

  # Find most recent file access/modification
  ts=$(find "$userdir" -type f -printf '%T@\n' 2>/dev/null | sort -n | tail -1 || true)
  [[ -z "$ts" ]] && continue

  ts_int=${ts%.*}
  age=$(( NOW - ts_int ))

  if [[ -n "$DAYS_LIMIT" ]]; then
    limit_seconds=$(( DAYS_LIMIT * 86400 ))
    (( age > limit_seconds )) && continue
  fi

  readable="$(human_elapsed "$age")"
  date_str="$(date -d @"$ts_int" '+%Y-%m-%d %H:%M:%S')"
  printf "%-12s %-20s %-20s\n" "$user" "$date_str" "$readable"
done | sort -k2r

echo
echo "✅ Done."
