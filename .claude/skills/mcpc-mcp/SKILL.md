---
name: mcpc-mcp
description: |
  Set up and use hosted MCPs (Slack, Notion, Neon, Answer Overflow, stdio servers) via mcpc.
  Triggers: "setup mcp", "setup notion mcp", "setup slack mcp", "mcpc", "mcp cli".
---

# MCP via mcpc

We use `mcpc`. Config lives at `~/.config/mcpc/mcp.json`, state lives in `~/.mcpc`, and OAuth credentials are stored by mcpc in the OS keychain or its secure fallback.

## Connect configured servers

```bash
mcpc connect ~/.config/mcpc/mcp.json:notion @notion
mcpc connect ~/.config/mcpc/mcp.json:slack @slack
mcpc connect ~/.config/mcpc/mcp.json:neon @neon
mcpc connect ~/.config/mcpc/mcp.json:discord-search @discord-search
mcpc connect ~/.config/mcpc/mcp.json:shadcnblocks @shadcnblocks
```

For bulk startup, include stdio servers explicitly:

```bash
mcpc connect ~/.config/mcpc/mcp.json --stdio
```

## OAuth login

Hosted OAuth servers need a human browser login first:

```bash
mcpc login https://mcp.notion.com/mcp
mcpc login https://mcp.slack.com/mcp --client-id 1601185624273.8899143856786 --callback-port 3118
mcpc login 'https://mcp.neon.tech/mcp?readonly=true&category=querying&category=schema&category=branches&category=docs'
```

After login, connect or restart the session:

```bash
mcpc connect ~/.config/mcpc/mcp.json:slack @slack
mcpc @slack restart
```

## Discover and call tools

```bash
mcpc @slack tools-list --full
mcpc @slack grep <term>
mcpc @slack tools-get <tool>
mcpc @slack tools-call <tool> key:=value
cat args.json | mcpc @slack tools-call <tool>
```

Use `mcpc --json ...` for scripts.
