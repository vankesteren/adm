#!/usr/bin/env sh
# Installs adm dispatcher and lib from the git repo to /usr/local by default.
# Pipe install usage:
#   curl -fsSL https://raw.githubusercontent.com/vankesteren/adm/HEAD/install.sh | sh
#
# Customization via env:
#   PREFIX=/opt          # default /usr/local
#   BIN_DIR=/usr/local/bin
#   LIB_DIR=/usr/local/lib/adm
#   BRANCH=main          # default: main (or HEAD)
#   REPO_URL=https://github.com/vankesteren/adm.git

set -eu

REPO_URL="${REPO_URL:-https://github.com/vankesteren/adm.git}"
BRANCH="${BRANCH:-main}"
PREFIX="${PREFIX:-/usr/local}"
BIN_DIR="${BIN_DIR:-$PREFIX/bin}"
LIB_DIR="${LIB_DIR:-$PREFIX/lib/adm}"

# Decide whether to sudo
need_write_dir() {
  _d="$1"
  ( [ -d "$_d" ] && [ -w "$_d" ] ) || ( mkdir -p "$_d" 2>/dev/null && [ -w "$_d" ] )
}
SUDO=""
if ! need_write_dir "$BIN_DIR" || ! need_write_dir "$(dirname "$LIB_DIR")"; then
  if command -v sudo >/dev/null 2>&1 && [ "${EUID:-$(id -u)}" -ne 0 ]; then
    SUDO="sudo"
  fi
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
  echo "Tip: add your dispatcher to bin/adm (chmod +x) and re-run." >&2
  exit 1
fi

# Create target dirs
echo "→ Ensuring target directories exist..."
$SUDO mkdir -p "$BIN_DIR"
$SUDO mkdir -p "$(dirname "$LIB_DIR")"

# Install lib tree
echo "→ Installing library to $LIB_DIR ..."
# Replace atomically: move aside old dir then replace
if [ -d "$LIB_DIR" ]; then
  TMP_OLD="$LIB_DIR.$(date +%s).old"
  $SUDO mv "$LIB_DIR" "$TMP_OLD"
  $SUDO mkdir -p "$LIB_DIR"
  if command -v rsync >/dev/null 2>&1; then
    $SUDO rsync -a "$REPO_LIB/" "$LIB_DIR/"
  else
    (cd "$REPO_LIB" && $SUDO tar cf - .) | (cd "$LIB_DIR" && $SUDO tar xf -)
  fi
  $SUDO rm -rf "$TMP_OLD"
else
  $SUDO mkdir -p "$LIB_DIR"
  if command -v rsync >/dev/null 2>&1; then
    $SUDO rsync -a "$REPO_LIB/" "$LIB_DIR/"
  else
    (cd "$REPO_LIB" && $SUDO tar cf - .) | (cd "$LIB_DIR" && $SUDO tar xf -)
  fi
fi

# Install dispatcher
echo "→ Installing dispatcher to $BIN_DIR/adm ..."
$SUDO install -m 0755 "$REPO_BIN_ADM" "$BIN_DIR/adm"

# Post-install checks
echo "→ Verifying installation..."
if ! command -v "$BIN_DIR/adm" >/dev/null 2>&1; then
  echo "Warning: $BIN_DIR is not on your PATH. Add it to PATH to use 'adm'." >&2
fi

# Try a dry-run help to ensure ADM_LIB_DIR is discoverable
if ! "$BIN_DIR/adm" --version >/dev/null 2>&1; then
  echo "Note: 'adm --version' failed. Ensure the dispatcher uses ADM_LIB_DIR='$LIB_DIR' or defaults to it." >&2
fi

cat <<EOF

✅ Installed 'adm'.

Binary:  $BIN_DIR/adm
Library: $LIB_DIR

Examples:
  adm --help
  adm user new <username> <password>
  adm disk check

To update later, just re-run the same install command.

Customize install:
  PREFIX=/opt BRANCH=main \\
  REPO_URL=${REPO_URL} \\
  curl -fsSL https://raw.githubusercontent.com/vankesteren/adm/HEAD/install.sh | sh
EOF
