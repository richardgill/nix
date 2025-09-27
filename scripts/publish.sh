#!/usr/bin/env bash

source_dir="$(dirname "$(dirname "$(realpath "$0")")")"
repo_url="https://github.com/richardgill/nix.git"

github_repo_dir=$(mktemp -d)

branch_name="update-$(date +%Y%m%d-%H%M%S)"

git clone "$repo_url" "$github_repo_dir"

cd "$github_repo_dir"

git checkout main
git pull origin main

git checkout -b "$branch_name"

# Remove all files except .git
find . -mindepth 1 -maxdepth 1 ! -name ".git" -exec rm -rf {} +

# Copy everything from current repo except .git
rsync -av --exclude='.git' "$source_dir/" .

git add -A

if git diff --staged --quiet; then
  echo "No changes to commit"
else
  git commit -m "Update configuration files"
  git push origin "$branch_name"
fi

echo "Repository cloned and updated at: $github_repo_dir"
echo "You can manually inspect the repository in this directory."

# Open GitHub compare page for the new branch
open "${repo_url%.git}/compare/main...$branch_name"
