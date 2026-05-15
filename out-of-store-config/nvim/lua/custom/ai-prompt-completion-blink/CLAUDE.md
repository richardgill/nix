# ai-prompt-completion testing

## Big picture

- `custom.ai-prompt-completion-blink.native` uses native Neovim insert completion for prompt buffers.
- `@` completions list repo files from `rg --files`, cache per cwd, filter literal path queries with smartcase, and rank `overlay/` lower.
- `/` completions suggest `/skill:<name>` commands from the Node-loaded pi skill list.
- Blink is disabled for `prompt` filetype; the older blink source files are no longer wired into completion.

## Quick test loop

Run `./test.sh` in this directory.
