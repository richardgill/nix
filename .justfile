default:
    just --list

_rebuild action machine='':
    @if [ "$(uname)" = "Darwin" ]; then \
      command="nix run nix-darwin --"; \
      sudo_prefix="{{ if action == "switch" { "sudo" } else { "" } }}"; \
    else \
      command="nixos-rebuild"; \
      sudo_prefix="{{ if action == "switch" { "sudo" } else { "" } }}"; \
    fi; \
    if [ -z "{{ machine }}" ]; then \
      full_command="$sudo_prefix $command {{ action }} --flake ."; \
      echo "Running: $full_command"; \
      $sudo_prefix $command {{ action }} --flake .; \
    else \
      full_command="$sudo_prefix $command {{ action }} --flake \".#{{ machine }}\""; \
      echo "Running: $full_command"; \
      $sudo_prefix $command {{ action }} --flake ".#{{ machine }}"; \
    fi

build machine='':
    @just _rebuild build "{{ machine }}"

switch machine='':
    @just _rebuild switch "{{ machine }}"

update:
    nix flake update

check:
    nix flake check

fmt:
    nix fmt .

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
