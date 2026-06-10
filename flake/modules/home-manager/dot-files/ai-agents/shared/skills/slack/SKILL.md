---
name: slack
description: Use the Slack MCP via mcpc.
---

Use `mcpc @slack` for Slack operations.


If the session is missing or unauthorized, ask Richard to run:

```bash
mcpc login https://mcp.slack.com/mcp --client-id 1601185624273.8899143856786 --callback-port 3118
mcpc connect ~/.config/mcpc/mcp.json:slack @slack
```

Note: re-auth may need `localhost` callback support in mcpc: https://github.com/apify/mcpc/issues/269

To discover what the Slack MCP can do:

```bash
mcpc @slack tools-list --full
mcpc @slack grep <term>
mcpc @slack tools-get <tool>
```

When you need to perform a Slack task, first use discovery to find the right tool, then call it with `mcpc @slack tools-call <tool> ...`.
