---
name: beeper
description: |
  Search and read messages from Beeper Desktop API (WhatsApp, Signal, Telegram, etc.).
  Triggers: "check my messages", "search messages", "who messaged me", "find conversations",
  "unread messages", "beeper", "chat history".
---

# Beeper Desktop API

Use the `~/Scripts/beeper` CLI to access messages across chat networks (WhatsApp, Signal, Telegram, Instagram, etc.).

## Commands

```bash
# List/search chats
beeper chats
beeper chats -q "John"
beeper chats --unread

# Search messages across all chats
beeper search "meeting tomorrow"

# Get messages from a specific chat (use chat ID from chats command)
beeper messages "!chatID:beeper.local"

# Get a single chat's details
beeper chat "!chatID:beeper.local"
```

## Tips

Chat IDs start with "!" - the CLI handles URL encoding automatically. Pipe to jq to filter JSON output. Search returns matching chats in the "chats" field.

$ARGUMENTS
