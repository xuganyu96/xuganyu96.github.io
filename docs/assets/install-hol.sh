#!/usr/bin/env bash
set -euo pipefail

# 1. Check for OPAM
if ! command -v opam &>/dev/null; then
    echo "opam not found. Install it first:"
    echo "  Debian/Ubuntu: sudo apt install opam"
    echo "  Fedora:        sudo dnf install opam"
    echo "  macOS:         brew install opam"
    exit 1
fi
echo "opam $(opam --version)"

# 2. Prompt for installation path
DEFAULT_DIR="$HOME/.hol"
read -rp "Installation path [$DEFAULT_DIR]: " HOLLIGHT_DIR
HOLLIGHT_DIR="${HOLLIGHT_DIR:-$DEFAULT_DIR}"
HOLLIGHT_DIR="${HOLLIGHT_DIR/#\~/$HOME}"
read -rp "Install to '$HOLLIGHT_DIR'? [Y/n] " confirm
[[ "$(echo "$confirm" | tr '[:upper:]' '[:lower:]')" == n* ]] && exit 0

# 3. Clone and install dependencies
git clone git@github.com:jrh13/hol-light.git "$HOLLIGHT_DIR"
cd "$HOLLIGHT_DIR"
make switch-5
eval $(opam env --switch "${HOLLIGHT_DIR}/" --set-switch)
export CAMLP5LIB="$HOLLIGHT_DIR/_opam/lib/camlp5"
[[ -d "$CAMLP5LIB" ]] || { echo "CAMLP5LIB not found: $CAMLP5LIB"; exit 1; }

# 4. Compile HOL Light
HOLLIGHT_USE_MODULE=1 make

# 5. Post-install
echo
echo "Add the following to your shell config:"
echo "  export HOLLIGHT_DIR=\"$HOLLIGHT_DIR\""
echo "  export CAMLP5LIB=\"$HOLLIGHT_DIR/_opam/lib/camlp5\""
echo "  export PATH=\"\$HOLLIGHT_DIR:\$PATH\""
