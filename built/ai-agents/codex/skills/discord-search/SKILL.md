---
name: discord-search
description: Search public Discord help-channel archives via Answer Overflow MCP (mcpc @discord-search).
---

Use `mcpc @discord-search` to search Answer Overflow — a searchable archive of public Discord help channels.

Known server: **The Shitty Coders Club** — `serverId=1456806362351669492`. Pass `serverId:=1456806362351669492` to scope queries.

If the session is missing, run:

```bash
mcpc connect ~/.config/mcpc/mcp.json:discord-search @discord-search
```

To discover tools:

```bash
mcpc @discord-search tools-list --full
mcpc @discord-search grep <term>
mcpc @discord-search tools-get <tool>
```

Typical workflow:

```bash
# 1. Find a server ID (skip if you already know it)
mcpc @discord-search tools-call search_servers query:="shitty coders"

# 2. Search threads
mcpc @discord-search tools-call search_answeroverflow \
  query:="ctx.reload" serverId:=1456806362351669492 limit:=25

# 3. Pull full conversation
mcpc @discord-search tools-call get_thread_messages threadId:=<id> limit:=100

# 4. Semantic similarity within a community
mcpc @discord-search tools-call find_similar_threads query:="<question>" serverId:=1456806362351669492
```

Caveats:
- Searches by message **content**, not author. Usernames are anonymized in results (e.g. `yucky-gold`); real handles only appear when someone is `@`-mentioned in the message body.
- Only public, indexed help channels are searchable.
