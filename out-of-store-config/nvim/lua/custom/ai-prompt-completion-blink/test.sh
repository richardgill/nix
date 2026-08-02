#!/usr/bin/env bash
set -euo pipefail

session="blink-ripgrep-test"
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(git -C "$script_dir" rev-parse --show-toplevel)"
test_dir="$(mktemp -d "/tmp/pi-editor-XXXXXX")"
test_file="$test_dir/prompt.md"
line_output="$(mktemp "/tmp/pi-editor-blink-line-XXXXXX")"
snapshot_dir="$(mktemp -d "/tmp/pi-editor-blink-snapshots-XXXXXX")"
incremental_sleep="${INCREMENTAL_SLEEP:-0.12}"

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

tmux send-keys -t "$pane" "cd \"$repo_root\" && nvim \"$test_file\"" Enter
sleep 1

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

snapshot_file_path() {
  local label="$1"
  local step="$2"
  local step_name
  printf -v step_name '%03d' "$step"
  printf '%s/%s-%s.ansi' "$snapshot_dir" "$label" "$step_name"
}

snapshot_incremental_step() {
  local label="$1"
  local step="$2"
  local typed="$3"
  local snapshot_file
  snapshot_file="$(snapshot_file_path "$label" "$step")"
  tmux capture-pane -t "$pane" -p -e -S -80 >"$snapshot_file"
  printf 'snapshot %s %03d %q -> %s\n' "$label" "$step" "$typed" "$snapshot_file"
}

assert_snapshot_contains() {
  local label="$1"
  local step="$2"
  local expected="$3"
  local snapshot_file
  snapshot_file="$(snapshot_file_path "$label" "$step")"
  if ! perl -pe 's/\e\[[0-9;:]*[A-Za-z]//g' "$snapshot_file" | grep -q -- "$expected"; then
    echo "FAIL ${label} step ${step}: expected snapshot to contain '${expected}'" >&2
    echo "$snapshot_file" >&2
    exit 1
  fi
}

assert_snapshot_not_contains() {
  local label="$1"
  local step="$2"
  local unexpected="$3"
  local snapshot_file
  snapshot_file="$(snapshot_file_path "$label" "$step")"
  if perl -pe 's/\e\[[0-9;:]*[A-Za-z]//g' "$snapshot_file" | grep -q -- "$unexpected"; then
    echo "FAIL ${label} step ${step}: expected snapshot not to contain '${unexpected}'" >&2
    echo "$snapshot_file" >&2
    exit 1
  fi
}

assert_current_line() {
  local label="$1"
  local expected="$2"
  tmux send-keys -t "$pane" Escape
  sleep 0.1
  tmux send-keys -t "$pane" ":lua vim.fn.writefile({vim.api.nvim_get_current_line()}, '${line_output}')" Enter
  sleep 0.2
  local line
  line="$(cat "$line_output")"
  if [[ "$line" != "$expected" ]]; then
    echo "FAIL ${label}: expected line '${expected}', got '${line}'" >&2
    tmux capture-pane -t "$pane" -p -e -S -80
    exit 1
  fi
}

assert_pum_closed() {
  local label="$1"
  tmux send-keys -t "$pane" Escape
  tmux send-keys -t "$pane" ":lua vim.fn.writefile({tostring(vim.fn.pumvisible())}, '${line_output}')" Enter
  sleep 0.2
  local visible
  visible="$(cat "$line_output")"
  if [[ "$visible" != "0" ]]; then
    echo "FAIL ${label}: expected popup menu to be closed, got pumvisible=${visible}" >&2
    tmux capture-pane -t "$pane" -p -e -S -80
    exit 1
  fi
}

assert_accept_continuation_after_space() {
  local label="$1"
  tmux send-keys -t "$pane" -l "x"
  sleep 0.2
  tmux send-keys -t "$pane" C-o
  tmux send-keys -t "$pane" ":lua vim.fn.writefile({vim.api.nvim_get_current_line()}, '${line_output}')" Enter
  sleep 0.2
  local line
  line="$(cat "$line_output")"
  if [[ "$line" != *" x" ]]; then
    echo "FAIL ${label}: expected cursor after appended space so continuing text yields ' x', got '${line}'" >&2
    tmux capture-pane -t "$pane" -p -e -S -80
    exit 1
  fi
}

run_accept_case() {
  local label="$1"
  local query="$2"
  local expected_line="$3"

  tmux send-keys -t "$pane" Escape
  tmux send-keys -t "$pane" ":silent %d" Enter
  tmux send-keys -t "$pane" -l "i${query}"
  sleep 1
  tmux send-keys -t "$pane" Enter
  sleep 0.4
  assert_accept_continuation_after_space "$label"
  assert_current_line "$label" "$expected_line"
  assert_pum_closed "$label"
}

run_incremental_file_case() {
  local label="$1"
  local path="$2"
  local step_sleep="${3:-$incremental_sleep}"
  local query="@${path}"
  local typed=""

  tmux send-keys -t "$pane" Escape
  tmux send-keys -t "$pane" ":silent %d" Enter
  tmux send-keys -t "$pane" i

  for ((index = 0; index < ${#query}; index++)); do
    local char="${query:index:1}"
    typed+="$char"
    tmux send-keys -t "$pane" -l "$char"
    sleep "$step_sleep"
    snapshot_incremental_step "$label" "$((index + 1))" "$typed"
  done

  sleep 0.5
  snapshot_incremental_step "$label" "${#query}" "$typed"
  assert_current_line "$label" "$query"
}

run_query_snapshot_case() {
  local label="$1"
  local query="$2"
  tmux send-keys -t "$pane" Escape
  tmux send-keys -t "$pane" ":silent %d" Enter
  tmux send-keys -t "$pane" -l "i${query}"
  sleep 1
  snapshot_incremental_step "$label" 1 "$query"
  assert_current_line "$label" "$query"
}

assert_root_readme_forward_expectations() {
  assert_snapshot_contains "10-root-readme" 10 "README.md"
}

assert_lowercase_readme_smartcase_expectations() {
  assert_snapshot_contains "10-lowercase-readme" 10 "README.md"
}

assert_nested_readme_expectations() {
  assert_snapshot_contains "11-nested-readme" 50 "themes/README.md"
}

assert_middle_folder_expectations() {
  assert_snapshot_contains "12-middle-folder" 42 "simplify/SKILL.md"
}

assert_folder_file_ext_expectations() {
  assert_snapshot_contains "13-folder-file-ext" 74 "native.lua"
}

assert_nested_filename_expectations() {
  assert_snapshot_contains "14-nested-filename" 16 "prompt-file.lua"
}

assert_middle_filename_expectations() {
  assert_snapshot_contains "15-middle-filename" 9 "prompt-file.lua"
}

assert_fuzzy_filename_expectations() {
  assert_snapshot_contains "16-fuzzy-filename" 1 "prompt-file.lua"
}

assert_multiple_filename_expectations() {
  assert_snapshot_contains "17-multiple-filenames" 1 "prompt-file.lua"
  assert_snapshot_contains "17-multiple-filenames" 1 "Scripts/ai-prompt"
}

run_root_readme_backspace_case() {
  local label="10-root-readme-backspace"
  local query="@README.md"
  tmux send-keys -t "$pane" Escape
  tmux send-keys -t "$pane" ":silent %d" Enter
  tmux send-keys -t "$pane" -l "i${query}"
  sleep 0.4

  snapshot_incremental_step "$label" 1 "$query"
  assert_snapshot_contains "$label" 1 "README.md"

  tmux send-keys -t "$pane" BSpace
  sleep 0.4
  snapshot_incremental_step "$label" 2 "@README.m"
  assert_snapshot_contains "$label" 2 "README.md"

  tmux send-keys -t "$pane" BSpace
  sleep 0.4
  snapshot_incremental_step "$label" 3 "@README."
  assert_snapshot_contains "$label" 3 "README.md"

  tmux send-keys -t "$pane" BSpace
  sleep 0.4
  snapshot_incremental_step "$label" 4 "@README"
  assert_snapshot_contains "$label" 4 "README.md"

  assert_current_line "$label" "@README"
}

assert_no_auto_insert() {
  local label="$1"
  local query="$2"

  tmux send-keys -t "$pane" Escape
  tmux send-keys -t "$pane" ":silent %d" Enter
  tmux send-keys -t "$pane" -l "i${query}"
  sleep 1
  tmux send-keys -t "$pane" C-Space
  sleep 1
  tmux send-keys -t "$pane" Down
  sleep 0.4
  tmux send-keys -t "$pane" Escape
  sleep 0.1
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

echo "EXPECT 03-smartcase-upper: uppercase query should not match lowercase paths"
run_case "03-smartcase-upper" "@Ai-"

echo "EXPECT 04-smartcase-shared-upper: uppercase path segment should not match lowercase shared paths"
run_case "04-smartcase-shared-upper" "@ai-agents/Shared"

echo "EXPECT 05-smartcase-shared-lower: show files under ai-agents/shared"
run_case "05-smartcase-shared-lower" "@ai-agents/shared/"

echo "EXPECT 06-missing: no items"
run_case "06-missing" "@some/missing/path"

echo "EXPECT 07-slash-after-at: no skills for @something/"
run_case "07-slash-after-at" "@something/"

echo "EXPECT 08-slash-root: show some pi skills"
run_case "08-slash-root" "/"

echo "EXPECT 09-slash-filter: show deep-research skill"
run_case "09-slash-filter" "/skill:dee"

echo "EXPECT 09b-slash-fuzzy-filter: fuzzy search /dr shows deep-research skill"
run_case "09b-slash-fuzzy-filter" "/dr"

printf '\nIncremental snapshots directory: %s\n' "$snapshot_dir"

echo "EXPECT 10-incremental-root-readme: README.md absent at @, then present from @R through @README.md"
run_incremental_file_case "10-root-readme" "README.md"
assert_root_readme_forward_expectations

echo "EXPECT 10a-lowercase-readme-smartcase: lowercase @readme.md still matches uppercase README.md"
run_incremental_file_case "10-lowercase-readme" "readme.md"
assert_lowercase_readme_smartcase_expectations

echo "EXPECT 10b-root-readme-backspace: README.md stays present for @README.md, @README.m, @README., @README"
run_root_readme_backspace_case

echo "EXPECT 10c-accept-file: Enter completes a file result and closes popup"
run_accept_case "10c-accept-file" "@prompt-file.lua" "@out-of-store-config/nvim/lua/custom/ai-prompt-completion-blink/prompt-file.lua x"

echo "EXPECT 10d-accept-skill: Enter completes a fuzzy skill result and closes popup"
run_accept_case "10d-accept-skill" "/dr" "/skill:deep-research x"

echo "EXPECT 10e-character-filter-refresh: every inserted character refreshes visible matches"
run_incremental_file_case "10e-character-filter-refresh" ".gi" 0.4
assert_snapshot_contains "10e-character-filter-refresh" 1 ".gitignore"
assert_snapshot_contains "10e-character-filter-refresh" 1 ".justfile"
assert_snapshot_contains "10e-character-filter-refresh" 2 ".gitignore"
assert_snapshot_contains "10e-character-filter-refresh" 2 ".justfile"
assert_snapshot_contains "10e-character-filter-refresh" 3 ".gitignore"
assert_snapshot_not_contains "10e-character-filter-refresh" 3 ".justfile"
assert_snapshot_contains "10e-character-filter-refresh" 4 ".gitignore"
assert_snapshot_not_contains "10e-character-filter-refresh" 4 ".justfile"

echo "EXPECT 11-incremental-nested-readme: nested README.md char-by-char"
run_incremental_file_case "11-nested-readme" "out-of-store-config/ai-agents/pi/themes/README.md"
assert_nested_readme_expectations

echo "EXPECT 12-incremental-middle-folder: shared skill path char-by-char"
run_incremental_file_case "12-middle-folder" "ai-agents/shared/skills/simplify/SKILL.md"
assert_middle_folder_expectations

echo "EXPECT 13-incremental-folder-file-ext: nvim lua provider path char-by-char"
run_incremental_file_case "13-folder-file-ext" "out-of-store-config/nvim/lua/custom/ai-prompt-completion-blink/native.lua"
assert_folder_file_ext_expectations

echo "EXPECT 14-nested-filename: basename-only nested file search char-by-char"
run_incremental_file_case "14-nested-filename" "prompt-file.lua"
assert_nested_filename_expectations

echo "EXPECT 15-middle-filename: middle substring filename search finds nested file"
run_incremental_file_case "15-middle-filename" "file.lua"
assert_middle_filename_expectations

echo "EXPECT 16-fuzzy-filename: fuzzy basename search finds nested file"
run_query_snapshot_case "16-fuzzy-filename" "@prmptfl"
assert_fuzzy_filename_expectations

echo "EXPECT 17-multiple-filenames: basename substring search shows multiple prompt files"
run_query_snapshot_case "17-multiple-filenames" "@prompt"
assert_multiple_filename_expectations

tmux kill-session -t "$session"
rm -rf "$test_dir"
rm -f "$line_output"

echo "Auto-insert assertion passed; review the remaining cases manually"
echo "Incremental snapshots saved in $snapshot_dir"
