# OpenCode + oh-my-opencode-slim on Termux/Android

## Complete installation, configuration, free-model, fallback, troubleshooting, and maintenance guide

> **Target:** Termux on Android, ARM64/aarch64\
> **OpenCode:** installed through the Hope2333 Termux package\
> **oh-my-opencode-slim:** Node/npm-compatible installation path\
> **Goal:** a practical, reproducible setup with Kilo + OpenCode Zen
> free models, safe fallbacks, MCPs, agents, LSP, and recovery
> instructions.

## What's in this repo

```text
termux-opencode-setup/
├── README.md                      # this guide
├── configs/
│   ├── oh-my-opencode-slim.json   # 3 working presets: free, opencode-free, kilo-free
│   └── opencode.json.example      # sanitized opencode.json (GitHub + Playwright MCPs)
├── templates/
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

This guide sets up:

- OpenCode on Termux/Android
- Node.js + npm
- oh-my-opencode-slim
- OpenCode agent orchestration
- Orchestrator / Oracle / Explorer / Librarian / Designer / Fixer /
  Councillor agents
- LSP integration
- Optional background subagents
- Optional Exa web search integration
- OpenCode Zen models
- Kilo Gateway models
- Free-model-first routing
- Model fallbacks
- Provider authentication
- GitHub MCP (remote) + Playwright MCP (local via CDP)
- Extra skills (web testing, frontend design, MCP builder, PDF)
- Configuration backup and recovery
- Verification and troubleshooting
- Safe cleanup
- Updating and rollback

The setup deliberately avoids requiring the desktop Companion
application.

---

# 2. Important architecture

Termux is not ordinary Linux.

Android uses **Bionic libc**, while OpenCode's Linux binary uses
**glibc**. The Termux OpenCode project therefore supplies a
compatibility wrapper and requires glibc-related packages.

The working installation in this setup is:

```text
Termux
  |
  +-- /data/data/com.termux/files/usr/bin/opencode
  |      Termux launcher
  |
  +-- /data/data/com.termux/files/usr/lib/opencode/runtime/opencode
         OpenCode runtime
```

Do not replace the Termux launcher with a symlink.

The launcher calculates its runtime path relative to itself. Moving or
symlinking it can cause:

```text
runtime not found
```

Keep the original executable in `$PREFIX/bin`.

---

# 3. Requirements

Recommended:

- Termux from a maintained source
- ARM64/aarch64 Android device
- Internet connection
- Enough storage for OpenCode, Node, npm packages, and plugin
  dependencies
- A provider account/API/OAuth login for whichever models you intend
  to use

Check architecture:

```bash
uname -m
```

Expected:

```text
aarch64
```

Check Termux:

```bash
echo "$PREFIX"
```

Expected:

```text
/data/data/com.termux/files/usr
```

---

# 4. Update Termux

Run:

```bash
pkg update -y
pkg upgrade -y
```

Install basic utilities:

```bash
pkg install -y wget curl git which jq tar
```

Optional but useful:

```bash
pkg install -y ripgrep fd
```

Verify:

```bash
which wget
which curl
which git
which which
```

---

# 5. Install OpenCode on Termux

## 5.1 Install glibc repository

```bash
apt install -y glibc-repo
apt update
```

Install the required runtime packages:

```bash
apt install -y glibc openssl-glibc
```

---

## 5.2 Download the OpenCode Termux package

The exact release asset name changes with releases.

Do not guess an asset called:

```text
opencode_aarch64.deb
```

Use the actual versioned asset from the release page.

Example:

```bash
cd ~
wget -O opencode.deb \
  https://github.com/Hope2333/opencode-termux/releases/download/Push260719/opencode_1.18.7_aarch64.deb
```

Check the downloaded file:

```bash
ls -lh ~/opencode.deb
file ~/opencode.deb
```

---

## 5.3 Install the package

```bash
dpkg -i ~/opencode.deb
```

If dependencies are reported:

```bash
apt install -f -y
```

Verify:

```bash
which opencode
```

Expected:

```text
/data/data/com.termux/files/usr/bin/opencode
```

Then:

```bash
opencode --version
```

---

## 5.4 Verify the launcher

Run:

```bash
head -20 "$(which opencode)"
```

The Termux launcher should refer to a runtime relative to its own
location.

Do not replace it with:

```bash
ln -s ...
```

Do not move it into:

```text
~/.local/bin/
```

unless you understand the launcher's relative-path behavior.

---

# 6. Install Node.js

oh-my-opencode-slim publishes a Node-compatible CLI, so Bun is not
mandatory for this setup.

Install Node:

```bash
pkg install -y nodejs
```

Verify:

```bash
node --version
npm --version
npx --version
```

A working installation should return all three versions.

Test npx:

```bash
npx cowsay "Termux npx works"
```

If `cowsay` is downloaded and runs, npm/npx is functioning.

---

# 7. Install oh-my-opencode-slim

## Preferred normal attempt

Try the published CLI:

```bash
npx oh-my-opencode-slim@latest install
```

For Termux, skip the desktop Companion:

```bash
npx oh-my-opencode-slim@latest install \
  --companion=no
```

For a non-interactive installation:

```bash
npx oh-my-opencode-slim@latest install \
  --no-tui \
  --skills=no \
  --companion=no \
  --background-subagents=no
```

Valid current installer options include:

```text
--skills=yes|no|force
--companion=ask|yes|no
--preset=<name>
--background-subagents=ask|yes|no
--background-subagents-target=<path>
--no-tui
--dry-run
--reset
```

Do **not** use:

```text
--tmux=no
```

unless a future installer explicitly adds that option.

---

# 8. Termux-specific oh-my-opencode-slim fallback installation

On Termux, npm's native dependency installation can fail.

A known failure is:

```text
@ast-grep/cli
Failed to locate @ast-grep/cli native binary.
```

If that happens, do not repeatedly reinstall everything.

Use a local package extraction.

```bash
cd ~
rm -rf ~/omo-slim-test
mkdir -p ~/omo-slim-test
cd ~/omo-slim-test
```

Download the package metadata:

```bash
npm pack oh-my-opencode-slim@latest
```

Extract it:

```bash
tar -xzf oh-my-opencode-slim-*.tgz
cd package
```

Install JavaScript dependencies while skipping native postinstall
scripts:

```bash
npm install --ignore-scripts
```

This is specifically a Termux workaround.

Then test the CLI:

```bash
node dist/cli/index.js --help
```

You should see the installer help.

---

# 9. Install from the local extracted package

Run:

```bash
cd ~/omo-slim-test/package
```

Then:

```bash
node dist/cli/index.js install \
  --reset \
  --no-tui \
  --skills=no \
  --companion=no \
  --background-subagents=no
```

A successful installation should report:

```text
[ok] OpenCode 1.x detected
[ok] Plugin added
[ok] TUI badge added
[ok] Default agents disabled
[ok] LSP enabled
[ok] Config written
★ Installation complete!
```

The installer may say:

```text
Local development install - cache warm-up not required
```

That means the plugin is currently being loaded from the local
directory.

Do not delete that directory until the plugin has been migrated to a
permanent location.

---

# 10. Understand the OpenCode configuration files

> **Note:** OpenCode accepts both `opencode.json` and `opencode.jsonc`
> (JSON with comments/trailing commas). This setup uses `opencode.json`.

Global configuration:

```text
~/.config/opencode/opencode.json
```

oh-my-opencode-slim configuration:

```text
~/.config/opencode/oh-my-opencode-slim.json
```

TUI configuration:

```text
~/.config/opencode/tui.json
```

Check:

```bash
cat ~/.config/opencode/opencode.json
```

and:

```bash
cat ~/.config/opencode/oh-my-opencode-slim.json
```

---

# 11. Expected plugin configuration

A local-development installation can look like:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": [
    "/data/data/com.termux/files/home/omo-slim-test/package"
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
```

This is valid for the temporary local setup.

Later, migrate the plugin to:

```text
~/.config/opencode/local-plugins/
```

and change the config to the permanent plugin path.

---

# 12. Verify oh-my-opencode-slim agents

Run:

```bash
opencode agent list
```

Look for agents such as:

```text
orchestrator
oracle
explorer
librarian
designer
fixer
councillor
```

Also expect OpenCode's normal agents such as:

```text
build
plan
summary
title
compaction
```

The exact list can change between OpenCode and OmO releases.

---

# 13. Authenticate providers

Start OpenCode:

```bash
opencode
```

Use:

```text
/connect
```

or the provider-specific authentication flow available in your OpenCode
version.

The CLI also supports:

```bash
opencode auth login
```

Check available models:

```bash
opencode models
```

Refresh the catalog:

```bash
opencode models --refresh
```

This setup uses **OpenCode Zen** and **Kilo Gateway** credentials
(`opencode auth list` should show both).

---

# 14. Model ID format

OpenCode model IDs normally follow:

```text
provider_id/model_id
```

For example:

```text
opencode/model-name
```

For a custom provider, the first component is the provider key from the
`provider` configuration.

Do not blindly invent provider prefixes.

Always verify:

```bash
opencode models
```

before assigning a model to an agent.

---

# 15. OpenCode Zen

OpenCode documents Zen as an OpenCode model provider and publishes its
model catalog at:

```text
https://opencode.ai/zen/v1/models
```

Refresh the OpenCode catalog:

```bash
opencode models --refresh
```

Then inspect Zen models:

```bash
opencode models | grep '^opencode/'
```

Free Zen models end in `-free`, e.g.:

```text
opencode/muse-spark-1.3-contributor-free
opencode/mimo-v2.5-free
opencode/nemotron-3-ultra-free
opencode/nemotron-3.5-lightning-free
```

Do not assume every model has the same reasoning variant.

For example, do not automatically put:

```text
variant: high
```

on every model.

Variants are model-specific.

Use the variants exposed by the current model catalog.

---

# 16. Kilo Gateway

Kilo's gateway model catalog:

```text
https://api.kilo.ai/api/gateway/models
```

Use the live catalog to determine current model IDs and which models are
free (each entry has an `isFree` flag; free IDs end in `:free`).

A free model can stop being free or be removed, so treat the gateway
response as the source of truth.

Useful command:

```bash
wget -qO- https://api.kilo.ai/api/gateway/models | jq .
```

If jq is unavailable:

```bash
wget -qO- https://api.kilo.ai/api/gateway/models
```

Kilo model references use the `kilo/` provider key:

```text
kilo/nvidia/nemotron-3-ultra-550b-a55b:free
kilo/poolside/laguna-s-2.1:free
kilo/nex-agi/nex-n2.5-pro:free
```

Verify locally:

```bash
opencode models | grep -E 'free'
```

---

# 17. Free-model strategy

A practical free-first setup should prioritize:

1. Kilo's free router if available
2. Strong Kilo free coding models
3. Strong OpenCode Zen free models
4. Fast models for exploration
5. Reasoning-capable models for Oracle/Fixer
6. Lightweight models for Librarian/Explorer

Do not make DeepSeek mandatory if it is unavailable in your account.

This guide deliberately does not require DeepSeek.

---

# 18. Recommended role strategy

`configs/oh-my-opencode-slim.json` ships three presets (switch at
runtime with `/preset`):

- `free` (active) — mixed: 5 of 7 agents on Zen (~70%), 2 on Kilo (~30%)
- `opencode-free` — 100% Zen free models
- `kilo-free` — 100% Kilo free models

The `free` preset assignments:

## Orchestrator

Purpose:

- Main planning
- Delegation
- Agent coordination
- Tool use
- Multi-step work

Configured:

```text
opencode/muse-spark-1.3-contributor-free (primary)
  → opencode/nemotron-3-ultra-free (automatic fallback on rate limit)
```

The `model` array is a failover chain (slim's foreground fallback).

---

## Oracle

Purpose:

- Difficult reasoning
- Architecture
- Debugging
- Code review
- Hard decisions

`free` preset:

```text
kilo/nvidia/nemotron-3-super-120b-a12b:free (variant: max)
```

`opencode-free` preset: `opencode/big-pickle` (variant: max).

---

## Explorer

Purpose:

- Fast repository search
- Codebase exploration
- Finding files
- Lightweight reasoning

Configured (`free` / `opencode-free`):

```text
opencode/nemotron-3.5-lightning-free
```

`kilo-free` preset: `kilo/nvidia/nemotron-3.5-lightning:free`.

---

## Librarian

Purpose:

- Documentation
- Context retrieval
- MCP use
- Research

Configured: same fast model as Explorer (+ context7, gh_grep MCPs).

---

## Designer

Purpose:

- UI
- Architecture presentation
- Front-end implementation
- Visual reasoning where supported

`free` / `kilo-free` presets:

```text
kilo/nex-agi/nex-n2.5-pro:free (variant: medium)
```

`opencode-free` preset: `opencode/mimo-v2.5-free` (variant: medium).

---

## Fixer

Purpose:

- Debugging
- Refactoring
- Repairing broken code
- Test failures

`free` / `opencode-free` presets:

```text
opencode/muse-spark-1.3-contributor-free (variant: high)
```

`kilo-free` preset: `kilo/poolside/laguna-s-2.1:free`
(code-specialized, variant: high).

---

## Observer

Purpose:

- Read-only visual analysis (images, screenshots, PDFs)

`free` / `opencode-free` presets: `opencode/mimo-v2.5-free`
(variant: low). `kilo-free` preset:
`kilo/inclusionai/ling-3.0-flash-vl:free` (vision-language).

Enabled via `"disabled_agents": []`.

---

## Council

Purpose:

- Independent review
- Second opinion
- Design debate
- Architecture validation

Council agent: Zen flagship in `free`/`opencode-free`, Kilo Ultra 550B
in `kilo-free`.

Councillors (`free-diverse` preset, mixed providers for consensus):

```text
opencode/nemotron-3-ultra-free
kilo/nvidia/nemotron-3-ultra-550b-a55b:free
kilo/nex-agi/nex-n2.5-pro:free
```

---

# 19. Fallback model design

A fallback chain should be based on models you have actually verified.

Do not put fictional or unverified model IDs into configuration.

First:

```bash
opencode models
```

Then copy the exact provider/model IDs shown by OpenCode.

This setup uses two fallback mechanisms:

1. **Per-agent model arrays** (oh-my-opencode-slim foreground failover):

```json
"orchestrator": {
  "model": [
    "opencode/muse-spark-1.3-contributor-free",
    "opencode/nemotron-3-ultra-free"
  ],
  "variant": "high"
}
```

2. **Manual preset switching** at runtime:

```text
/preset
```

(`free` → `opencode-free` → `kilo-free` if one provider has issues.)

Always check the installed schema before assuming a field accepts an
array:

```bash
cat ~/omo-slim-test/package/oh-my-opencode-slim.schema.json
```

---

# 20. Example OmO preset structure

All three working presets (`free`, `opencode-free`, `kilo-free`) are in
`configs/oh-my-opencode-slim.json`. A safe baseline structure is:

```json
{
  "$schema": "https://unpkg.com/oh-my-opencode-slim@latest/oh-my-opencode-slim.schema.json",
  "preset": "free",
  "disabled_agents": [],
  "presets": {
    "free": {
      "orchestrator": {
        "model": [
          "opencode/muse-spark-1.3-contributor-free",
          "opencode/nemotron-3-ultra-free"
        ],
        "variant": "high",
        "skills": ["*"],
        "mcps": ["*", "!context7"]
      },
      "oracle": {
        "model": "kilo/nvidia/nemotron-3-super-120b-a12b:free",
        "variant": "max",
        "skills": ["simplify"],
        "mcps": []
      },
      "explorer": {
        "model": "opencode/nemotron-3.5-lightning-free",
        "skills": [],
        "mcps": []
      },
      "librarian": {
        "model": "opencode/nemotron-3.5-lightning-free",
        "skills": [],
        "mcps": ["context7", "gh_grep"]
      },
      "designer": {
        "model": "kilo/nex-agi/nex-n2.5-pro:free",
        "variant": "medium",
        "skills": [],
        "mcps": []
      },
      "fixer": {
        "model": "opencode/muse-spark-1.3-contributor-free",
        "variant": "high",
        "skills": [],
        "mcps": []
      },
      "observer": {
        "model": "opencode/mimo-v2.5-free",
        "variant": "low",
        "skills": [],
        "mcps": []
      },
      "council": {
        "model": "opencode/nemotron-3-ultra-free",
        "variant": "high",
        "skills": [],
        "mcps": []
      }
    }
  },
  "council": {
    "default_preset": "free-diverse",
    "presets": {
      "free-diverse": {
        "alpha": { "model": "opencode/nemotron-3-ultra-free", "variant": "high" },
        "beta": { "model": "kilo/nvidia/nemotron-3-ultra-550b-a55b:free", "variant": "high" },
        "gamma": { "model": "kilo/nex-agi/nex-n2.5-pro:free", "variant": "medium" }
      }
    }
  }
}
```

Replace model IDs only with IDs that appear in:

```bash
opencode models
```

---

# 21. MCP configuration

This setup uses four MCP servers (see `configs/opencode.json.example`):

```text
github      remote  https://api.githubcopilot.com/mcp/   (PAT auth, oauth: false)
playwright  local   node wrapper + --cdp-endpoint http://127.0.0.1:9222
gh_grep     remote  https://mcp.grep.app
context7    remote  https://mcp.context7.com/mcp
```

Verify:

```bash
opencode mcp list
```

If an agent has:

```json
"mcps": [
  "context7",
  "gh_grep"
]
```

the corresponding integrations must actually exist.

If an MCP fails, the model itself may still work.

---

# 22. Skills

The installer supports:

```text
--skills=yes
--skills=no
--skills=force
```

For a minimal Termux installation:

```bash
--skills=no
```

For the full OmO skill set:

```bash
--skills=yes
```

If updating an existing installation and you specifically want bundled
skills refreshed:

```bash
--skills=force
```

Skills can increase package size and dependency complexity.

Extra skills used here (see `skills/SKILLS.md`):
`webapp-testing`, `frontend-design`, `mcp-builder`, `skill-creator`,
`pdf` — from `anthropics/skills`, installed into
`~/.config/opencode/skills/`.

---

# 23. Background subagents

OmO can configure OpenCode's experimental background subagents.

The installer can be run with:

```bash
--background-subagents=yes
```

or:

```bash
--background-subagents=no
```

To enable them manually:

```bash
export OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS=true
export OPENCODE_ENABLE_EXA=1
```

Then:

```bash
opencode
```

Or one command:

```bash
OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS=true \
OPENCODE_ENABLE_EXA=1 \
opencode
```

For a permanent Bash configuration:

```bash
cat >> ~/.bashrc <<'EOF'
export OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS=true
export OPENCODE_ENABLE_EXA=1
EOF
```

Reload:

```bash
source ~/.bashrc
```

Only enable experimental features if you actually need them.

---

# 24. Desktop Companion

Do not install the desktop Companion on Termux unless you have a
specific supported workflow for it.

Use:

```bash
--companion=no
```

This keeps the Termux setup CLI/TUI focused.

---

# 25. Test the complete system

First:

```bash
opencode --version
```

Then:

```bash
opencode models
```

Then:

```bash
opencode agent list
```

Then:

```bash
opencode mcp list
```

Then launch:

```bash
opencode
```

Inside OpenCode:

```text
ping all agents
```

This is the primary OmO integration test.

---

# 26. Test a simple coding request

From a test project:

```bash
mkdir -p ~/opencode-test
cd ~/opencode-test
```

Create a small file:

```bash
cat > hello.py <<'EOF'
def greet(name):
    return f"Hello, {name}!"

print(greet("Termux"))
EOF
```

Launch:

```bash
opencode
```

Ask:

```text
Review hello.py, explain what it does, and suggest one improvement without changing the file.
```

Then test editing:

```text
Improve hello.py with input validation and tests. Explain the changes.
```

---

# 27. Verify LSP

Check the config:

```bash
grep -n '"lsp"' ~/.config/opencode/opencode.json
```

Expected:

```text
"lsp": true
```

LSP functionality also depends on language servers being
installed/configured.

For example, Python projects may require a Python language server;
TypeScript projects may require the appropriate TypeScript tooling.

---

# 28. Backup configuration

Before changing providers/models:

```bash
mkdir -p ~/.config/opencode/backups

cp ~/.config/opencode/opencode.json \
  ~/.config/opencode/backups/opencode.json.$(date +%Y%m%d-%H%M%S)

cp ~/.config/opencode/oh-my-opencode-slim.json \
  ~/.config/opencode/backups/oh-my-opencode-slim.json.$(date +%Y%m%d-%H%M%S)
```

List backups:

```bash
ls -lh ~/.config/opencode/backups
```

---

# 29. Validate JSON

If jq is installed:

```bash
jq empty ~/.config/opencode/oh-my-opencode-slim.json
```

Or with node:

```bash
node -e "JSON.parse(require('fs').readFileSync(process.env.HOME+'/.config/opencode/oh-my-opencode-slim.json','utf8')); console.log('valid JSON')"
```

---

# 30. Safe config rewrite

Before replacing a configuration:

```bash
cp ~/.config/opencode/opencode.json \
   ~/.config/opencode/opencode.json.backup

cp ~/.config/opencode/oh-my-opencode-slim.json \
   ~/.config/opencode/oh-my-opencode-slim.json.backup
```

Then write the new configuration.

Never run:

```bash
rm -rf ~/.config/opencode
```

as a generic troubleshooting step.

That can destroy working authentication/configuration.

---

# 31. Local plugin installation and permanent migration

The temporary installation may contain:

```text
~/omo-slim-test/package
```

and:

```json
"plugin": [
  "/data/data/com.termux/files/home/omo-slim-test/package"
]
```

Do not delete the directory yet.

A permanent Termux-oriented local plugin layout can be:

```text
~/.config/opencode/local-plugins/oh-my-opencode-slim/
```

The OpenCode Termux ecosystem recommends local plugin files as a safer
approach for Android when upstream npm packages contain native
dependencies.

Before migration:

1. Back up the config.
2. Copy the working plugin.
3. Update the plugin path.
4. Restart OpenCode.
5. Run `opencode agent list`.
6. Run `ping all agents`.
7. Only then remove the temporary package.

Example copy:

```bash
mkdir -p ~/.config/opencode/local-plugins

cp -a ~/omo-slim-test/package \
  ~/.config/opencode/local-plugins/oh-my-opencode-slim
```

Then inspect:

```bash
ls -la ~/.config/opencode/local-plugins/oh-my-opencode-slim
```

Do not change the plugin path until you have a backup.

---

# 32. Do not clean the temporary package too early

This is unsafe:

```bash
rm -rf ~/omo-slim-test
```

if your `opencode.json` still contains:

```text
~/omo-slim-test/package
```

First migrate and verify.

Only after successful verification:

```bash
rm -rf ~/omo-slim-test
```

---

# 33. OpenCode detection troubleshooting

If OmO says:

```text
OpenCode is not installed on this system.
```

test:

```bash
which opencode
```

then:

```bash
opencode --version
```

Then test Node's child-process execution:

```bash
node -e '
const {spawnSync}=require("child_process");
const p=spawnSync("opencode",["--version"],{encoding:"utf8"});
console.log("status:",p.status);
console.log("stdout:",p.stdout);
console.log("stderr:",p.stderr);
console.log("error:",p.error);
'
```

Also test the absolute path:

```bash
node -e '
const {spawnSync}=require("child_process");
const p=spawnSync("/data/data/com.termux/files/usr/bin/opencode",["--version"],{encoding:"utf8"});
console.log("status:",p.status);
console.log("stdout:",p.stdout);
console.log("stderr:",p.stderr);
console.log("error:",p.error);
'
```

A healthy result looks like:

```text
status: 0
stdout: 1.18.30
error: undefined
```

then OpenCode itself is working.

Do not reinstall it just because the OmO installer reports a detection
problem.

---

# 34. @ast-grep/cli native dependency failure

If:

```bash
npm install
```

fails with:

```text
Failed to locate @ast-grep/cli native binary
```

use:

```bash
rm -rf node_modules package-lock.json
npm install --ignore-scripts
```

Then:

```bash
node dist/cli/index.js --help
```

This skips npm lifecycle scripts.

Important:

- This is a compatibility workaround.
- Native functionality that specifically depends on an npm postinstall
  binary may still require a Termux-compatible binary.
- Do not assume every ast-grep operation works merely because the CLI
  installer works.

---

# 35. If npx silently returns

Test npx independently:

```bash
npx cowsay "npx works"
```

Then:

```bash
npm view oh-my-opencode-slim@latest version
```

Then:

```bash
npm view oh-my-opencode-slim@latest bin
```

Then:

```bash
npm pack oh-my-opencode-slim@latest
```

If the package can be downloaded but its CLI does not execute through
npx, use the local extraction method in this guide.

---

# 36. If OpenCode launches but a model fails

First:

```bash
opencode models
```

Verify the exact model ID.

Then test the model directly:

```bash
opencode run --model PROVIDER/MODEL "Say hello."
```

Replace:

```text
PROVIDER/MODEL
```

with an ID actually shown by:

```bash
opencode models
```

Do not troubleshoot OmO until the underlying model works directly.

---

# 37. If a Kilo model fails

Check the live Kilo catalog:

```bash
wget -qO- https://api.kilo.ai/api/gateway/models | jq .
```

Then:

```bash
opencode models | grep -i kilo
```

Compare the IDs.

Common causes:

- model removed
- model no longer free
- provider not authenticated
- wrong provider key
- wrong model ID
- model temporarily unavailable
- account restrictions
- gateway/API changes

Do not simply add more guessed model IDs.

---

# 38. If Zen model fails

Check:

```bash
opencode models | grep '^opencode/'
```

Refresh:

```bash
opencode models --refresh
```

Then test the exact model ID shown by OpenCode.

Zen free availability can change, so never treat today's free list as
permanent.

---

# 39. If an OmO agent fails

Determine whether the problem is:

1. Agent configuration
2. Model
3. Provider authentication
4. MCP
5. Skill
6. OpenCode itself

Start with:

```bash
opencode --version
```

Then:

```bash
opencode models
```

Then:

```bash
opencode agent list
```

Then launch OpenCode and test:

```text
ping all agents
```

If one agent fails, test the same model directly.

---

# 40. If MCP causes a failure

Temporarily remove the MCP from that agent's configuration.

For example:

```json
"mcps": []
```

Then restart OpenCode.

If the agent works afterward, the model was probably not the root cause.

---

# 41. If skills cause a failure

Temporarily use:

```json
"skills": []
```

Restart OpenCode.

If the agent works, investigate the particular skill rather than
reinstalling the entire system.

---

# 42. Useful diagnostic commands

OpenCode:

```bash
opencode --version
```

Path:

```bash
which opencode
command -v opencode
```

Node:

```bash
node --version
npm --version
npx --version
```

Agents:

```bash
opencode agent list
```

Models:

```bash
opencode models
```

MCPs:

```bash
opencode mcp list
```

Refresh models:

```bash
opencode models --refresh
```

Config:

```bash
cat ~/.config/opencode/opencode.json
cat ~/.config/opencode/oh-my-opencode-slim.json
```

Plugin directory:

```bash
find ~/.config/opencode -maxdepth 4 -type f | sort
```

---

# 43. Useful environment check

```bash
env | grep -E '^(PATH|HOME|PREFIX|OPENCODE_)='
```

Check PATH:

```bash
printf '%s\n' "$PATH" | tr ':' '\n'
```

Check OpenCode:

```bash
type -a opencode
```

---

# 44. Safe cleanup after installation

Remove downloaded Debian package:

```bash
rm -f ~/opencode.deb
```

Clean apt cache:

```bash
apt clean
apt autoclean
```

Do not run aggressive deletion against OpenCode configuration.

Avoid:

```bash
rm -rf ~/.config/opencode
```

Avoid deleting authentication files unless you intentionally want to log
in again.

---

# 45. Updating OpenCode

Before updating:

```bash
opencode --version
```

Back up config:

```bash
mkdir -p ~/.config/opencode/backups

cp ~/.config/opencode/opencode.json \
  ~/.config/opencode/backups/opencode.json.before-update

cp ~/.config/opencode/oh-my-opencode-slim.json \
  ~/.config/opencode/backups/oh-my-opencode-slim.json.before-update
```

Download the new Termux release package using its exact published asset
name.

Then:

```bash
dpkg -i ~/opencode-new.deb
apt install -f -y
```

Verify:

```bash
opencode --version
```

Then:

```bash
opencode models --refresh
```

Finally:

```bash
opencode agent list
```

---

# 46. Updating oh-my-opencode-slim

Back up:

```bash
cp ~/.config/opencode/oh-my-opencode-slim.json \
   ~/.config/opencode/oh-my-opencode-slim.json.backup
```

Check the installed version:

```bash
npm view oh-my-opencode-slim version
```

If using the local package workflow, create a new clean extraction
rather than modifying the old directory blindly.

Keep the old working package until the new version passes:

```bash
node dist/cli/index.js --help
```

and:

```bash
opencode agent list
```

and:

```text
ping all agents
```

---

# 47. Rollback

If a new plugin configuration breaks OpenCode:

Restore the backup:

```bash
cp ~/.config/opencode/oh-my-opencode-slim.json.backup \
   ~/.config/opencode/oh-my-opencode-slim.json
```

Restore OpenCode config:

```bash
cp ~/.config/opencode/opencode.json.backup \
   ~/.config/opencode/opencode.json
```

Then:

```bash
opencode agent list
```

---

# 48. Recommended daily startup

Basic:

```bash
opencode
```

With experimental background subagents and Exa:

```bash
OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS=true \
OPENCODE_ENABLE_EXA=1 \
opencode
```

Ensure headless Chrome is running first if you use the Playwright MCP
(see §58).

---

# 49. Recommended health check

Run:

```bash
echo "=== OpenCode ==="
opencode --version

echo "=== Binary ==="
which opencode

echo "=== Node ==="
node --version

echo "=== npm ==="
npm --version

echo "=== Models ==="
opencode models | head -30

echo "=== MCPs ==="
opencode mcp list

echo "=== Agents ==="
opencode agent list | grep -E '^(orchestrator|oracle|explorer|librarian|designer|fixer|councillor)'
```

---

# 50. Minimal recovery checklist

If everything suddenly stops working:

```bash
opencode --version
```

If that fails:

```bash
which opencode
```

Then:

```bash
ls -l /data/data/com.termux/files/usr/bin/opencode
```

Then:

```bash
opencode --version
```

If OpenCode works:

```bash
opencode models
```

Then:

```bash
opencode agent list
```

Then inspect:

```bash
cat ~/.config/opencode/opencode.json
```

and:

```bash
cat ~/.config/opencode/oh-my-opencode-slim.json
```

Do not reinstall until these checks identify the failing layer.

---

# 51. Final verification checklist

The installation is considered healthy when all of these work:

```bash
opencode --version
```

```bash
which opencode
```

```bash
node --version
```

```bash
npm --version
```

```bash
opencode models
```

```bash
opencode agent list
```

```bash
opencode mcp list
```

Then:

```bash
opencode
```

Inside OpenCode:

```text
ping all agents
```

A working result means:

- OpenCode runtime works
- Termux/glibc wrapper works
- Node works
- OmO plugin loads
- OmO agents register
- model catalog is available
- provider authentication is available
- agent orchestration can be tested

---

# 52. Rules that prevent most Termux problems

### Rule 1

Do not symlink the Termux OpenCode launcher.

### Rule 2

Do not delete:

```text
~/.config/opencode/
```

as a generic fix.

### Rule 3

Do not guess model IDs.

Use:

```bash
opencode models
```

### Rule 4

Do not assume a model is still free.

Check the live provider catalog.

### Rule 5

Do not use invalid OmO installer options.

For current OmO versions, do not use:

```text
--tmux=no
```

### Rule 6

Do not install the desktop Companion on Termux unless you have a
supported reason.

Use:

```text
--companion=no
```

### Rule 7

If npm fails on a native dependency, use:

```bash
npm install --ignore-scripts
```

only as a deliberate compatibility workaround.

### Rule 8

Do not delete a local OmO plugin while `opencode.json` still points to
it.

### Rule 9

Test the underlying model before blaming the agent framework.

### Rule 10

Back up configs before updates.

---

# 53. Reference URLs

OpenCode documentation:

https://opencode.ai/docs/

OpenCode configuration:

https://opencode.ai/docs/config/

OpenCode models:

https://opencode.ai/docs/models/

OpenCode plugins:

https://opencode.ai/docs/plugins/

OpenCode Zen:

https://opencode.ai/docs/zen/

OpenCode Zen model API:

https://opencode.ai/zen/v1/models

Kilo model gateway:

https://api.kilo.ai/api/gateway/models

Kilo gateway docs:

https://kilo.ai/docs/gateway

OpenCode Termux:

https://github.com/Hope2333/opencode-termux

oh-my-opencode-slim:

https://github.com/alvinunreal/oh-my-opencode-slim

---

# 54. Current known-good Termux installation snapshot

This is the reference state for the setup described in this guide:

```text
Android
  ↓
Termux
  ↓
glibc + openssl-glibc
  ↓
OpenCode 1.18.30
  ↓
Node.js v26.4.0 (npm 11.19.1)
  ↓
oh-my-opencode-slim 2.2.18
  ↓
local plugin installation
  ↓
OpenCode agents
  ↓
Kilo + OpenCode Zen providers
  ↓
free-first model configuration (Zen 70% / Kilo 30%)
```

The exact OpenCode and model versions are expected to change over time.
The installation architecture and troubleshooting principles are more
important than hard-coding old versions.

---

# 55. Playwright MCP on Termux (works via CDP)

Stock `@playwright/mcp` crashes on Termux (`Unsupported platform:
android`) and Playwright cannot download browsers for Android. This
setup works around both:

1. Install the package once:

```bash
mkdir -p ~/.local/share/playwright-mcp
npm install --prefix ~/.local/share/playwright-mcp @playwright/mcp
```

2. Use `mcp/playwright-mcp-wrapper.cjs` (spoofs `linux` platform,
   then loads the real CLI). Copy to `~/.local/bin/`.

3. Install system Chromium and run it headless with remote debugging:

```bash
pkg install -y chromium
```

4. Connect the MCP to it with `--cdp-endpoint http://127.0.0.1:9222`
   (see `configs/opencode.json.example`). The MCP then drives the
   real browser: navigate, snapshot, click, type, screenshot.

No Docker, no Playwright browser download needed.

---

# 56. GitHub MCP (remote, no Docker)

Docker is unavailable on Termux, so this setup uses GitHub's hosted
server with a personal access token:

```json
"github": {
  "type": "remote",
  "url": "https://api.githubcopilot.com/mcp/",
  "enabled": true,
  "oauth": false,
  "headers": {
    "Authorization": "Bearer {env:GITHUB_PERSONAL_ACCESS_TOKEN}"
  }
}
```

Export the token before starting OpenCode:

```bash
export GITHUB_PERSONAL_ACCESS_TOKEN="ghp_YOUR_TOKEN_HERE"
```

---

# 57. Skills in this setup

Bundled (plugin-managed): `codemap`, `deepwork`,
`verification-planning`, `simplify`, `worktrees`, `clonedeps`,
`reflect`, `oh-my-opencode-slim`.

Extra (see `skills/SKILLS.md`): `webapp-testing`, `frontend-design`,
`mcp-builder`, `skill-creator`, `pdf`.

The orchestrator (`"skills": ["*"]`) picks up new skills
automatically; other agents need explicit grants. Restart OpenCode
after installing skills.

---

# 58. Headless-Chrome autostart

The Playwright MCP needs Chrome listening on CDP `:9222` before
OpenCode starts. `mcp/chrome-mcp.sh` is idempotent (exits instantly if
CDP already responds). Hook it into `~/.bashrc`:

```bash
[ -x "$HOME/.local/bin/chrome-mcp.sh" ] && "$HOME/.local/bin/chrome-mcp.sh" >/dev/null 2>&1
```

Optional: with the Termux:Boot app, copy the same script to
`~/.termux/boot/` to start Chrome at device boot.

---

# 59. Starter templates (copy-paste with `cat`)

The `templates/` directory holds minimal starters. Write them with
heredocs — no editor needed.

Minimal `opencode.json`:

```bash
cat > ~/.config/opencode/opencode.json << 'EOF'
{
  "$schema": "https://opencode.ai/config.json",
  "plugin": [
    "~/.config/opencode/local-plugins/oh-my-opencode-slim"
  ],
  "agent": {
    "explore": { "disable": true },
    "general": { "disable": true }
  },
  "lsp": true
}
EOF
```

Minimal slim preset (mixed free models, same as `templates/slim.starter.json`):

```bash
cat > ~/.config/opencode/oh-my-opencode-slim.json << 'EOF'
{
  "$schema": "https://unpkg.com/oh-my-opencode-slim@latest/oh-my-opencode-slim.schema.json",
  "preset": "free",
  "disabled_agents": [],
  "presets": {
    "free": {
      "orchestrator": {
        "model": [
          "opencode/muse-spark-1.3-contributor-free",
          "opencode/nemotron-3-ultra-free"
        ],
        "variant": "high",
        "skills": ["*"],
        "mcps": ["*", "!context7"]
      },
      "oracle": {
        "model": "kilo/nvidia/nemotron-3-super-120b-a12b:free",
        "variant": "max",
        "skills": ["simplify"],
        "mcps": []
      },
      "explorer": {
        "model": "opencode/nemotron-3.5-lightning-free",
        "skills": [],
        "mcps": []
      },
      "librarian": {
        "model": "opencode/nemotron-3.5-lightning-free",
        "skills": [],
        "mcps": ["context7", "gh_grep"]
      },
      "designer": {
        "model": "kilo/nex-agi/nex-n2.5-pro:free",
        "variant": "medium",
        "skills": [],
        "mcps": []
      },
      "fixer": {
        "model": "opencode/muse-spark-1.3-contributor-free",
        "variant": "high",
        "skills": [],
        "mcps": []
      },
      "observer": {
        "model": "opencode/mimo-v2.5-free",
        "variant": "low",
        "skills": [],
        "mcps": []
      },
      "council": {
        "model": "opencode/nemotron-3-ultra-free",
        "variant": "high",
        "skills": [],
        "mcps": []
      }
    }
  }
}
EOF
```

Validate, then restart OpenCode:

```bash
node -e "JSON.parse(require('fs').readFileSync(process.env.HOME+'/.config/opencode/oh-my-opencode-slim.json','utf8')); console.log('valid JSON')"
```

Prefer files over heredocs? Pull them straight from this repo:

```bash
curl -sL -o ~/.config/opencode/oh-my-opencode-slim.json \
  https://raw.githubusercontent.com/senpaiorbit/termux-opencode-setup/main/configs/oh-my-opencode-slim.json
curl -sL -o /tmp/opencode.json.example \
  https://raw.githubusercontent.com/senpaiorbit/termux-opencode-setup/main/configs/opencode.json.example
```

---

## End state

A successful setup should allow:

```bash
opencode
```

with OmO agents available, authenticated providers available, verified
free models configured, LSP enabled, optional background subagents
enabled, and a recoverable configuration.

When model availability changes, update the model IDs from the live
catalogs instead of reinstalling the whole stack.
