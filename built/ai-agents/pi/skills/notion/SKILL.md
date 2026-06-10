---
name: notion
description: Use the Notion MCP via mcpc.
---

Use `mcpc @notion` for Notion operations.

If the session is missing or unauthorized, ask Richard to run:

```bash
mcpc login https://mcp.notion.com/mcp
mcpc connect ~/.config/mcpc/mcp.json:notion @notion
```

To discover what the Notion MCP can do:

```bash
mcpc @notion tools-list --full
mcpc @notion grep <term>
mcpc @notion tools-get <tool>
```

When you need to perform a Notion task, first use discovery to find the right tool, then call it with `mcpc @notion tools-call <tool> ...`.
