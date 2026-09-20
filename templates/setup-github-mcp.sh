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

echo
echo "[1/8] Installing dependencies..."
pkg update -y
pkg upgrade -y
pkg install -y git golang ca-certificates termux-api python

echo
echo "Go:"
go version
echo
echo "Git:"
git --version

echo
echo "[2/8] Checking Android dialog support..."
if ! command -v termux-dialog >/dev/null 2>&1; then
    echo "ERROR: termux-dialog is unavailable."
    echo "Install the Termux:API Android app, then run:"
    echo "  pkg install termux-api"
    echo "and run this script again."
    exit 1
fi
echo "[OK] termux-dialog available"

echo
echo "[3/8] Downloading official GitHub MCP Server..."
if [ -d "$DIR/.git" ]; then
    cd "$DIR"
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

echo
echo "[4/8] Building GitHub MCP Server..."
CGO_ENABLED=0 GOOS=android GOARCH=arm64 go build -trimpath -ldflags="-s -w" -o "$BIN" ./cmd/github-mcp-server
chmod 755 "$BIN"
if [ ! -x "$BIN" ]; then echo "ERROR: Build failed."; exit 1; fi
echo "[OK] Binary built: $BIN"

echo
echo "[5/8] Checking binary..."
"$BIN" --version || true

echo
echo "=========================================="
echo " GitHub Authentication"
echo "=========================================="
echo "An Android input box will appear."
echo "Paste your NEW GitHub Personal Access Token"
echo "into the box and press OK."
sleep 1

# FIX: removed -p flag (password mode) which caused the dialog
# to not dismiss properly. Now uses plain text input.
DIALOG_OUTPUT="$(termux-dialog text -t "GitHub Personal Access Token" -i "Paste your GitHub PAT here")"

if [ -z "$DIALOG_OUTPUT" ]; then
    echo "ERROR: No response from Android dialog."
    exit 1
fi

TOKEN="$(printf '%s' "$DIALOG_OUTPUT" | python -c 'import sys,json; print(json.load(sys.stdin).get("text",""))')"

if [ -z "$TOKEN" ]; then
    echo "ERROR: Token box was empty or cancelled."
    exit 1
fi

mkdir -p "$HOME/.config"
cat > "$TOKEN_FILE" <<TOKEN_EOF
export GITHUB_PERSONAL_ACCESS_TOKEN=$(printf '%q' "$TOKEN")
TOKEN_EOF
chmod 600 "$TOKEN_FILE"
unset TOKEN
unset DIALOG_OUTPUT

echo "[OK] GitHub token saved securely. File permissions: 600"

echo
echo "[6/8] Configuring OpenCode..."
mkdir -p "$HOME/.config/opencode"
if [ -f "$CONFIG" ]; then
    BACKUP="$CONFIG.backup.$(date +%Y%m%d-%H%M%S)"
    cp "$CONFIG" "$BACKUP"
fi

python <<PY
import json, os
config = os.path.expanduser("$CONFIG")
data = {} if not os.path.exists(config) else json.load(open(config))
if not isinstance(data, dict): data = {}
data.setdefault("$schema", "https://opencode.ai/config.json")
mcp = data.setdefault("mcp", {})
mcp["github"] = {
    "type": "local",
    "command": ["$BIN", "stdio"],
    "enabled": True,
    "environment": {"GITHUB_PERSONAL_ACCESS_TOKEN": "{env:GITHUB_PERSONAL_ACCESS_TOKEN}"}
}
with open(config, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\\n")
PY

echo
echo "[7/8] Creating GitHub MCP launcher..."
cat > "$PREFIX/bin/github-mcp" <<'LAUNCH_EOF'
#!/data/data/com.termux/files/usr/bin/bash
set -e
TOKEN_FILE="$HOME/.config/github-mcp.env"
if [ ! -f "$TOKEN_FILE" ]; then
    echo "ERROR: GitHub token file not found: $TOKEN_FILE"
    exit 1
fi
set -a
. "$TOKEN_FILE"
set +a
exec "$PREFIX/bin/github-mcp-server" stdio
LAUNCH_EOF
chmod 755 "$PREFIX/bin/github-mcp"

echo
echo "[8/8] Verifying installation..."
echo "Binary: $(which github-mcp-server)"
echo "Launcher: $(which github-mcp)"
echo "OpenCode config: $CONFIG"
echo "Token file: $TOKEN_FILE"
echo
echo "=========================================="
echo " GitHub MCP INSTALLATION COMPLETE"
echo "=========================================="
echo "Run: opencode mcp list"
echo "Then: opencode"
echo "Inside OpenCode, GitHub MCP should appear as: github"
echo "Manual launcher: github-mcp"
echo "=========================================="
