# OpenCode + oh-my-opencode-slim on Termux/Android

## Complete installation, configuration, free-model, fallback, troubleshooting, and maintenance guide

> **Target:** Termux on Android, ARM64/aarch64\
> **OpenCode:** installed through the Hope2333 Termux package\
> **oh-my-opencode-slim:** Node/npm-compatible installation path\
> **Goal:** a practical, reproducible setup with Kilo + OpenCode Zen
> free models, safe fallbacks, MCPs, agents, LSP, and recovery
> instructions.

## ⚡ Use it now — one command

```bash
curl -sL https://raw.githubusercontent.com/senpaiorbit/termux-opencode-setup/main/templates/quickstart.sh | bash
```

Backs up your current configs, installs the starter `opencode.json` +
the 3-preset slim config (`free`, `opencode-free`, `kilo-free`),
validates JSON. Then restart OpenCode and switch presets with
`/preset`.

## 🔧 Additional setup scripts

```bash
# One-shot Colab MCP (Google T4 GPU) installer
curl -sL https://raw.githubusercontent.com/senpaiorbit/termux-opencode-setup/main/templates/setup-colab-mcp.sh | bash

# One-shot GitHub MCP installer (with termux-dialog token input)
curl -sL https://raw.githubusercontent.com/senpaiorbit/termux-opencode-setup/main/templates/setup-github-mcp.sh | bash
```

## What's in this repo

```text
termux-opencode-setup/
├── README.md                      # this guide
├── configs/
│   ├── oh-my-opencode-slim.json   # 3 working presets: free, opencode-free, kilo-free
│   └── opencode.json.example      # sanitized opencode.json (GitHub + Playwright MCPs)
├── templates/
│   ├── quickstart.sh              # one-shot bootstrap (curl ... | bash)
│   ├── setup-colab-mcp.sh         # one-shot Colab MCP installer
│   ├── setup-github-mcp.sh        # one-shot GitHub MCP installer (dialog token input)
│   ├── opencode.starter.json      # minimal opencode.json starter (cat-ready)
│   └── slim.starter.json          # minimal slim preset starter (cat-ready)
├── mcp/
│   ├── playwright-mcp-wrapper.cjs # Termux platform-spoof launcher for @playwright/mcp
│   └── chrome-mcp.sh              # idempotent headless-Chrome launcher (CDP :9222)
└── skills/
    └── SKILLS.md                  # extra skills manifest + install commands
```

Fast bootstrap from these templates: see §59.

---

## 1. What this guide installs