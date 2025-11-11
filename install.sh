#!/usr/bin/env sh
# Installs adm dispatcher and lib from the git repo to /usr/local by default.
# Pipe install usage:
#   curl -fsSL https://raw.githubusercontent.com/vankesteren/adm/HEAD/install.sh | sh
#
# Customization via env:
#   PREFIX=/opt          # default /usr/local
#   BRANCH=main          # default: main (or HEAD)
#   REPO_URL=https://github.com/vankesteren/adm.git

set -eu

REPO_URL="${REPO_URL:-https://github.com/vankesteren/adm.git}"
BRANCH="${BRANCH:-main}"
PREFIX="${PREFIX:-/usr/local}"
BIN_DIR="$PREFIX/bin"
LIB_DIR="$PREFIX/lib/adm"

# Check for sudo privileges
if [ "$(id -u)" -ne 0 ]; then
    echo "[ERROR] This script must be run with sudo or as root." >&2
    exit 1
fi

# Check dependencies
need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Error: required command '$1' not found." >&2
    exit 1
  fi
}
need git
need mktemp

# Create a temp directory and clean up on exit
TMPDIR="$(mktemp -d 2>/dev/null || mktemp -d -t adm-install)"
cleanup() { rm -rf "$TMPDIR"; }
trap cleanup EXIT INT TERM

echo "→ Cloning ${REPO_URL} (branch: ${BRANCH}) to a temporary directory..."
git -c advice.detachedHead=false clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$TMPDIR/repo" >/dev/null 2>&1 || {
  echo "Falling back to cloning default branch (HEAD)..."
  git clone --depth 1 "$REPO_URL" "$TMPDIR/repo" >/dev/null
}

# Paths in repo
REPO_LIB="$TMPDIR/repo/lib"
REPO_BIN_ADM="$TMPDIR/repo/bin/adm"

# Validate repo contents
if [ ! -d "$REPO_LIB" ]; then
  echo "Error: repo does not contain a 'lib/' directory." >&2
  exit 1
fi

if [ ! -f "$REPO_BIN_ADM" ]; then
  echo "Error: repo does not contain 'bin/adm' dispatcher." >&2
  exit 1
fi

# Add version
mkdir -p "$REPO_LIB/self"
git -C "$TMPDIR/repo" rev-parse HEAD > "$REPO_LIB/self/VERSION"

# Create target dirs
echo "→ Ensuring target directories exist..."
mkdir -p "$BIN_DIR"
mkdir -p "$(dirname "$LIB_DIR")"

# Install lib tree
echo "→ Installing library to $LIB_DIR ..."
if [ -d "$LIB_DIR" ]; then
  # Move aside old dir then replace
  TMP_OLD="$LIB_DIR.$(date +%s).old"
  mv "$LIB_DIR" "$TMP_OLD"
  mkdir -p "$LIB_DIR"
  cp -Rp "$REPO_LIB"/* "$LIB_DIR"
  rm -rf "$TMP_OLD"
else
  mkdir -p "$LIB_DIR"
  cp -Rp "$REPO_LIB"/* "$LIB_DIR"
fi

# Install dispatcher
echo "→ Installing adm to $BIN_DIR/adm ..."
install -m 0755 "$REPO_BIN_ADM" "$BIN_DIR/adm"

# Post-install checks
echo "→ Verifying installation..."
if ! "$BIN_DIR/adm" --version >/dev/null 2>&1; then
    echo "Note: '$BIN_DIR' may not be on PATH or adm failed to run." >&2
fi

cat <<EOF

✅ Installed 'adm'.

Binary:  $BIN_DIR/adm
Library: $LIB_DIR

To get started, run
  adm --help

EOF
