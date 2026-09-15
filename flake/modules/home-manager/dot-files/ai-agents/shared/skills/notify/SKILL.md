---
name: notify
description: Send Richard an Overmux notification.
---

Always use `"topic":"agent"`.

```bash
overmux call notification --input '{"title":"Agent","body":"Need your input","topic":"agent"}'
```

When an agent conversation finishes, prefer linking to its tmux pane so Richard can return to it.

Optionally add `"link":"/tmux/<session>/<window>/<pane>"` using numeric tmux IDs without `$`, `@`, or `%` prefixes, or an HTTPS URL. Omit `link` to open the inbox entry; do not use `overmux://` links.
