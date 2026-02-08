#!/usr/bin/env bash
# Based on https://github.com/basecamp/omarchy

compositor="$($HOME/Scripts/nixos/compositor)"
if [[ "$compositor" == "niri" ]]; then
  exec setsid chromium --app="$1" "${@:2}"
fi

if command -v uwsm >/dev/null 2>&1; then
  exec setsid uwsm app -- chromium --app="$1" "${@:2}"
fi

exec setsid chromium --app="$1" "${@:2}"
