default:
    just --list

_rebuild action machine='' ip='':
    @if [ "$(uname)" = "Darwin" ]; then \
      command="nix run nix-darwin --"; \
      sudo_flag=""; \
    else \
      command="nixos-rebuild"; \
      sudo_flag="{{ if action == "switch" { "--use-remote-sudo" } else { "" } }}"; \
    fi; \
    if [ -z "{{ machine }}" ] && [ -z "{{ ip }}" ]; then \
      full_command="$command {{ action }} $sudo_flag --flake ."; \
      echo "Running: $full_command"; \
      $full_command; \
    elif [ -z "{{ ip }}" ]; then \
      full_command="$command {{ action }} $sudo_flag --flake \".#{{ machine }}\""; \
      echo "Running: $full_command"; \
      $full_command; \
    else \
      full_command="$command {{ action }} --fast --flake \".#{{ machine }}\" $sudo_flag --target-host \"eh8@{{ ip }}\" --build-host \"eh8@{{ ip }}\""; \
      echo "Running: $full_command"; \
      $full_command; \
    fi

build machine='' ip='':
    @just _rebuild build "{{ machine }}" "{{ ip }}"

deploy machine='' ip='':
    @just _rebuild switch "{{ machine }}" "{{ ip }}"

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

first-install machine:
  ./first-install.sh {{machine}}

find-impermanent:
  @scripts/find-impermanent-files.sh

# Publish dotfiles to public repository
publish:
    ./scripts/publish.sh
