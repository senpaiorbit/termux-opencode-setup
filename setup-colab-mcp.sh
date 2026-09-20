#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

REPO="https://github.com/bd-loser/colab-mcp-termux.git"
DIR="$HOME/colab-mcp-termux"

echo "=========================================="
echo " Google Colab MCP — Termux Setup"
echo "=========================================="

# --------------------------------------------------
# 1. Verify Termux
# --------------------------------------------------
if [ -z "${PREFIX:-}" ] || [ ! -x "$PREFIX/bin/pkg" ]; then
    echo "ERROR: This script must run inside Termux."
    exit 1
fi

ARCH="$(uname -m)"

if [ "$ARCH" != "aarch64" ]; then
    echo "ERROR: This project requires aarch64/ARM64."
    echo "Detected: $ARCH"
    exit 1
fi

echo "[OK] Termux detected"
echo "[OK] Architecture: $ARCH"

# --------------------------------------------------
# 2. Update Termux
# --------------------------------------------------
echo
echo "[1/6] Updating Termux..."

pkg update -y
pkg upgrade -y

# --------------------------------------------------
# 3. Install prerequisites
# --------------------------------------------------
echo
echo "[2/6] Installing prerequisites..."

pkg install -y \
    python \
    python-pip \
    uv \
    python-rpds-py \
    python-cryptography \
    curl \
    git \
    unzip \
    tar

echo
echo "Python:"
python3 --version

echo
echo "uv:"
uv --version

# --------------------------------------------------
# 4. Clone/update repository
# --------------------------------------------------
echo
echo "[3/6] Getting colab-mcp-termux..."

if [ -d "$DIR/.git" ]; then
    echo "Repository already exists."
    cd "$DIR"

    git fetch origin
    git reset --hard origin/main
else
    rm -rf "$DIR"
    git clone "$REPO" "$DIR"
    cd "$DIR"
fi

echo
echo "Repository:"
git log -1 --oneline

# --------------------------------------------------
# 5. Run official installer
# --------------------------------------------------
echo
echo "[4/6] Installing Colab MCP..."
echo
echo "NOTE:"
echo "- A prebuilt ARM64 wheel will be used if available."
echo "- Otherwise pydantic-core will be compiled."
echo "- Source compilation can take 15-40 minutes."
echo "- Keep Termux open during compilation."
echo

bash install.sh

# --------------------------------------------------
# 6. Authenticate Google Colab
# --------------------------------------------------
echo
echo "=========================================="
echo " Google Colab Authentication"
echo "=========================================="
echo
echo "A Google authorization page will open."
echo "Sign in with the Google account you use"
echo "for Colab and approve access."
echo

bash scripts/colab-auth.sh

# --------------------------------------------------
# 7. Verify GPU
# --------------------------------------------------
echo
echo "=========================================="
echo " Testing Colab GPU"
echo "=========================================="
echo
echo "Requesting a Colab T4..."
echo

bash scripts/verify.sh

# --------------------------------------------------
# 8. Test persistent launcher
# --------------------------------------------------
echo
echo "=========================================="
echo " Installation Complete"
echo "=========================================="

INSTALL_DIR="$HOME/.local/share/colab-mcp"

echo
echo "Persistent launcher:"
echo "$INSTALL_DIR/colab_persistent.py"

echo
echo "DNS launcher:"
echo "$INSTALL_DIR/colab_mcp_dns.py"

echo
echo "OAuth token:"
echo "$HOME/.config/colab-exec/token.json"

echo
echo "Testing persistent launcher syntax..."

python3 -m py_compile \
    "$INSTALL_DIR/colab_persistent.py"

echo "[OK] Persistent launcher is valid."

echo
echo "=========================================="
echo " OpenCode MCP configuration"
echo "=========================================="
echo

cat <<JSON
{
  "mcp": {
    "colab-exec": {
      "type": "local",
      "command": [
        "/data/data/com.termux/files/usr/bin/python3",
        "$INSTALL_DIR/colab_persistent.py"
      ],
      "enabled": true
    }
  }
}
JSON

echo
echo "=========================================="
echo " DONE"
echo "=========================================="
echo
echo "You can now connect the persistent launcher"
echo "to OpenCode."
echo
echo "23 Colab MCP tools are available."
echo
echo "Launcher:"
echo "$INSTALL_DIR/colab_persistent.py"
echo