---
name: buffer
description: Manage social media posts with the Buffer MCP via mcpc.
---

Use `mcpc @buffer` for Buffer operations.

Unless Richard explicitly says otherwise, create every requested social post for both the connected Twitter and Bluesky channels. Call `get_account` and `list_channels`, then use the exact channel IDs returned for the `twitter` and `bluesky` services. Treat one requested post as two `create_post` operations, and ask before proceeding if either channel is unavailable.

If the session is missing or unauthorized, ask Richard to run:

```bash
mcpc login https://mcp.buffer.com/mcp
mcpc connect ~/.config/mcpc/mcp.json:buffer @buffer
```

To discover what the Buffer MCP can do:

```bash
mcpc @buffer tools-list --full
mcpc @buffer grep <term>
mcpc @buffer tools-get <tool>
```

When you need to perform a Buffer task, first use discovery to find the right tool, then call it with `mcpc @buffer tools-call <tool> ...`.
