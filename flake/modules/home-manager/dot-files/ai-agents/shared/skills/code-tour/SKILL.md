---
name: code-tour
description: Create and launch a temporary JSON-driven code tour in the user's running Neovim, with highlighted ranges, contextual buffer annotations, and an indented location list. Use when asked for a code tour or a guided walkthrough of code in nvim/tmux.
---

# Code tour

Trace the requested behavior, generate a JSON tour, and open it in the correct running Neovim through `custom.code-tour`. Do not change source contents, save buffers, install plugins, or restart the editor unless requested. The renderer creates a dedicated temporary tab and preserves the original workspace.

## Prepare the tour

1. Find the intended tmux session and its Neovim socket. Confirm the editor's working directory before resolving filenames.
2. Read the relevant code and trace the behavior from the caller's perspective. Use live buffer contents when unsaved edits may differ from disk.
3. Write `overlay/branch/<topic>-tour.json` in the repository. Use the schema below, with current line numbers.
4. Launch synchronously through `--remote-expr`. Validation errors return a nonzero exit before changing an active tour. Correct the JSON rather than bypassing validation.
5. Confirm the location list and annotations are visible. Report the JSON path and remind the user of navigation and cleanup.

## JSON format

```json
{
  "title": "Starting voice recording",
  "entries": [
    {
      "filename": "flake/modules/home-manager/dot-files/Scripts/nixos/voxtype-record",
      "line": 25,
      "end_line": 30,
      "location_list_text": "Start recording: lower playback volume, then signal Voxtype",
      "buffer_annotation": "Keep playback subdued until recording stops, not just until this wrapper exits"
    },
    {
      "filename": "flake/modules/home-manager/dot-files/Scripts/nixos/voxtype-record",
      "line": 12,
      "end_line": 16,
      "location_list_text": "  duck_sink(): preserve the current volume before lowering it",
      "buffer_annotation": "Preserve the user's volume so recording doesn't leave audio permanently quieter"
    }
  ]
}
```

| Field | Meaning |
|---|---|
| `title` | Required string, used as the location-list title. |
| `entries` | Required nonempty array, ordered as the reader should follow the code. |
| `filename` | Required file path, relative to the original Neovim window's working directory or absolute. |
| `line` | Required positive, 1-based starting line and jump target. The cursor lands on its first nonblank character. |
| `end_line` | Optional inclusive highlight end, at least `line`; defaults to `line`. |
| `location_list_text` | Required location-list description. Leading spaces are preserved verbatim. |
| `buffer_annotation` | Optional short, single-line virtual text beside the starting line. Omit it when it adds no useful context; the range still gets highlighted and listed. |

Do not add other fields, step numbers, anchors, explicit depths, or nested children. The example's line numbers are illustrative: verify them against the current source before using it.

## Shape the walkthrough

- Start at a user-facing entry point, then follow meaningful calls, branches, state transitions, and side effects. Separate setup and parallel status paths from actual nested calls.
- Indent `location_list_text` by two spaces per call depth when entering a callee. Dedent when returning to a sibling or the caller. Keep the array flat; indentation is presentation, not a generated call graph.
- Prefer repo-relative filenames. The renderer appends `basename:line` to each list row, so do not repeat the path there. Mention the subsystem or directory in the description when basenames would be ambiguous.
- Prefer fewer important, cohesive ranges: a function, branch, or meaningful block. Do not turn every statement in one file into a separate entry. Add a callee entry only when seeing its implementation explains something important.
- Use `location_list_text` to orient the reader: what role does this range play in the larger flow? Use `buffer_annotation` to reveal intent, an invariant, a tradeoff, a surprising consequence, or an external boundary.
- Avoid annotations that merely translate syntax, such as `save volume -> set output to 0.1`. Prefer context, such as `Preserve the user's volume so recording doesn't leave audio permanently quieter`. Ground claims in the code; do not invent motivation or repeat the list description.
- Keep annotations brief and insightful. Omit low-value annotations rather than filling every range with text. Do not add synthetic numbered labels or a repetitive `Tour:` prefix.

## Find the socket and launch

The main Neovim in a tmux session normally owns the session's `NVIM_SOCKET`. Use the requested session; do not assume the agent's session is the target.

```sh
# Example target: nix-private, editor in window 1.
SESSION=nix-private
SOCKET=$(tmux show-environment -t "$SESSION" NVIM_SOCKET | cut -d= -f2-)
test -S "$SOCKET"

# Confirm this is the intended repository/editor.
nvim --server "$SOCKET" --remote-expr 'getcwd()'

# The JSON path resolves against Neovim's current working directory.
nvim --server "$SOCKET" --remote-expr \
  "luaeval(\"require('custom.code-tour').open('overlay/branch/example-tour.json')\")"
```

For the current tmux session, obtain its name with `tmux display-message -p '#{session_name}'`. An absolute JSON path avoids ambiguity if the editor's working directory differs from the shell's. Use safe quoting for paths; do not interpolate unescaped arbitrary strings into Lua expressions.

If `NVIM_SOCKET` is absent or stale, inspect the requested editor pane and match its process ancestry to a Neovim `--listen` socket. Do not use the first Neovim process you find:

```sh
tmux list-panes -t "$SESSION:1" -F '#{pane_pid} #{pane_current_command}'
ps -eo pid,ppid,args | rg '[n]vim.*--listen'
```

A successful launch returns the entry count. Opening a valid new tour replaces the active one rather than accumulating tabs. Invalid JSON leaves the existing tour untouched. External-file-change recovery is out of scope; regenerate a tour when its coordinates become stale.

## Navigate and stop

Inside the tour tab, in normal mode:

- `l` / `L`: next / previous entry, wrapping without an explicit count.
- `]l` / `[l`: the underlying location-list navigation, also available outside tours. Count-prefixed navigation keeps native behavior and does not wrap.
- `[L` / `]L`: first / last entry.
- Enter on a location-list row: jump to that entry.
- `q` or `:CodeTourClear`: remove annotations, close the temporary tab, and return to the original workspace. Prior global mappings are restored when leaving the tour tab; buffer-local mappings are left untouched.
- `:lclose` / `:lopen`: hide / reopen only the location-list window, without stopping the tour.

Stop programmatically:

```sh
nvim --server "$SOCKET" --remote-expr \
  "luaeval(\"require('custom.code-tour').clear()\")"
```
