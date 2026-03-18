---
name: beeper
description: |
  Search and read messages from Beeper Desktop API (WhatsApp, Signal, Telegram, etc.).
  Triggers: "check my messages", "search messages", "who messaged me", "find conversations",
  "unread messages", "beeper", "chat history".
---

# Beeper Desktop API

Use the `~/Scripts/beeper-cli` CLI to access messages across chat networks (WhatsApp, Signal, Telegram, Instagram, etc.).

## Commands

```bash
# List/search chats
beeper-cli chats
beeper-cli chats -q "John"
beeper-cli chats --unread

# Search messages across all chats
beeper-cli search "meeting tomorrow"

# Get messages from a specific chat (use chat ID from chats command)
beeper-cli messages "!chatID:beeper.local"

# Get a single chat's details
beeper-cli chat "!chatID:beeper.local"
```

## Tips

Chat IDs start with "!" - the CLI handles URL encoding automatically. Pipe to jq to filter JSON output. Search returns matching chats in the "chats" field.

## Auth Issues

If any Beeper CLI command fails due to authentication/session issues, stop and tell the user that authentication is required. Ask them to re-authenticate, and do not attempt to work around or fix authentication automatically.

$ARGUMENTS
