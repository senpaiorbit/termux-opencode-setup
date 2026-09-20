cat > ~/setup-opencode.sh <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "=========================================="
echo " OpenCode + oh-my-opencode-slim Termux"
echo "=========================================="

# ---------- Checks ----------
if [ -z "$PREFIX" ]; then
    echo "ERROR: This script must be run inside Termux."
    exit 1
fi

ARCH="$(uname -m)"
if [ "$ARCH" != "aarch64" ]; then
    echo "ERROR: This setup expects ARM64/aarch64."
    echo "Detected: $ARCH"
    exit 1
fi

echo "[OK] Termux detected"
echo "[OK] Architecture: $ARCH"

# ---------- Update Termux ----------
echo
echo "[1/10] Updating Termux..."
pkg update -y
pkg upgrade -y

# ---------- Basic tools ----------
echo
echo "[2/10] Installing basic utilities..."
pkg install -y wget curl git which jq tar

# Optional utilities
pkg install -y ripgrep fd || true

# ---------- OpenCode glibc ----------
echo
echo "[3/10] Installing glibc repository..."
apt install -y glibc-repo
apt update

echo
echo "[4/10] Installing OpenCode runtime dependencies..."
apt install -y glibc openssl-glibc

# ---------- Find latest OpenCode Termux release ----------
echo
echo "[5/10] Finding latest OpenCode Termux ARM64 release..."

REPO="Hope2333/opencode-termux"

RELEASE_JSON="$PREFIX/tmp/opencode-release.json"
mkdir -p "$PREFIX/tmp"

curl -fsSL \
    "https://api.github.com/repos/$REPO/releases/latest" \
    -o "$RELEASE_JSON"

ASSET_URL="$(
    jq -r '
        .assets[]
        | select(.name | test("aarch64.*\\.deb$"))
        | .browser_download_url
    ' "$RELEASE_JSON" | head -n 1
)"

if [ -z "$ASSET_URL" ] || [ "$ASSET_URL" = "null" ]; then
    echo
    echo "ERROR: Could not find an aarch64 OpenCode .deb."
    echo "Check:"
    echo "https://github.com/$REPO/releases"
    exit 1
fi

ASSET_NAME="$(basename "$ASSET_URL")"

echo "Found: $ASSET_NAME"
echo "Downloading..."

cd "$HOME"

curl -fL \
    "$ASSET_URL" \
    -o "$HOME/opencode.deb"

echo
echo "Downloaded:"
ls -lh "$HOME/opencode.deb"

# ---------- Install OpenCode ----------
echo
echo "[6/10] Installing OpenCode..."

dpkg -i "$HOME/opencode.deb" || true
apt install -f -y

if ! command -v opencode >/dev/null 2>&1; then
    echo "ERROR: OpenCode installation failed."
    exit 1
fi

echo
echo "OpenCode:"
opencode --version || true

echo
echo "OpenCode path:"
which opencode

# Do NOT replace the Termux launcher with a symlink.
# The repository explicitly warns that the launcher uses a relative
# runtime path. 
echo
echo "[OK] Keeping original Termux OpenCode launcher."

# ---------- Node.js ----------
echo
echo "[7/10] Installing Node.js + npm..."

pkg install -y nodejs

echo
node --version
npm --version
npx --version

# ---------- oh-my-opencode-slim ----------
echo
echo "[8/10] Installing oh-my-opencode-slim..."

if npx oh-my-opencode-slim@latest install \
    --no-tui \
    --skills=no \
    --companion=no \
    --background-subagents=no
then
    echo
    echo "[OK] Normal oh-my-opencode-slim installation succeeded."
else
    echo
    echo "[WARN] Normal npm installation failed."
    echo "[INFO] Using Termux local-package fallback..."

    rm -rf "$HOME/omo-slim-test"
    mkdir -p "$HOME/omo-slim-test"
    cd "$HOME/omo-slim-test"

    npm pack oh-my-opencode-slim@latest

    tar -xzf oh-my-opencode-slim-*.tgz

    cd package

    npm install --ignore-scripts

    node dist/cli/index.js --help

    node dist/cli/index.js install \
        --reset \
        --no-tui \
        --skills=no \
        --companion=no \
        --background-subagents=no

    echo
    echo "[OK] Local fallback installation completed."
fi

# ---------- Configuration ----------
echo
echo "[9/10] Installing repository configuration..."

mkdir -p "$HOME/.config/opencode"
mkdir -p "$HOME/.config/opencode/backups"

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

# Backup existing configs
if [ -f "$HOME/.config/opencode/opencode.json" ]; then
    cp "$HOME/.config/opencode/opencode.json" \
       "$HOME/.config/opencode/backups/opencode.json.$TIMESTAMP"
fi

if [ -f "$HOME/.config/opencode/oh-my-opencode-slim.json" ]; then
    cp "$HOME/.config/opencode/oh-my-opencode-slim.json" \
       "$HOME/.config/opencode/backups/oh-my-opencode-slim.json.$TIMESTAMP"
fi

# Pull the repository's maintained slim configuration
curl -fsSL \
    -o "$HOME/.config/opencode/oh-my-opencode-slim.json" \
    "https://raw.githubusercontent.com/senpaiorbit/termux-opencode-setup/main/configs/oh-my-opencode-slim.json"

# Create minimal OpenCode configuration
cat > "$HOME/.config/opencode/opencode.json" <<'JSON'
{
  "$schema": "https://opencode.ai/config.json",
  "agent": {
    "explore": {
      "disable": true
    },
    "general": {
      "disable": true
    }
  },
  "lsp": true
}
JSON

# If the local fallback plugin exists, configure it.
if [ -d "$HOME/omo-slim-test/package" ]; then
    cat > "$HOME/.config/opencode/opencode.json" <<JSON
{
  "\$schema": "https://opencode.ai/config.json",
  "plugin": [
    "$HOME/omo-slim-test/package"
  ],
  "agent": {
    "explore": {
      "disable": true
    },
    "general": {
      "disable": true
    }
  },
  "lsp": true
}
JSON
fi

# ---------- Validate ----------
echo
echo "[10/10] Validating installation..."

node -e "
const fs=require('fs');
const p=process.env.HOME+'/.config/opencode/oh-my-opencode-slim.json';
JSON.parse(fs.readFileSync(p,'utf8'));
console.log('oh-my-opencode-slim.json: valid JSON');
"

echo
echo "=========================================="
echo " INSTALLATION COMPLETE"
echo "=========================================="

echo
echo "OpenCode:"
opencode --version || true

echo
echo "Binary:"
which opencode

echo
echo "Node:"
node --version

echo
echo "npm:"
npm --version

echo
echo "Agents:"
opencode agent list || true

echo
echo "Models:"
opencode models || true

echo
echo "MCP:"
opencode mcp list || true

echo
echo "Config:"
echo "$HOME/.config/opencode/opencode.json"

echo
echo "Slim config:"
echo "$HOME/.config/opencode/oh-my-opencode-slim.json"

echo
echo "=========================================="
echo " Start OpenCode with:"
echo "   opencode"
echo "=========================================="
EOF

chmod +x ~/setup-opencode.sh
sh ~/setup-opencode.sh
