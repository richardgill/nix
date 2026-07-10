---
name: worktrees
description: |
  This skill creates git worktrees with tmux sessions and spawns an AI agent with a prompt.
  Triggers: "create a worktree", "new worktree", "worktree for branch", "spawn worktree",
  "parallel branch", "work on branch in new session", "worktree-branch script".
  Creates isolated worktree directories with an AI agent running automatically.
  Not for regular git branching or checkout operations.
---

# Worktrees

Create a git worktree in a new tmux session with an AI agent running a specific prompt.

## Base branch

By default everything should have a base branch of `main` unless you're explicitly told otherwise.

## Choosing the prompt file

Pick the best option based on what's available:

A) **Issue or markdown file** — if the work references an issue, plan, design doc, or spec, use `--prompt-file` with that path
B) **Text prompt** — write the prompt text to a timestamped file in `/tmp` and pass that path via `--prompt-file`
C) **No prompt** — if you want to continue working in your current session you can omit `--prompt-file` and continue modifying the created worktree in the current session

Prefer B) by default.

## Command

Run from the repo's `./main` worktree. If you are in a sibling worktree, run the command via `(cd ../main && ...)`. 
A single branch argument creates a new sibling worktree from `./main` HEAD. Use two branch arguments only when you intentionally want the new branch to start from an explicit source ref instead of local `./main` HEAD.

### Parameters

- `$BRANCH` - New branch/worktree name (e.g., `my-feature`)
- `$SOURCE_REF` - Optional explicit source ref for two-argument form (e.g., `origin/feature-branch`)
- `$PROMPT_FILE` - File path passed to `--prompt-file`; either an existing issue/plan/spec file or a generated temp file
- `$PROMPT` - Inline prompt text used only when creating a generated temp `$PROMPT_FILE`

### Examples

```bash
# With an existing issue, plan, design doc, or spec
PROMPT_FILE="overlay/my-plan-spec.md"
~/Scripts/worktree-branch --no-switch --pull --binary pi --prompt-file "$PROMPT_FILE" my-feature

# With a text prompt
PROMPT_FILE="/tmp/worktree-prompt-$(date +%Y%m%d-%H%M%S).md"
cat > "$PROMPT_FILE" <<'EOF'
$PROMPT
EOF

# New branch from ./main HEAD
~/Scripts/worktree-branch --no-switch --pull --binary pi --prompt-file "$PROMPT_FILE" my-feature

# Same, when currently in a sibling worktree
(cd ../main && ~/Scripts/worktree-branch --no-switch --pull --binary pi --prompt-file "$PROMPT_FILE" my-feature)

# New branch from ./main HEAD, no prompt file
~/Scripts/worktree-branch --no-switch --pull --binary pi my-feature

# Rare: new branch from remote main instead of local ./main HEAD
~/Scripts/worktree-branch --no-switch --pull --binary pi --prompt-file "$PROMPT_FILE" origin/main my-feature

# Existing remote branch, local branch/worktree becomes feature-branch
~/Scripts/worktree-branch --no-switch --pull --binary pi --prompt-file "$PROMPT_FILE" origin/feature-branch
```

## Notes

- The new worktree session is created and marked recent, but not switched to
- The AI agent starts automatically in the 4th tmux window with the given prompt
- Do not use `main my-feature` to create a branch from main; use `my-feature` unless you intentionally need an explicit source ref

$ARGUMENTS
