# Skills

Skills live in `~/.config/opencode/skills/<name>/SKILL.md`.
The 8 `oh-my-opencode-slim` bundled skills are managed by the plugin
(`codemap`, `deepwork`, `verification-planning`, `simplify`,
`worktrees`, `clonedeps`, `reflect`, `oh-my-opencode-slim`).
Custom skills placed alongside them are preserved across plugin updates.

The orchestrator in `configs/oh-my-opencode-slim.json` uses
`"skills": ["*"]`, so newly installed skills attach to it
automatically. Other agents need explicit grants per agent.

## Extra skills in this setup (from `anthropics/skills`)

| Skill | Use with |
|---|---|
| `webapp-testing` | Playwright-based web QA; pairs with the playwright MCP |
| `frontend-design` | Visual/UI direction; natural fit for designer |
| `mcp-builder` | Build custom MCP servers (FastMCP / TS SDK) |
| `skill-creator` | Create/improve your own skills |
| `pdf` | Read, merge, split, OCR, fill forms; pairs with observer |

## Install them

```bash
git clone --depth 1 https://github.com/anthropics/skills /tmp/skills-upstream
for s in webapp-testing frontend-design mcp-builder skill-creator pdf; do
  rm -rf ~/.config/opencode/skills/$s
  cp -r /tmp/skills-upstream/skills/$s ~/.config/opencode/skills/$s
done
rm -rf /tmp/skills-upstream
```

Restart OpenCode afterwards. Grant per agent as needed, e.g.
`designer.skills: ["frontend-design"]`, `fixer.skills: ["webapp-testing"]`.
