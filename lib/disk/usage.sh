#!/usr/bin/env bash
# Lists user home directories under /data and prints their sizes.
# Usage:
#   adm disk usage [options]
#
# Options:
#   --help    Show this message and exit
#   --human   Show human-readable sizes (default)
#   --sort    Sort by size descending
#   --total   Show total size at the end

set -euo pipefail

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Lists user home directories under /data and prints their sizes.

Options:
  --help    Show this message and exit
  --human   Show human-readable sizes (default)
  --sort    Sort by size descending
  --total   Show total size at the end

Examples:
  $(basename "$0")
  $(basename "$0") --sort
  $(basename "$0") --total
EOF
}

DATA_DIR="/data"
HUMAN=1
SORT=0
TOTAL=0

# Parse arguments
for arg in "$@"; do
  case "$arg" in
    -h|--help) usage; exit 0 ;;
    --human) HUMAN=1 ;;
    --sort)  SORT=1 ;;
    --total) TOTAL=1 ;;
    *) echo "Unknown option: $arg" >&2; echo; usage; exit 1 ;;
  esac
done

if [[ ! -d "$DATA_DIR" ]]; then
  echo "Error: data directory '$DATA_DIR' not found." >&2
  exit 1
fi

if [[ "$HUMAN" -eq 1 ]]; then
  DU_OPTS=(-sh)
else
  DU_OPTS=(-sk)
fi

if [[ "$SORT" -eq 1 ]]; then
  du "${DU_OPTS[@]}" "${DATA_DIR}"/* 2>/dev/null | sort -hr
else
  du "${DU_OPTS[@]}" "${DATA_DIR}"/* 2>/dev/null
fi

if [[ "$TOTAL" -eq 1 ]]; then
  echo
  echo "Total size of all user directories:"
  du -sh "$DATA_DIR" 2>/dev/null
fi
