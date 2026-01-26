# ai-prompt-completion-blink testing

## Big picture

- `custom.ai-prompt-completion-blink.ripgrep-files-provider` is a blink.cmp source that lists files with ripgrep (`rg --files`) and filters them against the `@` query using a path-safe pattern.
- `custom.ai-prompt-completion-blink.keyword` overrides blink.cmp fuzzy matching and keyword ranges so `@` queries keep the picker open and highlight the full `ai-agents/` or `ai-agents/p` prefix.
- Matching is smart-case: if the query has uppercase, comparisons are case-sensitive; otherwise they are lowercased.
- Completions are returned as file items with `textEdit` ranges that replace only the `@` query.
- Results are cached per cwd so repeated queries reuse the file list.
- `custom.ai-prompt-completion-blink.prompt-commands-provider` is a blink.cmp source for `/` that only runs in pi editor temp buffers (matching `/tmp/pi-editor-*.pi.md`) and suggests `/skill:<name>` commands from the Node-loaded skill list.

## Quick test loop

Run `./test.sh` in this directory.
