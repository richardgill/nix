---
name: worktrees
description: |
  This skill creates git worktrees with tmux sessions and spawns Claude with a prompt.
  Triggers: "create a worktree", "new worktree", "worktree for branch", "spawn worktree",
  "parallel branch", "work on branch in new session", "worktree-branch script".
  Creates isolated worktree directories with Claude Code running automatically.
  Not for regular git branching or checkout operations.
---

# Worktrees

Create a git worktree in a new tmux session with Claude Code running a specific prompt.

## Command

```bash
~/Scripts/worktree-branch --detached --pull --cmd 'pi "$PROMPT"' "$BRANCH"
```

## Parameters

- `$BRANCH` - Branch name or remote/branch (e.g., `my-feature`)
- `$PROMPT` - The prompt to pass to Claude Code in the new worktree

## Examples

```bash
# Create worktree from new branch with Claude prompt
~/Scripts/worktree-branch --detached --pull --cmd 'pi "fix the login bug"' fix-login

# Create worktree from remote branch
~/Scripts/worktree-branch --detached --pull --cmd 'pi "implement the feature from the PR description"' origin/feature-branch
```

## Notes

- Uses `--detached` to stay in current tmux session
- Uses `--pull` to automatically pull main if behind (no prompt)
- The new worktree session is created but not switched to
- Claude Code starts automatically in the `ai1` window with the given prompt

$ARGUMENTS
