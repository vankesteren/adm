#!/usr/bin/env bash
# Secure user creation script with confirmation prompt
# Usage: sudo newuser <username> <password>

set -euo pipefail

# --- Check arguments ---
if [ $# -ne 2 ]; then
  echo "Usage: sudo $0 <username> <password>"
  exit 1
fi

username="$1"
password="$2"
homedir="/data/$username"

# --- Check if user already exists ---
if id "$username" &>/dev/null; then
  echo "❌ User '$username' already exists."
  exit 1
fi

# --- Show summary and ask for confirmation ---
echo ""
echo "You are about to create a new user with the following details:"
echo "--------------------------------------------------------------"
echo "👤 Username:        $username"
echo "🏠 Home directory:  $homedir"
echo "🔑 Password:        $password"
echo "🧩 Shell:           /bin/bash"
echo "--------------------------------------------------------------"
echo ""

read -p "Proceed with creating this user? (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "❎ Operation cancelled."
  exit 0
fi

# --- Create user ---
useradd -m -d "$homedir" -s /bin/bash "$username"

# --- Set password securely ---
echo "$username:$password" | chpasswd

# --- Set ownership and permissions ---
chown -R "$username":"$username" "$homedir"
chmod -R go-rwx "$homedir"

# --- Success message ---
echo ""
echo "✅ User '$username' created successfully!"
echo "📁 Home directory: $homedir"
echo "🔒 Permissions: owner-only (700)"
echo ""
echo "👉 To switch to this user:"
echo "   sudo su $username"
echo ""