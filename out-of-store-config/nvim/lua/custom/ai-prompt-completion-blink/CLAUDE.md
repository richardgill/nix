# ai-prompt-completion testing

## Big picture

- `custom.ai-prompt-completion-blink.native` uses native Neovim insert completion for prompt buffers.
- `@` completions list repo files from `rg --files`, cache per cwd, filter literal path queries with smartcase, and rank `overlay/` lower.
- `/` completions suggest `/skill:<name>` commands from Pi's RPC command list.
- Blink is disabled for `prompt` filetype.

## Quick test loop

Run `./test.sh` in this directory.
