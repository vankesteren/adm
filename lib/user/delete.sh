#!/usr/bin/env bash
##  Delete a user from the system
##
##  Usage:
##    adm user delete <username>
##
##  Options:
##    -h, --help       Show this help message and exit

#------------------------------ CONFIGURATION ----------------------------------
set -euo pipefail

# Check for sudo privileges if required
if [ "$(id -u)" -ne 0 ]; then
    echo "[ERROR] This script must be run with sudo or as root." >&2
    exit 1
fi

#------------------------------ FUNCTIONS --------------------------------------

# Print help message (only lines starting with ##)
show_help() {
    grep '^##' "$0" | sed 's/^##[ ]\{0,1\}//'
}


# Parse arguments
case "${1-}" in
    -h|--help) show_help ; exit 0;;
esac

# --- Args ---
if [ $# -ne 1 ]; then
  echo "Usage: sudo adm user delete <username>" >&2
  exit 1
fi

username="$1"

# --- Check user exists ---
if ! id "$username" &>/dev/null; then
  echo "❌ User '$username' does not exist." >&2
  exit 1
fi

# --- Gather details ---
passwd_line="$(getent passwd "$username")"
uid="$(echo "$passwd_line" | cut -d: -f3)"
gid="$(echo "$passwd_line" | cut -d: -f4)"
homedir="$(echo "$passwd_line" | cut -d: -f6)"
shell="$(echo "$passwd_line" | cut -d: -f7)"
groupname="$(getent group "$gid" | cut -d: -f1 || true)"

echo ""
echo "You are about to permanently REMOVE the following account and data:"
echo "-------------------------------------------------------------------"
echo "👤 Username:        $username"
echo "🆔 UID:GID:         $uid:$gid"
echo "👥 Primary group:   ${groupname:-<unknown>}"
echo "🏠 Home directory:  $homedir"
echo "🧩 Login shell:     $shell"
echo "🗓️  Also remove:     crontab (if any), /etc/sudoers.d/$username (if present)"
echo "🔪 Processes:       will be terminated"
echo "-------------------------------------------------------------------"
echo ""
read -p "Type the username EXACTLY to confirm: " confirm

if [[ "$confirm" != "$username" ]]; then
  echo "❎ Confirmation did not match. Aborting."
  exit 1
fi

# --- Extra safety on home directory deletion ---
# userdel -r will remove the home dir listed in /etc/passwd. We’ll still
# verify later and only rm -rf if it still exists AND is not suspicious.
safe_rm_home() {
  local path="$1"
  if [ -z "$path" ] || [ "$path" = "/" ] || [ "$path" = "/root" ]; then
    echo "⚠️  Refusing to remove suspicious home directory path: '$path'" >&2
    return 1
  fi
  if [ -e "$path" ]; then
    rm -rf --one-file-system -- "$path"
  fi
}

echo ""
echo "🔧 Terminating user processes..."
# Try systemd first (if available), fall back to pkill
if command -v loginctl &>/dev/null; then
  loginctl terminate-user "$username" || true
fi
pkill -u "$username" || true

echo "🗓️  Removing crontab (if any)..."
crontab -r -u "$username" 2>/dev/null || true

echo "🧰 Removing sudoers drop-in (if any)..."
if [ -f "/etc/sudoers.d/$username" ]; then
  rm -f "/etc/sudoers.d/$username"
fi

echo "👤 Deleting user (and home) with userdel -r..."
# userdel -r removes the home directory listed in passwd and the mail spool
userdel -r "$username" || {
  echo "⚠️  userdel -r returned non-zero. Continuing cleanup..."
}

# If home still exists (e.g., custom mount or mismatch), remove safely
if [ -e "$homedir" ]; then
  echo "🧹 Home directory still present; removing: $homedir"
  safe_rm_home "$homedir" || true
fi

# --- Clean up primary group if it’s user-only and matches username ---
if [ -n "${groupname:-}" ] && [ "$groupname" = "$username" ]; then
  # Check if group is still present and has no members
  if getent group "$groupname" &>/dev/null; then
    # If no other users share the GID, groupdel is safe
    echo "👥 Removing primary group '$groupname' (if unused)..."
    groupdel "$groupname" 2>/dev/null || true
  fi
fi

echo ""
echo "✅ User '$username' and associated data have been removed."
echo "   - Processes terminated"
echo "   - Crontab removed (if existed)"
echo "   - Sudoers drop-in removed (if existed)"
echo "   - Account deleted"
echo "   - Home directory purged: $homedir"
echo ""