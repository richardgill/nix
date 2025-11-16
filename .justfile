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
    nix flake update

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
publish:
  ./scripts/publish.sh
