---
name: notify
description: Send Richard an ntfy notification.
---

Use `notify` to send Richard a notification on the Agent topic.

Examples:

```bash
notify "Need your input on this change"
notify "Build passed"
```

Use `--title` or `--click` when useful:

```bash
notify --title "CI needs attention" --click "https://github.com/example/repo/actions" "The build failed"
```
