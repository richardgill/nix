---
name: tmux-pi
description: |
  Delegate and oversee work in tmux-hosted Pi agents.
  Triggers: "🧵", "thread", "delegate", "orchestrate", "oversee", "worktree", "wt", "spawn", "FAF", "🔥".
  Use for launching, monitoring, following up with, or coordinating delegated Pi work.
---

# tmux-pi

## Delegate work

Delegate work to another Pi:

- In the current tmux session and working directory by default.
- In another existing repo or worktree tmux session with `--target`.
- In a new worktree and tmux session with `--worktree`. This pulls local `main` first and creates the branch from its updated HEAD unless `--source-ref` is supplied.

Delegation remains supervised without blocking the parent. `tmux-pi` launches the child with the parent Pi session ID, reports the child Pi session ID and tmux window, then returns. The `overmux-pi` extension notifies the parent after every child `agent_settled` event.

## Launch the delegate

For --task-slug choose a human-readable lowercase task slug of at most 13 characters using only letters, numbers, and internal hyphens; it must start and end with a letter or number. `tmux-pi` only accepts prompt files. Use an existing issue, plan, design, or spec, or write generated prompt text to a temporary file first.

Child prompts must contain only the delegated work. Do not forward parent-only orchestration such as "in a thread," subsequent tasks, cleanup, or supervision. The child reports its result; the parent owns follow-on work.

- `wt` means spawn in a new worktree using `--worktree`. Ask whether callbacks should be enabled unless the request already specifies normal supervision, no callback, `FAF`, or `🔥`.
- `FAF` and `🔥` mean fire-and-forget: launch with `--no-callback` and do not supervise the child.
- Delegated Pis may delegate distinct, self-contained subtasks by default. Use `--block-nested` when the launched child must not delegate.

When running `tmux-pi`, confirm the launcher reaches `Launched`; if slow worktree setup moves the command to the background, wait only for its automatic completion notification and do not poll it.

Current tmux session and working directory:

```bash
tmux-pi \
  --task-slug 'auth-research' \
  --prompt-file '<prompt-file>'
```

Launch without a callback to the parent:

```bash
tmux-pi \
  --no-callback \
  --task-slug 'auth-research' \
  --prompt-file '<prompt-file>'
```

A no-callback child remains available in its tmux window, but the parent must not wait for, supervise, or expect a completion notification from it. It's fire-and-forget.

Launch a child that cannot delegate:

```bash
tmux-pi \
  --block-nested \
  --task-slug 'auth-research' \
  --prompt-file '<prompt-file>'
```

Another existing repo or worktree tmux session:

```bash
tmux-pi \
  --task-slug 'auth-research' \
  --prompt-file '<prompt-file>' \
  --target '<repo-or-worktree>'
```

New worktree from local `main` HEAD always uses the `strongHigh` profile:

```bash
tmux-pi \
  --task-slug 'auth-research' \
  --prompt-file '<prompt-file>' \
  --worktree '<branch>' \
  --model "openai-codex/gpt-6-astra" \
  --thinking "high"
```

Add `--source-ref '<ref>'` only when the worktree should start from an explicit source ref. Add `--pi-session`, `--model`, or `--thinking` when supplied by the request. Skill metadata delegates use `--skill --block-nested` when `pi.allowChildDelegation` is `false`; `--skill` marks the child without exposing `PI_SKILL_CHILD` at the call site.

`tmux-pi` launches the child with `PI_CHILD=1`, `PI_TASK_SLUG=<task-slug>`, and, unless `--no-callback` is used, `PI_PARENT_SESSION_ID=<parent-session-id>`. `--block-nested` adds `PI_BLOCK_NESTED=1`; a process with that marker cannot invoke `tmux-pi`. Skill children also receive `PI_SKILL_CHILD=1`. Keep the task, child Pi session ID, and window from its output available for supervision when callbacks are enabled.

Child will let you know when it's finished; no need to wait or poll. Do not use `capture-pane`, `bash_process`, `sleep`, or repeated status commands while waiting. Inspect the pane only if the notification is incomplete or the user explicitly requests live monitoring.

## Oversee delegated work

When `overmux-pi` delivers a `delegate-settled` notification, use the delegated status embedded in the notification as the primary report. Do not run `pi-jq` again unless the embedded status is incomplete, reports an inspection failure, or richer diagnostics are necessary. Use `tmux capture-pane` only if session inspection fails or terminal-only state is required.

### Use pi-jq

For fallback inspection, `pi-jq <session-id> --messages 1 --role assistant --chars 5000` prints the latest answer without repeating the delegated request. Use `--messages 3` when recent conversational context is necessary, `--turn` for richer diagnostics with the latest request, status, tools, and errors, `--errors` for failures, `--log` for the whole compact conversation, `--path` for the JSONL path, and `--json` for structured output. IDs may be shortened to a unique prefix.

If `pi-jq` needs another feature, read `~/code/nix-private/CLAUDE.md`, edit `~/code/nix-private/flake/modules/home-manager/dot-files/Scripts/pi-jq`, and run `just switch` from `~/code/nix-private` to deploy it.

If the task remains unresolved, send follow-up instructions through `overmux-pi` using the child Pi session ID recorded at launch. The child will notify the parent again when the follow-up turn settles; assess the fresh embedded status directly before deciding whether more work is needed.

Write multiline follow-up messages to a file under `/tmp`, then pipe the file contents to the sender:

```bash
followup_file=/tmp/pi-followup-<task>.md
# Write the multiline instructions to "$followup_file" with the write tool.
pnpm --dir /home/rich/code/overmux/active-server \
  --filter @overmux/pi \
  overmux-pi-send '<child-session-id>' --after-turn < "$followup_file"
```

`--after-turn` delivers immediately when the child is idle and otherwise steers after its current assistant turn and tools. Use `--follow-up` only when the message must wait for the entire active agent run. Send the file contents, not an `@file` reference. If delivery is unavailable, report the failure instead of silently falling back to `tmux send-keys`; use tmux input only when the user explicitly asks for terminal interaction.

For skill delegates, close the delegated tmux window after confirming the task is resolved:

```bash
tmux kill-window -t '<window-id>'
```

Worktree delegates are the exception: leave their tmux windows open after completion for human follow-ups. Do not kill a worktree delegate's window unless the user explicitly asks.

When the launcher prints an `overmux://` URL, include it as `[<slug>](<overmux-url>)` in your response, outside a code block.
When referring to the delegate later, link its task slug as `[<slug>](<overmux-url>)`.

After launch, end the current turn with a brief delegation-in-progress status; do not claim the task is complete. `overmux-pi` will start or steer a later parent turn when the child settles. Then resume supervision and do not present the task as complete while notified work remains unresolved.
