default:
    just --list

# path:. uses the path protocol to include untracked files (git protocol would require files to be staged)
_rebuild action machine='' extra_flags='':
    @if [ "$(uname)" = "Darwin" ]; then \
      command="nix run nix-darwin --"; \
      sudo_prefix="{{ if action == "switch" { "sudo" } else { "" } }}"; \
    else \
      command="nixos-rebuild"; \
      sudo_prefix="{{ if action == "switch" { "sudo" } else { "" } }}"; \
    fi; \
    if [ -z "{{ machine }}" ]; then \
      full_command="$sudo_prefix $command {{ action }} {{ extra_flags }} --flake path:./flake"; \
      echo "Running: $full_command"; \
      $sudo_prefix $command {{ action }} {{ extra_flags }} --flake path:./flake; \
    else \
      full_command="$sudo_prefix $command {{ action }} {{ extra_flags }} --flake \"path:./flake#{{ machine }}\""; \
      echo "Running: $full_command"; \
      $sudo_prefix $command {{ action }} {{ extra_flags }} --flake "path:./flake#{{ machine }}"; \
    fi

build machine='':
    @just _rebuild build "{{ machine }}"

switch machine='':
    @just template-bundle
    @if [ "$(uname)" = "Darwin" ]; then \
      just _rebuild switch "{{ machine }}"; \
    else \
      scripts/switch-fast.sh "{{ machine }}"; \
    fi

switch-debug machine='':
    #!/usr/bin/env bash
    set -euo pipefail
    start=$(date +%s)
    just template-bundle
    just _rebuild switch "{{ machine }}" "--debug --verbose --print-build-logs --log-format bar-with-logs" 2>&1 \
      | awk '{ print strftime("[%F %T]"), $0; fflush(); }'
    end=$(date +%s)
    echo "Total seconds: $((end - start))"

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
    nix flake update ./flake
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
      checks=$(nix eval --json path:./flake#checks.$sys --apply builtins.attrNames | jq -r '.[]' | grep -v formatting || true)

      for check in $checks; do
        echo "  Checking: $check"
        nix build --no-link --print-out-paths path:./flake#checks.$sys.$check
      done

      echo "  ✓ All checks passed for $sys"
    done

    echo ""
    echo "✓ All checks completed successfully"

fmt:
    nix fmt path:./flake

gc:
    sudo nix-collect-garbage -d && nix-collect-garbage -d

optimize:
    nix-store --optimize -v

repair:
    sudo nix-store --verify --check-contents --repair

sops-edit:
    sops flake/secrets/secrets.yaml

sops-rotate:
    for file in flake/secrets/*; do sops --rotate --in-place "$file"; done

sops-update:
    for file in flake/secrets/*; do sops updatekeys "$file"; done

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

    just template-bundle

    if [ -z "{{ machine }}" ]; then
      machine=$(hostname)
    else
      machine="{{ machine }}"
    fi

    echo "Building templates for: $machine"

    rm -rf built

    # Get template config from Nix
    data_file=$(mktemp)
    nix eval --json "path:./flake#templateConfig.$machine" > "$data_file"

    echo "data_file written to: $data_file"

    # Run the template builder
    cd flake/template-builder
    bun ./build-templates.bundle.js --data-file "$data_file" --outDir ../../built

    rm -f "$data_file"
    echo "Templates built to: built/"

template-bundle:
    #!/usr/bin/env bash
    set -euo pipefail

    cd ts-utils

    if [ ! -d node_modules ] || [ bun.lock -nt node_modules ] || [ package.json -nt node_modules ]; then
      bun install --frozen-lockfile
    fi

    mkdir -p ../flake/template-builder
    bun build build-templates.ts --target bun --outfile ../flake/template-builder/build-templates.bundle.js
