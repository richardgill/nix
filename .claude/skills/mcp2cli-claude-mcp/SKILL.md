---
name: mcp2cli-claude-mcp
description: |
  An MCP (Slack, Notion, ...) in mcp2cli by reusing the OAuth client_id + redirect_uri that Claude Code registers.
  Triggers: "setup mcp" "setup notion mcp", "setup slack mcp", "bake mcp2cli", "fake claude mcp client".
---

# Fake Claude's OAuth client in mcp2cli

Hosted MCPs only accept pre-registered OAuth clients (Slack disallows DCR entirely). Rather than installing Claude Code's plugin to bootstrap auth, reuse the client_id + redirect_uri that Claude publishes — directly from mcp2cli.

Slack values are published at https://github.com/slackapi/slack-mcp-plugin. For other servers, grep the Claude plugin cache:

```bash
grep -rn 'client_id\|clientId\|redirect' ~/.claude/plugins/cache/claude-plugins-official/
```

## 1) Bake

No-auth (Answer Overflow — Discord search):

```bash
mcp2cli bake create discord-search --mcp https://www.answeroverflow.com/mcp
```

DCR-capable (Notion):

```bash
mcp2cli bake create notion --mcp https://mcp.notion.com/mcp --oauth
```

DCR-less (Slack) — pin both values:

```bash
mcp2cli bake create slack \
  --mcp https://mcp.slack.com/mcp --oauth \
  --oauth-client-id 1601185624273.8899143856786 \
  --oauth-redirect-uri http://localhost:3118/callback
```

## 2) Trigger OAuth

```bash
mcp2cli @slack --list   # opens browser → consent → tokens cached
```

Tokens land in `~/.cache/mcp2cli/oauth/<hash>/tokens.json` and refresh automatically. To re-auth, delete `tokens.json` and re-run. Locate a cache dir by server URL:

```bash
grep -l "mcp.slack.com" ~/.cache/mcp2cli/oauth/*/client.json
```

## Gotcha: port 3118

Claude Code desktop holds `127.0.0.1:3118` while running, which blocks mcp2cli's callback server. Quit Claude Code before auth or re-auth.

## 3) Create a skill

Path: `./flake/modules/home-manager/dot-files/ai-agents/shared/skills/<server>/SKILL.md`

````md
---
name: slack
description: Use the baked Slack MCP via mcp2cli.
---

Use `mcp2cli @slack` for Slack operations.

Discover tools:

```bash
mcp2cli @slack --list --verbose     # exploration
mcp2cli @slack --search <term>      # focused lookup
```

Then call: `mcp2cli @slack <tool-name> ...`
````

$ARGUMENTS
