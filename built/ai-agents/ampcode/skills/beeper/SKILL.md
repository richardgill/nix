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

# Send a message to an allowed chat
# First call prints a one-time confirmation code and does not send. The CLI enforces the allowed recipient list
beeper-cli send "!chatID:beeper.local" "message text"
beeper-cli send --confirm-code "abc123" "!chatID:beeper.local" "message text"
```

## Tips

Chat IDs start with "!" - the CLI handles URL encoding automatically. Pipe to jq to filter JSON output. Search returns matching chats in the "chats" field.

## Finding your own WhatsApp chat

Use `/v1/accounts` to get the WhatsApp self user ID, then find the single WhatsApp chat containing that participant:

```bash
self_id=$(~/Scripts/beeper-cli raw http://localhost:23373/v1/accounts \
  | jq -r '.[] | select(.accountID=="whatsapp") | .user.id')

~/Scripts/beeper-cli chats \
  | jq -r --arg participant "@whatsapp_${self_id}:beeper.local" '
      .items[]
      | select(.accountID=="whatsapp"
          and .type=="single"
          and any(.participants.items[]?; .id == $participant))
      | [.id, .title, .lastActivity] | @tsv
    '
```

## Auth Issues

If any Beeper CLI command fails due to authentication/session issues, stop and tell the user that authentication is required. Ask them to re-authenticate, and do not attempt to work around or fix authentication automatically.

$ARGUMENTS
