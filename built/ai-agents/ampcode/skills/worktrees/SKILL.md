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

## Choosing the prompt file

Pick the best option based on what's available:

1. **Issue file** — if the work references an issue in `thoughts/shared/issues/`, use `--prompt-file` pointing to the issue's `plan.md`
2. **Other .md file** — if the user references a specific markdown file (design doc, spec, etc.), use `--prompt-file` with that path
3. **Text prompt** — otherwise, write the prompt text to a timestamped file in `/tmp` and pass that path via `--prompt-file`

## Command

```bash
# With an issue or markdown file
~/Scripts/worktree-branch --no-switch --pull --binary amp --prompt-file "$FILE" "$BRANCH"

# With a text prompt
PROMPT_FILE="/tmp/worktree-prompt-$(date +%Y%m%d-%H%M%S).md"
cat > "$PROMPT_FILE" <<'EOF'
$PROMPT
EOF
~/Scripts/worktree-branch --no-switch --pull --binary amp --prompt-file "$PROMPT_FILE" "$BRANCH"
```

## Parameters

- `$BRANCH` - Branch name or remote/branch (e.g., `my-feature`)
- `$FILE` - Path to a .md file to use as the prompt (e.g., `thoughts/shared/issues/10-feature/plan.md`)
- `$PROMPT` - Text prompt to write to a timestamped `/tmp` file before passing via `--prompt-file`

## Examples

```bash
# From an existing file 
~/Scripts/worktree-branch --no-switch --pull --binary amp --prompt-file docs/migration-spec.md migration

# From a text prompt
PROMPT_FILE="/tmp/worktree-prompt-$(date +%Y%m%d-%H%M%S).md"
cat > "$PROMPT_FILE" <<'EOF'
fix the login bug
EOF
~/Scripts/worktree-branch --no-switch --pull --binary amp --prompt-file "$PROMPT_FILE" fix-login

# From a remote branch
PROMPT_FILE="/tmp/worktree-prompt-$(date +%Y%m%d-%H%M%S).md"
cat > "$PROMPT_FILE" <<'EOF'
implement the feature from the PR description
EOF
~/Scripts/worktree-branch --no-switch --pull --binary amp --prompt-file "$PROMPT_FILE" origin/feature-branch
```

## Notes

- Uses `--no-switch` to create the new tmux session without switching to it
- Uses `--pull` to automatically pull main if behind (no prompt)
- The new worktree session is created but not switched to
- Claude Code starts automatically in the `ai1` tmux window with the given prompt

$ARGUMENTS
