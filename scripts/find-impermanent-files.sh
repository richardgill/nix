#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
hostname=$(hostname)
user=$(whoami)

persistence_data=$(nix eval --json "$PROJECT_ROOT#nixosConfigurations.$hostname.config.environment.persistence.\"/persistent\"" 2>/dev/null || echo "{}")

# Extract system-level and user-level persisted directory paths from nix configuration
persist_dirs=$(echo "$persistence_data" | jq -r --arg user "$user" '
  (.directories[]? | if type == "object" then .dirPath else . end),
  (.users[$user].directories[]? |
    if type == "object" then
      .dirPath
    elif startswith("/") then
      .
    else
      ("/home/" + $user + "/" + .)
    end)
')

# Extract system-level and user-level persisted file paths from nix configuration
persist_files=$(echo "$persistence_data" | jq -r --arg user "$user" '
  (.files[]? | if type == "object" then .filePath else . end),
  (.users[$user].files[]? |
    if type == "object" then
      .filePath
    elif startswith("/") then
      .
    else
      ("/home/" + $user + "/" + .)
    end)
')

additional_excludes=(
  "/persistent"
  "/nix"
  "/tmp"
  "/home/$user/.cache"
  "/home/$user/.bun/install/cache"
  "/home/$user/.npm"
  "/root/.cache/nix"
)

sudo btrfs subvolume find-new / 0 |
sed '$d' |
cut -f17- -d' ' |
sort |
uniq |
while read -r file; do
  path="/$file"

  [ -L "$path" ] && continue
  [ -d "$path" ] && continue

  skip=false
  for dir in $persist_dirs "${additional_excludes[@]}"; do
    [[ "$path" == $dir/* || "$path" == "$dir" ]] && skip=true && break
  done
  $skip && continue

  for file in $persist_files; do
    [[ "$path" == "$file" ]] && skip=true && break
  done
  $skip && continue

  echo "$path"
done
