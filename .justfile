default:
    just --list

# path:. uses the path protocol to include untracked files (git protocol would require files to be staged)
_rebuild action machine='':
    @if [ "$(uname)" = "Darwin" ]; then \
      command="nix run nix-darwin --"; \
      sudo_prefix="{{ if action == "switch" { "sudo" } else { "" } }}"; \
    else \
      command="nixos-rebuild"; \
      sudo_prefix="{{ if action == "switch" { "sudo" } else { "" } }}"; \
    fi; \
    if [ -z "{{ machine }}" ]; then \
      full_command="$sudo_prefix $command {{ action }} --flake path:."; \
      echo "Running: $full_command"; \
      $sudo_prefix $command {{ action }} --flake path:.; \
    else \
      full_command="$sudo_prefix $command {{ action }} --flake \"path:.#{{ machine }}\""; \
      echo "Running: $full_command"; \
      $sudo_prefix $command {{ action }} --flake "path:.#{{ machine }}"; \
    fi

build machine='':
    @just _rebuild build "{{ machine }}"

switch machine='':
    @just _rebuild switch "{{ machine }}"

update:
    #!/usr/bin/env bash
    set -euo pipefail

    if ! git diff --quiet || ! git diff --cached --quiet || [ -n "$(git ls-files --others --exclude-standard)" ]; then
      echo "Error: Working directory has uncommitted changes or untracked files"
      echo "Please commit or stash your changes before updating"
      exit 1
    fi

    session_type="${XDG_SESSION_TYPE-}"
    if [ -z "$session_type" ] && [ -n "${XDG_SESSION_ID-}" ] && command -v loginctl >/dev/null 2>&1; then
      session_type=$(loginctl show-session "$XDG_SESSION_ID" -p Type --value 2>/dev/null || true)
    fi

    if [ -n "${TMUX-}" ] || [ ! -t 0 ] || [ ! -t 1 ]; then
      echo "Error: update must be run from a TTY: ctrl+alt+F3"
      exit 1
    fi

    just _update-inner

_update-inner:
    nix flake update
    just switch

check all="false":
    #!/usr/bin/env bash
    set -euo pipefail

    if [ "{{ all }}" = "true" ]; then
      systems="x86_64-linux aarch64-linux"
      echo "Checking all systems: $systems"
    else
      systems=$(nix eval --impure --raw --expr 'builtins.currentSystem')
      echo "Checking current system: $systems"
    fi

    for sys in $systems; do
      echo ""
      echo "Building configurations for $sys..."

      # Build all checks for this system in one go to leverage Nix's deduplication
      checks=$(nix eval --json path:.#checks.$sys --apply builtins.attrNames | jq -r '.[]' | grep -v formatting || true)

      for check in $checks; do
        echo "  Checking: $check"
        nix build --no-link --print-out-paths path:.#checks.$sys.$check
      done

      echo "  ✓ All checks passed for $sys"
    done

    echo ""
    echo "✓ All checks completed successfully"

fmt:
    nix fmt path:.

gc:
    sudo nix-collect-garbage -d && nix-collect-garbage -d

optimize:
    nix-store --optimize -v

repair:
    sudo nix-store --verify --check-contents --repair

sops-edit:
    sops secrets/secrets.yaml

sops-rotate:
    for file in secrets/*; do sops --rotate --in-place "$file"; done

sops-update:
    for file in secrets/*; do sops updatekeys "$file"; done

find-impermanent:
  @scripts/find-impermanent-files.sh

mac-install:
  @./scripts/darwin-install.sh

# Publish dotfiles to public repository
# Use -f to skip checks and merge directly to main
publish *flags:
  ./scripts/publish.sh {{ flags }}

# Build templates manually (useful for testing/debugging)
# Usage: just template [machine]
# Defaults to current hostname
template machine='':
    #!/usr/bin/env bash
    set -euo pipefail
    
    if [ -z "{{ machine }}" ]; then
      machine=$(hostname)
    else
      machine="{{ machine }}"
    fi
    
    echo "Building templates for: $machine"

    rm -rf built

    # Get template config from Nix
    data_file=$(mktemp)
    nix eval --json "path:.#templateConfig.$machine" > "$data_file"
    
    echo "data_file written to: $data_file"
    
    # Run the template builder
    cd ts-utils
    bun install --frozen-lockfile
    bun run build-templates.ts --data-file "$data_file" --outDir ../built
    
    rm -f "$data_file"
    echo "Templates built to: built/"
