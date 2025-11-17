#!/usr/bin/env bash
##  Show the last activity date of each user
##
##  Usage:
##    adm user lastactivity
##
##  Options:
##    -h, --help       Show this help message and exit

#------------------------------ CONFIGURATION ----------------------------------
set -euo pipefail

# Check for sudo privileges 
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



DATA_ROOT="/data"
NOW=$(date +%s)

# Parse arguments
for arg in "$@"; do
  case "$arg" in
    -h|--help) show_help; exit 0 ;;
    *) echo "Unknown option: $arg" >&2; echo; show_help; exit 1 ;;
  esac
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

  readable="$(human_elapsed "$age")"
  date_str="$(date -d @"$ts_int" '+%Y-%m-%d %H:%M:%S')"
  printf "%-12s %-20s %-20s\n" "$user" "$date_str" "$readable"
done | sort -k2r

echo
echo "✅ Done."
