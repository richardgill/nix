#!/usr/bin/env bash

source_dir="$(dirname "$(dirname "$(realpath "$0")")")"
repo_url="https://github.com/richardgill/nix.git"

cd "$source_dir"

if ! git diff --quiet || ! git diff --cached --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
  echo "Error: Working directory has uncommitted changes or untracked files"
  echo "Please commit or stash your changes before publishing"
  exit 1
fi

echo "Building templates..."
just template

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
rsync -av --exclude='.git' --exclude='modules/home-manager/dot-files/Scripts/final-cut-pro.swift' --exclude='todo.md' "$source_dir/" .

# Remove built/ from .gitignore so built templates are tracked in public repo
sed -i '/^built\/$/d' .gitignore

echo "Removing private blocks from files..."
find . -type f -not -path "./.git/*" | while read -r file; do
  if grep -q "PRIVATE-START" "$file" 2>/dev/null; then
    "$source_dir/scripts/remove-private.sh" "$file" > "$file.tmp"
    mv "$file.tmp" "$file"
  fi
done

git add -A
# Force-add files ignored by global gitignore
git add -f modules/home-manager/dot-files/Scripts/local-ci.sh 2>/dev/null || true

if git diff --staged --quiet; then
  echo "No changes to commit"
  exit 0
fi

echo "=== AI Agent is checking for secrets/sensitive data ==="
claude -p /check-secrets

echo ""
read -p "Continue to diff? (y/n): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Publish cancelled. Repository at: $github_repo_dir"
  exit 0
fi

echo ""
echo "=== Changes to be published ==="
git diff --cached

echo ""
echo "Repository prepared at: $github_repo_dir"
echo ""
read -p "Push these changes to GitHub? (y/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
  short_sha=$(cd "$source_dir" && git rev-parse --short HEAD)
  git commit -m "nix-private sha: $short_sha"
  git push origin "$branch_name"
  echo ""
  echo "Changes pushed successfully!"

  pr_url=$(gh pr create --title "nix-private sha: $short_sha" --body "" --head "$branch_name" --base main)
  open "$pr_url/files"
else
  echo "Push cancelled. You can manually inspect the repository at: $github_repo_dir"
fi
