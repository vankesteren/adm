#!/usr/bin/env bash
##  Add or remove a user from the sudo group
##
##  Usage:
##    adm user sudo add <username>
##    adm user sudo remove <username>
##
##  Options:
##    -h, --help       Show this help message and exit

#------------------------------ CONFIGURATION ----------------------------------
set -euo pipefail

# Require root
if [ "$(id -u)" -ne 0 ]; then
    echo "[ERROR] This script must be run with sudo or as root." >&2
    exit 1
fi

#------------------------------ FUNCTIONS --------------------------------------

show_help() {
    grep '^##' "$0" | sed 's/^##[ ]\{0,1\}//'
}

need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "[ERROR] Required command '$1' not found." >&2
    exit 1
  fi
}

detect_sudo_group() {
  if getent group sudo >/dev/null 2>&1; then
    echo "sudo"
  elif getent group wheel >/dev/null 2>&1; then
    echo "wheel"
  else
    echo ""
  fi
}

user_in_group() {
  local user="$1" group="$2"
  id -nG "$user" 2>/dev/null | tr ' ' '\n' | grep -qx "$group"
}

#------------------------------ SCRIPT LOGIC -----------------------------------

# Parse options
case "${1-}" in
  -h|--help)
    show_help
    exit 0
    ;;
esac

# We expect: adm user sudo <action> <username>
if (( $# != 2 )); then
  echo "[ERROR] Usage: adm user sudo add <username>  OR  adm user sudo remove <username>" >&2
  echo
  show_help
  exit 1
fi

action="$1"
username="$2"

if ! getent passwd "$username" >/dev/null 2>&1; then
  echo "[ERROR] User '$username' does not exist." >&2
  exit 1
fi

SUDO_GROUP="$(detect_sudo_group)"
if [ -z "$SUDO_GROUP" ]; then
  echo "[ERROR] Could not find a 'sudo' or 'wheel' group on this system." >&2
  exit 1
fi

need usermod
need gpasswd

case "$action" in
  add)
    if user_in_group "$username" "$SUDO_GROUP"; then
      echo "ℹ️  User '$username' is already in '$SUDO_GROUP'. Nothing to do."
      exit 0
    fi

    usermod -aG "$SUDO_GROUP" "$username"
    echo "✅ Added user '$username' to '$SUDO_GROUP'."
    ;;

  remove)
    if ! user_in_group "$username" "$SUDO_GROUP"; then
      echo "ℹ️  User '$username' is not in '$SUDO_GROUP'. Nothing to do."
      exit 0
    fi

    gpasswd -d "$username" "$SUDO_GROUP" >/dev/null
    echo "✅ Removed user '$username' from '$SUDO_GROUP'."
    ;;

  *)
    echo "[ERROR] Unknown action: $action (use 'add' or 'remove')" >&2
    echo
    show_help
    exit 1
    ;;
esac
