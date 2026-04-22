---
name: mcp2cli-claude-mcp
description: |
  Quick workflow for setting up a Claude Code MCP server (Notion example), then switching to mcp2cli + skill-based usage.
  Triggers: "setup notion mcp", "claude mcp add", "disable claude mcp", "use mcp2cli instead", "mcp2cli skill".
---

# Claude MCP -> mcp2cli Skill Workflow (Notion example)

Use this when you want Claude Code to bootstrap a hosted MCP once, then switch to `mcp2cli`.

## 1) Install the Claude Code plugin

In Claude Code, run `/plugins`, install the MCP plugin you want, then make sure it works there first.

For Notion:

- plugin MCP config: `~/.claude/plugins/cache/claude-plugins-official/notion/0.1.0/.mcp.json`
- hosted MCP URL: `https://mcp.notion.com/mcp`

## 2) Reuse Claude's OAuth in mcp2cli

Confirm Claude stored the hosted MCP credentials:

```bash
rg -n "notion|mcpOAuth|serverUrl" ~/.claude/.credentials.json
```

If needed, copy the Notion token from `~/.claude/.credentials.json` into mcp2cli's cache:

- cache dir: `~/.cache/mcp2cli/oauth/1cbd18bf1818c780/`
- token file: `~/.cache/mcp2cli/oauth/1cbd18bf1818c780/tokens.json`

check it works using mcp2cli:

```bash
mcp2cli \
  --mcp https://mcp.notion.com/mcp \
  --oauth \
  --list
```

## 3) Bake it

```bash
mcp2cli bake create notion \
  --mcp https://mcp.notion.com/mcp \
  --oauth
```
Check it works
```bash
mcp2cli @notion --list
```

## 4) Disable the Claude Code plugin

List plugins first:

```bash
claude plugin list
```

Then disable the plugin:

```bash
claude plugin disable notion@claude-plugins-official
claude plugin list
```

## 5) Create a shared skill for the MCP

After baking the MCP as `@notion`, create a new skill under:


Example skill

Path:

- `./flake/modules/home-manager/dot-files/ai-agents/shared/skills/notion/SKILL.md`

```md
---
name: notion
description: Use the baked Notion MCP via mcp2cli.
---

Use `mcp2cli @notion` for Notion operations.

To discover what the Notion MCP can do:

- best for exploration:

```bash
mcp2cli @notion --list --verbose
```

- best for focused lookup:

```bash
mcp2cli @notion --search <term>
```

When you need to perform a Notion task, first use the discovery commands above to find the right tool, then call it with `mcp2cli @notion ...`.
```

$ARGUMENTS
