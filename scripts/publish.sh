#!/usr/bin/env bash
set -euo pipefail

force=false
while getopts "f" opt; do
  case $opt in
    f) force=true ;;
  esac
done

source_dir="$(dirname "$(dirname "$(realpath "$0")")")"
repo_url="https://github.com/richardgill/nix.git"

cd "$source_dir"

if ! git diff --quiet || ! git diff --cached --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
  echo "Error: Working directory has uncommitted changes or untracked files"
  echo "Please commit or stash your changes before publishing"
  exit 1
fi

echo "Building templates..."
# Render public templates from a public host, not the machine running publish.
publish_host=um790
just template "$publish_host"

mcp_path=flake/modules/home-manager/shared/headless/mcp.json
publish_user=$(nix eval --raw 'path:./flake#vars.userName')
# Reading home.file directly can require building templates for the host's platform.
mcp_config=$(nix eval --raw "path:./flake#nixosConfigurations.$publish_host.config.home-manager.users.\"$publish_user\".custom.aiAgents.pi.mcp.rendered")

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

# Copy everything from current repo except .git and gitignored files
rsync_options=(
  --filter=':- .gitignore'
  --exclude='.git'
  --exclude='overlay/***'
  --exclude='flake/machines/darwin/aarch64/macbookair-work/***'
  --exclude='/flake/home-manager/*/rg-devbox/***'
  --exclude='docs/ubuntu.md'
  --exclude='flake/packages/cone.nix'
  --exclude='flake/modules/home-manager/dot-files/git/ch'
  --exclude='flake/modules/home-manager/dot-files/Scripts/beeper-cli'
  --exclude='flake/modules/home-manager/dot-files/ai-agents/shared/skills/beeper/***'
  --exclude='flake/modules/home-manager/dot-files/ai-agents/shared/skills/posthog/***'
  --exclude='flake/modules/home-manager/shared/headless/optional/ch-ai-gateway.nix'
  --exclude='*ch-gateway*'
  --exclude="/$mcp_path"
  --exclude='/out-of-store-config/mcpc/***'
  --exclude='out-of-store-config/services/ai-cron/***'
  --exclude='todo.md'
)
rsync -av "${rsync_options[@]}" "$source_dir/" .

# The public flake reads only the MCP servers selected by the publish host.
printf '%s\n' "$mcp_config" > "$mcp_path"

# Copy built/ separately since it's gitignored in source but tracked in public repo
rsync -av \
  --exclude='ai-agents/*/skills/beeper/***' \
  --exclude='ai-agents/*/skills/slack/***' \
  --exclude='ai-agents/*/skills/posthog/***' \
  --exclude='*ch-gateway*' \
  "$source_dir/built/" ./built/

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
git add -f flake/modules/home-manager/dot-files/Scripts/local-ci.sh 2>/dev/null || true

if git diff --staged --quiet; then
  echo "No changes to commit"
  exit 0
fi

short_sha=$(cd "$source_dir" && git rev-parse --short HEAD)

publish_to_main() {
  git commit -m "nix-private sha: $short_sha"
  git checkout main
  git merge "$branch_name"
  git push origin main
  echo "Changes pushed directly to main!"
  rm -rf "$github_repo_dir"
}

create_pr() {
  git commit -m "nix-private sha: $short_sha"
  git push origin "$branch_name"
  echo ""
  echo "Changes pushed successfully!"

  pr_url=$(gh pr create --title "nix-private sha: $short_sha" --body "" --head "$branch_name" --base main)
  open "$pr_url/files"
}

if [[ "$force" == "true" ]]; then
  publish_to_main
  exit 0
fi

# echo "=== AI Agent is checking for secrets/sensitive data ==="
# claude -p /check-secrets

echo ""
echo "=== Changes to be published ==="
git diff --cached

echo ""
echo "Repository prepared at: $github_repo_dir"
echo ""
read -p "Choose: [c]ancel, create [p]r, or [f]orce publish to main: " -n 1 -r action
echo ""

if [[ $action =~ ^[Pp]$ ]]; then
  create_pr
elif [[ $action =~ ^[Ff]$ ]]; then
  publish_to_main
else
  echo "Publish cancelled. You can manually inspect the repository at: $github_repo_dir"
fi
