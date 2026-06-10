---
name: neon
description: Use the read-only Neon MCP via mcpc.
---

Use `mcpc @neon` for read-only Neon operations scoped to querying, schema, branches, and docs.

If the session is missing or unauthorized, ask Richard to run:

```bash
mcpc login 'https://mcp.neon.tech/mcp?readonly=true&category=querying&category=schema&category=branches&category=docs'
mcpc connect ~/.config/mcpc/mcp.json:neon @neon
```

To discover what the Neon MCP can do:

```bash
mcpc @neon tools-list --full
mcpc @neon grep <term>
mcpc @neon tools-get <tool>
```

When you need to perform a Neon task, first use discovery to find the right tool, then call it with `mcpc @neon tools-call <tool> ...`.
