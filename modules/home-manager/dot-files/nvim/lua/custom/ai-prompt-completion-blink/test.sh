#!/usr/bin/env bash
set -euo pipefail

session="blink-ripgrep-test"
test_file="/tmp/pi-editor-blink-test-$(date +%Y%m%d-%H%M%S)-$RANDOM.pi.md"
line_output="$(mktemp "/tmp/pi-editor-blink-line-XXXXXX")"

if tmux has-session -t "$session" 2>/dev/null; then
  tmux kill-session -t "$session"
fi

tmux new-session -d -s "$session"

pane="$(tmux display-message -p -t "${session}:0.0" "#{pane_id}")"
if [[ -z "$pane" ]]; then
  echo "Failed to create tmux pane" >&2
  exit 1
fi

sleep 0.5

tmux send-keys -t "$pane" "nvim \"$test_file\"" Enter
sleep 1

tmux send-keys -t "$pane" ":lua package.loaded['custom.ai-prompt-completion-blink.keyword']=nil; require('custom.ai-prompt-completion-blink.keyword'); package.loaded['custom.ai-prompt-completion-blink.ripgrep-files-provider']=nil; require('custom.ai-prompt-completion-blink.ripgrep-files-provider'); package.loaded['custom.ai-prompt-completion-blink.prompt-commands-provider']=nil; require('custom.ai-prompt-completion-blink.prompt-commands-provider')" Enter
sleep 0.5

run_case() {
  local label="$1"
  local query="$2"

  tmux send-keys -t "$pane" Escape
  tmux send-keys -t "$pane" ":silent %d" Enter
  tmux send-keys -t "$pane" -l "i${query}"
  sleep 0.4
  printf "\n===== %s =====\n" "$label"
  tmux capture-pane -t "$pane" -p -e -S -80
}

assert_no_auto_insert() {
  local label="$1"
  local query="$2"

  tmux send-keys -t "$pane" Escape
  tmux send-keys -t "$pane" ":silent %d" Enter
  tmux send-keys -t "$pane" -l "i${query}"
  sleep 0.4
  tmux send-keys -t "$pane" C-Space
  sleep 0.4
  tmux send-keys -t "$pane" Down
  sleep 0.4
  tmux send-keys -t "$pane" Escape
  tmux send-keys -t "$pane" ":lua vim.fn.writefile({vim.api.nvim_get_current_line()}, '${line_output}')" Enter
  sleep 0.2
  local line
  line="$(cat "$line_output")"
  if [[ "$line" != "$query" ]]; then
    echo "FAIL ${label}: expected line '${query}', got '${line}'" >&2
    tmux capture-pane -t "$pane" -p -e -S -80
    exit 1
  fi
}

echo "EXPECT 00-selection: moving selection does not insert"
assert_no_auto_insert "00-selection" "@"

echo "EXPECT 01-root: show files from repo root"
run_case "01-root" "@"

echo "EXPECT 02-ai-agents: show files under modules/home-manager/dot-files/ai-agents/"
run_case "02-ai-agents" "@ai-agents/"

echo "EXPECT 03-smartcase-upper: no items (case-sensitive miss)"
run_case "03-smartcase-upper" "@Ai-"

echo "EXPECT 04-smartcase-shared-upper: show no files under ai-agents/Shared because it's not a smartcase match"
run_case "04-smartcase-shared-upper" "@ai-agents/Shared"

echo "EXPECT 05-smartcase-shared-lower: show files under ai-agents/shared and highlighting is correct"
run_case "05-smartcase-shared-lower" "@ai-agents/shared/"

echo "EXPECT 06-missing: no items"
run_case "06-missing" "@some/missing/path"

echo "EXPECT 07-slash-root: show some pi skills"
run_case "07-slash-root" "/"


tmux kill-session -t "$session"

echo "Auto-insert assertion passed; review the remaining cases manually"
