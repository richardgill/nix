---
name: orchestrate
description: |
  Delegate and oversee work in tmux-hosted Pi agents.
  Triggers: "🧵", "thread", "delegate", "orchestrate", "oversee".
  Use for launching, monitoring, following up with, or coordinating delegated Pi work.
---

# Pi orchestration

## Delegate work

Delegate work to another Pi in an existing tmux session:

- In the current tmux session in a new tmux window.
- In an existing worktree's tmux session in a new tmux window.
  - Find its session by matching the worktree path: `tmux list-panes -a -F '#{session_name}: #{pane_current_path}' | rg '<worktree-path>'`.
- Or create a new worktree with a tmux session by using the worktrees skill.

Delegation is not fire-and-forget. Every delegated task must have a tracked listener before detached work starts.

## Start the listener

Use a lowercase slug of at most 13 characters. Run this with bash tool settings `timeout: 1` and `timeoutAction: "background"`:

```bash
slug='auth-research'
suffix=$(head -c 5 /dev/urandom | base64 | tr '+/' '_-' | tr -d '=\n' | cut -c1-6)
task="${slug}-${suffix}"
channel="$task"

printf 'Listener armed: task=%s channel=%s\n' "$task" "$channel"

timeout 10m tmux wait-for "$channel"
status=$?

printf 'Listener exited with status %s. Inspect task %s; if unresolved, immediately re-arm channel %s.\n' \
  "$status" "$task" "$channel"

exit "$status"
```

Do not launch detached work until the tool confirms that the listener is running in the background. The values remain visible in tool output; do not persist them in an environment file.

## Prepare the prompt

Use the write tool to create `/tmp/pi-prompt-<task>.md`, then append the completion protocol using the printed values as literals:

```bash
task='auth-research-AbC123'
channel='auth-research-AbC123'
prompt="/tmp/pi-prompt-${task}.md"

test -f "$prompt" || { printf 'Missing prompt: %s\n' "$prompt"; exit 1; }

printf "\nBefore signalling, leave a concise status in your pane. Whenever finished, blocked, or needing parent attention, run exactly:\n\n\`tmux wait-for -S '%s'\`\n\nYou may signal repeatedly. Remain available for follow-up work.\n" \
  "$channel" >> "$prompt"
```

For a new worktree, run the worktrees skill with this prepared prompt only after the listener is active, then verify the Pi window started. Otherwise launch directly:

```bash
task='auth-research-AbC123'
prompt="/tmp/pi-prompt-${task}.md"

window_id=$(tmux new-window -d -P -F '#{window_id}' \
  -t '<session>:' \
  -c '<repo-or-worktree>' \
  "pi @$prompt")

sleep 1
tmux rename-window -t "$window_id" "$task"
tmux display-message -p -t "$window_id" '#{window_id} #{window_name} #{pane_current_command}'
tmux capture-pane -p -t "$window_id" -S -20
```

## Oversee delegated work

When the listener exits, inspect the delegated pane and repository. Exit status `124` means the ten-minute liveness timeout expired rather than the delegate signalling.

If the task remains unresolved, re-arm the same channel with bash tool settings `timeout: 1` and `timeoutAction: "background"` before sending follow-up work:

```bash
task='auth-research-AbC123'
channel='auth-research-AbC123'

printf 'Listener re-armed: task=%s channel=%s\n' "$task" "$channel"

timeout 10m tmux wait-for "$channel"
status=$?

printf 'Listener exited with status %s. Inspect task %s; if unresolved, re-arm channel %s.\n' \
  "$status" "$task" "$channel"

exit "$status"
```

A signal sent between listeners is latched, so the next waiter exits immediately. Multiple signals before re-arming collapse into one. Use a fresh channel only for a new delegated task.

Send follow-up instructions with `tmux send-keys`. Remove the prompt only when the task is resolved. Never respond finally while observed delegated work remains unresolved unless explicitly asked not to wait.
