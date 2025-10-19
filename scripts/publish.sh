#!/usr/bin/env bash

source_dir="$(dirname "$(dirname "$(realpath "$0")")")"
repo_url="https://github.com/richardgill/nix.git"
OPENER=$(command -v xdg-open || command -v open)

cd "$source_dir"

if ! git diff --quiet || ! git diff --cached --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
  echo "Error: Working directory has uncommitted changes or untracked files"
  echo "Please commit or stash your changes before publishing"
  exit 1
fi

github_repo_dir=$(mktemp -d)

short_sha=$(git rev-parse --short HEAD)
branch_name="update-$(date +%Y%m%d-%H%M%S)-${short_sha}"

git clone "$repo_url" "$github_repo_dir"

cd "$github_repo_dir"

git checkout main
git pull origin main

git checkout -b "$branch_name"

# Remove all files except .git
find . -mindepth 1 -maxdepth 1 ! -name ".git" -exec rm -rf {} +

# Copy everything from current repo except .git
rsync -av --exclude='.git' --exclude='modules/home-manager/dot-files/Scripts/finalCutPro.swift' --exclude='todo.md' "$source_dir/" .

echo "Removing private blocks from files..."
find . -type f -not -path "./.git/*" | while read -r file; do
