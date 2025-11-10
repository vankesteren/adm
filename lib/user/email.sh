#!/usr/bin/env bash
##  Show or add email of a user
##
##  Usage:
##    adm user email <username> [email]
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

# Need at least one argument (username)
if (( $# < 1 )); then
    echo "[ERROR] Missing username." >&2
    echo
    show_help
    exit 1
fi

if (( $# > 2 )); then
    echo "[ERROR] Too many arguments." >&2
    echo
    show_help
    exit 1
fi


username="$1"
email="${2-}"  # optional

# Check that the user exists
if ! getent passwd "$username" >/dev/null 2>&1; then
    echo "[ERROR] User '$username' does not exist." >&2
    exit 1
fi

# If no email provided → show current email
if [[ -z "$email" ]]; then
    getent passwd "$username" | awk -F: '{print $5}'
    exit 0
fi

usermod -c "<$email>" "$username"

echo "✅ Set email for '$username' to <$email>"