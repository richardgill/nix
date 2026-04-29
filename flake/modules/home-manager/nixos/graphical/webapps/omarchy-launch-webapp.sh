#!/usr/bin/env bash
# Based on https://github.com/basecamp/omarchy

if command -v uwsm >/dev/null 2>&1 && uwsm check is-active >/dev/null 2>&1; then
  exec setsid uwsm app -- chromium --app="$1" "${@:2}"
fi

exec setsid chromium --app="$1" "${@:2}"
