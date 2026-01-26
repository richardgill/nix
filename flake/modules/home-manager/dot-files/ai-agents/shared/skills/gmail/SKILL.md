---
name: gmail
description: Gmail CLI for searching emails, reading threads, sending messages, managing drafts, and handling labels/attachments.
---

## Usage

Email style preference: start with "Hi" and end with "Thanks,\nRichard".

Run `gmcli --help` for full command reference.

First: run `gmcli accounts list` to find which emails exist. If there's only one, use that.

Common operations:
- `gmcli <email> search "<query>"` - Search emails using Gmail query syntax
- `gmcli <email> thread <threadId>` - Read a thread with all messages
- `gmcli <email> send --to <emails> --subject <s> --body <b>` - Send email
- For newlines in `--body`, use Bash ANSI-C quoting like `--body $'Line 1\n\nLine 2'` or paste literal newlines
- `gmcli <email> labels list` - List all labels
- `gmcli <email> drafts list` - List drafts

## Data Storage

- `~/.gmcli/credentials.json` - OAuth client credentials
- `~/.gmcli/accounts.json` - Account tokens
- `~/.gmcli/attachments/` - Downloaded attachments
