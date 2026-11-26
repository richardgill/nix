#!/usr/bin/env bash
set -euo pipefail

action="${1:?expected build or switch}"
machine="${2:-$(hostname -s)}"
if [[ $# -ge 2 ]]; then
  shift 2
else
  shift
fi

if [[ "$action" != build && "$action" != switch ]]; then
  echo "Unsupported Home Manager action: $action" >&2
  exit 1
fi
if [[ "$EUID" == 0 ]]; then
  echo "Run Home Manager as your login user, not root." >&2
  exit 1
fi

activation=$(nix build --no-link --print-out-paths "$@" \
  "path:./flake#homeConfigurations.\"${machine}\".activationPackage")
if [[ "$action" == switch ]]; then
  HOME_MANAGER_BACKUP_EXT="${HOME_MANAGER_BACKUP_EXT-backup}" "$activation/activate"
fi
printf 'Home Manager %s: %s\n' "$action" "$activation"
