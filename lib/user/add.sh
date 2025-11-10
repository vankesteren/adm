#!/usr/bin/env bash
##  Add a user to the system
##
##  Usage:
##    adm user add <username> <password> [email]
##
##  Options:
##    -h, --help       Show this help message and exit

#------------------------------ CONFIGURATION ----------------------------------
SCRIPT_NAME="$(basename "$0")"

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


# Very basic username sanity check (POSIX-ish)
valid_username() {
  [[ "$1" =~ ^[a-z_][a-z0-9_-]*$ ]]
}

#------------------------------ ARG PARSING ------------------------------------

# Parse options first
while (( $# > 0 )); do
  case "$1" in
    -h|--help) show_help; exit 0 ;;
    --) shift; break ;;
    -*) echo "Unknown option: $1" >&2; echo; show_help; exit 1 ;;
    *) break ;;
  esac
done

# Now positional args: <username> <password> [email]
if (( $# < 2 || $# > 3 )); then
  echo "[ERROR] Expected: adm user add <username> <password> [email]" >&2
  echo
  show_help
  exit 2
fi

username="$1"
password="$2"
email="${3:-}"                        # optional
homedir="/data/$username"
shell="/bin/bash"

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
if [ -n "$email" ]; then
  echo "📧 Email (GECOS):   <$email>"
fi
echo "🧩 Shell:           /bin/bash"
echo "--------------------------------------------------------------"
echo ""

read -p "Proceed with creating this user? (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  echo "❎ Operation cancelled."
  exit 0
fi

# --- Create user ---
# Build useradd args
useradd_args=(-m -d "$homedir" -s "$shell")
if [ -n "$email" ]; then
  useradd_args+=(-c "<$email>")
fi

useradd "${useradd_args[@]}" "$username"

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