#!/data/data/com.termux/files/usr/bin/bash
# Idempotent launcher for the headless Chrome used by the Playwright MCP.
# Exits instantly if Chrome/CDP is already up on :9222.
# Install: pkg install -y chromium
# Run at shell start (see README) or via Termux:Boot (~/.termux/boot/).
[ -x /data/data/com.termux/files/usr/bin/chromium-browser ] || exit 0
if curl -s -m 3 http://127.0.0.1:9222/json/version > /dev/null 2>&1; then
  exit 0
fi
mkdir -p "$HOME/.chrome-mcp-profile"
setsid nohup chromium-browser \
  --headless=new --no-sandbox --disable-gpu --disable-dev-shm-usage \
  --remote-debugging-port=9222 \
  --user-data-dir="$HOME/.chrome-mcp-profile" \
  about:blank > "$HOME/.chrome-mcp.log" 2>&1 < /dev/null &
exit 0
