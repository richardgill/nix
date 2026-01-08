#!/bin/bash

# Claude Code status line script
# Shows model, git status counts, context window info

# ANSI color codes
CYAN='\033[0;96m'
GRAY='\033[0;90m'
GREEN='\033[0;92m'
PURPLE='\033[0;95m'
RED='\033[0;91m'
YELLOW='\033[0;93m'
RESET='\033[0m'

# Read JSON input from stdin
json_input=$(cat)

# Log for debugging (view with: cat /tmp/claude-statusline-*.json | jq)
session_id=$(echo "$json_input" | jq -r '.session_id // "unknown"' 2>/dev/null)
echo "$json_input" > "/tmp/claude-statusline-${session_id}.json" 2>/dev/null

# Extract values using jq
cwd=$(echo "$json_input" | jq -r '.workspace.current_dir // .cwd // empty' 2>/dev/null)
model=$(echo "$json_input" | jq -r '.model.display_name // empty' 2>/dev/null)
context_size=$(echo "$json_input" | jq -r '.context_window.context_window_size // 0' 2>/dev/null)
cost_usd=$(echo "$json_input" | jq -r '.cost.total_cost_usd // 0' 2>/dev/null)
duration_ms=$(echo "$json_input" | jq -r '.cost.total_api_duration_ms // 0' 2>/dev/null)

# Current usage tokens (accurate context calculation from 2.0.70+)
current_input=$(echo "$json_input" | jq -r '.context_window.current_usage.input_tokens // 0' 2>/dev/null)
current_output=$(echo "$json_input" | jq -r '.context_window.current_usage.output_tokens // 0' 2>/dev/null)
cache_creation=$(echo "$json_input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0' 2>/dev/null)
cache_read=$(echo "$json_input" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0' 2>/dev/null)

# Fallback for cwd
if [ -z "$cwd" ]; then
    cwd="$PWD"
fi

# Terminal width detection for responsive layout (try tmux first, then tput)
term_width=$(tmux display-message -p '#{pane_width}' 2>/dev/null || tput cols 2>/dev/null || echo 120)
narrow_term=$([[ "$term_width" -lt 65 ]] && echo 1 || echo 0)

# Git status counts (only if in a git repo)
git_info=""
GIT_WIDTH=15
if cd "$cwd" 2>/dev/null && git rev-parse --git-dir > /dev/null 2>&1; then
    read staged modified untracked <<< $(git status --porcelain 2>/dev/null | awk '
        /^[MADRC]/ {s++}
        /^.[MD]/ {m++}
        /^\?\?/ {u++}
        END {print s+0, m+0, u+0}
    ')

    [ "$staged" -gt 0 ] && git_info+="${GREEN}+${staged}${RESET} "
    [ "$modified" -gt 0 ] && git_info+="${YELLOW}~${modified}${RESET} "
    [ "$untracked" -gt 0 ] && git_info+="${RED}?${untracked}${RESET} "

    # Ahead/behind
    read behind ahead <<< $(git rev-list --left-right --count HEAD...@{upstream} 2>/dev/null)
    [ "$behind" -gt 0 ] 2>/dev/null && git_info+="${CYAN}⇣${behind}${RESET} "
    [ "$ahead" -gt 0 ] 2>/dev/null && git_info+="${CYAN}⇡${ahead}${RESET} "
fi

# Pad git_info to fixed width
git_visible=$(echo -e "$git_info" | sed 's/\x1b\[[0-9;]*m//g')
git_len=${#git_visible}
git_padding=$((GIT_WIDTH - git_len))
[ "$git_padding" -lt 0 ] && git_padding=0
git_info="${git_info}$(printf '%*s' "$git_padding" '')"

# Context window info (progress bar spanning 200k with 100k midpoint marker)
context_info=""
if [ "$context_size" -gt 0 ] 2>/dev/null; then
    total_tokens=$((current_input + current_output + cache_creation + cache_read))
    total_k=$((total_tokens / 1000))

    # Progress bar: full=20 chars (10k/char), narrow=10 chars (20k/char)
    # Midpoint │ at 100k (position 10 or 5)
    if [ "$narrow_term" -eq 1 ]; then
        bar_width=10
        midpoint=5
        tokens_per_char=20000
    else
        bar_width=20
        midpoint=10
        tokens_per_char=10000
    fi
    filled=$((total_tokens / tokens_per_char))
    [ "$filled" -gt "$bar_width" ] && filled=$bar_width

    # Color based on token usage: red at 100k+, yellow at 70k+, purple otherwise
    if [ "$total_tokens" -ge 100000 ]; then
        bar_color="$RED"
    elif [ "$total_tokens" -ge 70000 ]; then
        bar_color="$YELLOW"
    else
        bar_color="$PURPLE"
    fi

    # Build the bar with midpoint marker
    bar=""
    for ((i=0; i<bar_width; i++)); do
        if [ "$i" -eq "$midpoint" ]; then
            bar+="${GRAY}│${bar_color}"
        fi
        if [ "$i" -lt "$filled" ]; then
            bar+="█"
        else
            bar+="░"
        fi
    done

    context_info="${total_k}k ${bar_color}[${bar}${bar_color}]${RESET} 200k"
fi

# Model info
model_info=""
if [ -n "$model" ]; then
    model_info="${GRAY}${model}${RESET}"
fi

# Duration in minutes
duration_info=""
if [ "$duration_ms" -gt 0 ] 2>/dev/null; then
    duration_mins=$((duration_ms / 60000))
    duration_info="${GRAY}${duration_mins}m${RESET}"
fi

# Cost
cost_info=""
if awk "BEGIN {exit !($cost_usd > 0)}" 2>/dev/null; then
    cost_fmt=$(printf "%.2f" "$cost_usd")
    cost_info="${GRAY}\$${cost_fmt}${RESET}"
fi

# Output: context | git | model
echo -e "${context_info} ${git_info}${model_info}"
