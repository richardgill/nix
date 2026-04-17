---
name: slack
description: Use the baked Slack MCP via mcp2cli.
---

Use `mcp2cli @slack` for Slack operations.

To discover what the Slack MCP can do:

- best for exploration:

```bash
mcp2cli @slack --list --verbose
```

- best for focused lookup:

```bash
mcp2cli @slack --search <term>
```

When you need to perform a Slack task, first use the discovery commands above to find the right tool, then call it with `mcp2cli @slack ...`.
