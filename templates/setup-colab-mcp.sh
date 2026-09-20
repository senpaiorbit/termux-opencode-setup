#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

REPO="https://github.com/bd-loser/colab-mcp-termux.git"
DIR="$HOME/colab-mcp-termux"

echo "=========================================="
echo " Google Colab MCP — Termux Setup"
echo "=========================================="

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

echo
echo "[1/6] Updating Termux..."
pkg update -y
pkg upgrade -y

echo
echo "[2/6] Installing prerequisites..."
pkg install -y python python-pip uv python-rpds-py python-cryptography curl git unzip tar

echo
echo "Python:"
python3 --version
echo
echo "uv:"
uv --version

echo
echo "[3/6] Getting colab-mcp-termux..."
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
echo "Repository:"
git log -1 --oneline

echo
echo "[4/6] Installing Colab MCP..."
bash install.sh

echo
echo "=========================================="
echo " Google Colab Authentication"
echo "=========================================="
bash scripts/colab-auth.sh

echo
echo "=========================================="
echo " Testing Colab GPU"
echo "=========================================="
bash scripts/verify.sh

echo
echo "=========================================="
echo " Installation Complete"
echo "=========================================="

INSTALL_DIR="$HOME/.local/share/colab-mcp"
echo
echo "Persistent launcher: $INSTALL_DIR/colab_persistent.py"
echo "DNS launcher: $INSTALL_DIR/colab_mcp_dns.py"
echo "OAuth token: $HOME/.config/colab-exec/token.json"
python3 -m py_compile "$INSTALL_DIR/colab_persistent.py"
echo "[OK] Persistent launcher is valid."
echo
echo "23 Colab MCP tools are available."
echo "Launcher: $INSTALL_DIR/colab_persistent.py"
