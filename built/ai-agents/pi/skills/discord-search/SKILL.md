---
name: discord-search
description: Search public Discord help-channel archives via Answer Overflow MCP (mcp2cli @discord-search).
---

Use `mcp2cli @discord-search` to search Answer Overflow — a searchable archive of public Discord help channels.

Known server: **The Shitty Coders Club** — `serverId=1456806362351669492`. Pass `--server-id 1456806362351669492` to scope queries.

To discover tools:

```bash
mcp2cli @discord-search --list --verbose
mcp2cli @discord-search --search <term>
```

Typical workflow:

```bash
# 1. Find a server ID (skip if you already know it)
mcp2cli @discord-search search-servers --query "shitty coders"

# 2. Search threads
mcp2cli @discord-search search-answeroverflow \
  --query "ctx.reload" --server-id 1456806362351669492 --limit 25

# 3. Pull full conversation
mcp2cli @discord-search get-thread-messages --thread-id <id> --limit 100

# 4. Semantic similarity within a community
mcp2cli @discord-search find-similar-threads --query "<question>" --server-id 1456806362351669492
```

Caveats:
- Searches by message **content**, not author. Usernames are anonymized in results (e.g. `yucky-gold`); real handles only appear when someone is `@`-mentioned in the message body.
- Only public, indexed help channels are searchable.
