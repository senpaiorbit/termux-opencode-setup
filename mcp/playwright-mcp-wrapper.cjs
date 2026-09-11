// Playwright MCP launcher for Termux/Android.
//
// Playwright refuses to start on Termux because process.platform is
// "android" ("Unsupported platform: android"), and process.platform is
// non-writable on this Node build (but configurable). Spoof "linux"
// before loading @playwright/mcp.
//
// Prerequisites:
//   npm install --prefix ~/.local/share/playwright-mcp @playwright/mcp
//   cp this file to ~/.local/bin/playwright-mcp-wrapper.cjs
//
// Use with a CDP endpoint (see ../README.md + chrome-mcp.sh), e.g.:
//   node ~/.local/bin/playwright-mcp-wrapper.cjs --cdp-endpoint http://127.0.0.1:9222
Object.defineProperty(process, 'platform', { value: 'linux', configurable: true });
const os = require('os');
os.platform = () => 'linux';
require(process.env.HOME + '/.local/share/playwright-mcp/node_modules/@playwright/mcp/cli.js');
