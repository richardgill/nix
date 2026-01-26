#!/usr/bin/env bash
set -euo pipefail

if [ "$(uname)" = "Darwin" ]; then
  echo "nix-fast-build switch is only supported on NixOS." >&2
  exit 1
fi

machine="${1:-$(hostname)}"

attr="path:./flake#nixosConfigurations.\"${machine}\".config.system.build.toplevel"
out_link_dir=".nix-fast-build"
out_link_prefix="${out_link_dir}/nix-fast-build-result"
install_bootloader="${NIXOS_INSTALL_BOOTLOADER:-0}"

eval_workers="${NIX_FAST_BUILD_EVAL_WORKERS:-3}"

mkdir -p "$out_link_dir"
rm -f "${out_link_prefix}"*

eval_cache_disable="${NIX_FAST_BUILD_DISABLE_EVAL_CACHE:-1}"

set -- -f "$attr" --out-link "$out_link_prefix" --no-nom --eval-workers "$eval_workers"
if [ "$eval_cache_disable" = "1" ]; then
  set -- "$@" --option eval-cache false
fi

nix_conf_dir=""
if [ -f /etc/nix/nix.conf ]; then
  nix_conf_dir="$(mktemp -d)"
  # Filter Determinate-only settings that nix-fast-build's nix doesn't recognize.
  filter_regex='^(allowed-users|trusted-users|eval-cores|lazy-trees|bash-prompt-prefix) ='
  grep -vE "$filter_regex" /etc/nix/nix.conf > "${nix_conf_dir}/nix.conf"
  if [ -f /etc/nix/nix.custom.conf ]; then
    grep -vE "$filter_regex" /etc/nix/nix.custom.conf > "${nix_conf_dir}/nix.custom.conf"
  fi
fi

if [ -n "$nix_conf_dir" ]; then
  NIX_CONF_DIR="$nix_conf_dir" nix run nixpkgs#nix-fast-build -- "$@"
  rm -rf "$nix_conf_dir"
else
  nix run nixpkgs#nix-fast-build -- "$@"
fi

out_link="$out_link_prefix"
if [ ! -e "$out_link" ]; then
  shopt -s nullglob
  matches=("${out_link_prefix}"*)
  shopt -u nullglob
  if [ "${#matches[@]}" -eq 1 ]; then
    out_link="${matches[0]}"
  else
    echo "Unable to locate nix-fast-build output link for ${out_link_prefix}." >&2
    exit 1
  fi
fi

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
