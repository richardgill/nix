---
name: nvim
description: |
  This skill should be used when the user asks to "open in nvim", "show in editor",
  "open file in nvim", "edit in nvim", "nvim open", "send to nvim", "open buffer",
  "view in neovim", or "open this in my editor".
  Requires NVIM_SOCKET environment variable to be set (automatic in worktree sessions).
  Not for editing files directly - this sends files to the user's nvim instance.
---

# Open Files in Nvim

Open files in the running nvim instance connected to this tmux session.

## Command

```bash
v <files...>
```

`v` forwards files to the nvim listening on `$NVIM_SOCKET` if one is live; otherwise it launches nvim on those files.

## Environment

- `$NVIM_SOCKET` - Path to the nvim socket (set automatically in worktree sessions)

## Examples

```bash
# Open a single file
v src/index.ts

# Open multiple files
v src/index.ts src/utils.ts

# Open file at specific line (use +line before filename)
v +42 src/index.ts
```

## Troubleshooting

- **Socket not set**: Ensure you're in a worktree session, or manually set `NVIM_SOCKET`
- **Connection refused**: The nvim instance may have closed; restart nvim with `v .`
- **File not opening**: Verify the file path is correct and accessible

## Notes

- The socket is set via `tmux set-environment` at session creation
- New panes/windows in the session inherit `NVIM_SOCKET`

$ARGUMENTS
