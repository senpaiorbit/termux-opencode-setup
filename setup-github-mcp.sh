#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

REPO="https://github.com/github/github-mcp-server.git"
DIR="$HOME/github-mcp-server"
BIN="$PREFIX/bin/github-mcp-server"
CONFIG="$HOME/.config/opencode/opencode.json"
TOKEN_FILE="$HOME/.config/github-mcp.env"

echo "=========================================="
echo " GitHub MCP Server — Termux"
echo "=========================================="

# ------------------------------------------
# Check Termux
# ------------------------------------------
if [ -z "${PREFIX:-}" ] || [ ! -x "$PREFIX/bin/pkg" ]; then
    echo "ERROR: This script must run inside Termux."
    exit 1
fi

ARCH="$(uname -m)"

if [ "$ARCH" != "aarch64" ]; then
    echo "ERROR: ARM64/aarch64 is required."
    echo "Detected: $ARCH"
    exit 1
fi

echo "[OK] Termux"
echo "[OK] ARM64"

# ------------------------------------------
# Install dependencies
# ------------------------------------------
echo
echo "[1/8] Installing dependencies..."

pkg update -y
pkg upgrade -y

pkg install -y \
    git \
    golang \
    ca-certificates \
    termux-api \
    python

echo
echo "Go:"
go version

echo
echo "Git:"
git --version

# ------------------------------------------
# Check Android Termux:API
# ------------------------------------------
echo
echo "[2/8] Checking Android dialog support..."

if ! command -v termux-dialog >/dev/null 2>&1; then
    echo
    echo "ERROR: termux-dialog is unavailable."
    echo
    echo "Install the Termux:API Android app, then run:"
    echo
    echo "  pkg install termux-api"
    echo
    echo "and run this script again."
    exit 1
fi

echo "[OK] termux-dialog available"

# ------------------------------------------
# Clone/update GitHub MCP
# ------------------------------------------
echo
echo "[3/8] Downloading official GitHub MCP Server..."

if [ -d "$DIR/.git" ]; then
    cd "$DIR"

    echo "Existing repository found."
    git fetch origin
    git reset --hard origin/main
else
    rm -rf "$DIR"
    git clone "$REPO" "$DIR"
    cd "$DIR"
fi

echo
echo "Latest commit:"
git log -1 --oneline

# ------------------------------------------
# Build
# ------------------------------------------
echo
echo "[4/8] Building GitHub MCP Server..."
echo
echo "This may take a few minutes on Termux."
echo

CGO_ENABLED=0 \
GOOS=android \
GOARCH=arm64 \
go build \
    -trimpath \
    -ldflags="-s -w" \
    -o "$BIN" \
    ./cmd/github-mcp-server

chmod 755 "$BIN"

if [ ! -x "$BIN" ]; then
    echo "ERROR: Build failed."
    exit 1
fi

echo
echo "[OK] Binary built:"
echo "$BIN"

# ------------------------------------------
# Version
# ------------------------------------------
echo
echo "[5/8] Checking binary..."

"$BIN" --version || true

# ------------------------------------------
# Android TOKEN INPUT BOX
# ------------------------------------------
echo
echo "=========================================="
echo " GitHub Authentication"
echo "=========================================="
echo
echo "An Android input box will appear."
echo
echo "Paste your NEW GitHub Personal Access Token"
echo "into the box and press OK."
echo

sleep 1

# FIX: removed -p flag (password mode) which caused the dialog
# to not dismiss properly. Now uses plain text input so you can
# see what you're pasting and the dialog closes on OK.
DIALOG_OUTPUT="$(termux-dialog text \
    -t "GitHub Personal Access Token" \
    -i "Paste your GitHub PAT here")"

# Show raw result only for error checking.
# Do NOT echo the token itself.
if [ -z "$DIALOG_OUTPUT" ]; then
    echo
    echo "ERROR: No response from Android dialog."
    echo
    echo "Make sure:"
    echo "1. Termux:API app is installed."
    echo "2. Termux has permission to use Termux:API."
    exit 1
fi

# Extract the JSON "text" field.
TOKEN="$(
    printf '%s' "$DIALOG_OUTPUT" |
    python -c '
import sys,json
try:
    x=json.load(sys.stdin)
    print(x.get("text",""))
except Exception:
    print("")
'
)"

if [ -z "$TOKEN" ]; then
    echo
    echo "ERROR: Token box was empty or cancelled."
    exit 1
fi

# ------------------------------------------
# Save token securely
# ------------------------------------------
mkdir -p "$HOME/.config"

cat > "$TOKEN_FILE" <<TOKEN_EOF
export GITHUB_PERSONAL_ACCESS_TOKEN=$(printf '%q' "$TOKEN")
TOKEN_EOF

chmod 600 "$TOKEN_FILE"

unset TOKEN
unset DIALOG_OUTPUT

echo
echo "[OK] GitHub token saved securely."
echo "File permissions: 600"

# ------------------------------------------
# OpenCode configuration
# ------------------------------------------
echo
echo "[6/8] Configuring OpenCode..."

mkdir -p "$HOME/.config/opencode"

# Backup existing configuration
if [ -f "$CONFIG" ]; then
    BACKUP="$CONFIG.backup.$(date +%Y%m%d-%H%M%S)"
    cp "$CONFIG" "$BACKUP"

    echo
    echo "Existing OpenCode config backed up:"
    echo "$BACKUP"
fi

python <<PY
import json
import os

config = os.path.expanduser("$CONFIG")

if os.path.exists(config):
    try:
        with open(config, "r") as f:
            data = json.load(f)
    except Exception:
        data = {}
else:
    data = {}

if not isinstance(data, dict):
    data = {}

data.setdefault("$schema", "https://opencode.ai/config.json")

mcp = data.setdefault("mcp", {})

mcp["github"] = {
    "type": "local",
    "command": [
        "$BIN",
        "stdio"
    ],
    "enabled": True,
    "environment": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "{env:GITHUB_PERSONAL_ACCESS_TOKEN}"
    }
}

with open(config, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\\n")

PY

# ------------------------------------------
# Create launcher
# ------------------------------------------
echo
echo "[7/8] Creating GitHub MCP launcher..."

LAUNCHER="$PREFIX/bin/github-mcp"

cat > "$LAUNCHER" <<'LAUNCH_EOF'
#!/data/data/com.termux/files/usr/bin/bash
set -e

TOKEN_FILE="$HOME/.config/github-mcp.env"

if [ ! -f "$TOKEN_FILE" ]; then
    echo "ERROR: GitHub token file not found:"
    echo "$TOKEN_FILE"
    exit 1
fi

set -a
. "$TOKEN_FILE"
set +a

exec "$PREFIX/bin/github-mcp-server" stdio
LAUNCH_EOF

chmod 755 "$LAUNCHER"

# ------------------------------------------
# Final verification
# ------------------------------------------
echo
echo "[8/8] Verifying installation..."

echo
echo "Binary:"
which github-mcp-server

echo
echo "Launcher:"
which github-mcp

echo
echo "OpenCode config:"
echo "$CONFIG"

echo
echo "Token file:"
echo "$TOKEN_FILE"

echo
echo "=========================================="
echo " GitHub MCP INSTALLATION COMPLETE"
echo "=========================================="

echo
echo "Run:"
echo
echo "  opencode mcp list"
echo
echo "Then:"
echo
echo "  opencode"
echo
echo "Inside OpenCode, GitHub MCP should appear"
echo "as: github"

echo
echo "Manual launcher:"
echo
echo "  github-mcp"

echo
echo "=========================================="
