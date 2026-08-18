#!/usr/bin/env bash
set -euo pipefail

if [ "$(uname)" = "Darwin" ]; then
  echo "Fast switch is only supported on NixOS." >&2
  exit 1
fi

machine="${1:-$(hostname)}"

attr="path:./flake#nixosConfigurations.\"${machine}\".config.system.build.toplevel"
out_link=".nix-fast-build/nixos-system"
install_bootloader="${NIXOS_INSTALL_BOOTLOADER:-0}"

mkdir -p "$(dirname "$out_link")"
nix build --out-link "$out_link" "$attr"

path_to_config="$(readlink -f "$out_link")"

if [ ! -f "${path_to_config}/nixos-version" ] && [ -z "${NIXOS_REBUILD_I_UNDERSTAND_THE_CONSEQUENCES_PLEASE_BREAK_MY_SYSTEM:-}" ]; then
  echo "Missing nixos-version in ${path_to_config}." >&2
  echo "Set NIXOS_REBUILD_I_UNDERSTAND_THE_CONSEQUENCES_PLEASE_BREAK_MY_SYSTEM=1 to continue." >&2
  exit 1
fi

sudo nix-env -p /nix/var/nix/profiles/system --set "$path_to_config"

if [ -d /run/systemd/system ]; then
  NIXOS_INSTALL_BOOTLOADER="$install_bootloader" sudo systemd-run \
    -E LOCALE_ARCHIVE \
    -E NIXOS_INSTALL_BOOTLOADER \
    --collect \
    --no-ask-password \
    --pipe \
    --quiet \
    --service-type=exec \
    --unit=nixos-rebuild-switch-to-configuration \
    "${path_to_config}/bin/switch-to-configuration" switch
else
  NIXOS_INSTALL_BOOTLOADER="$install_bootloader" sudo "${path_to_config}/bin/switch-to-configuration" switch
fi

echo "Done. The new configuration is ${path_to_config}"
