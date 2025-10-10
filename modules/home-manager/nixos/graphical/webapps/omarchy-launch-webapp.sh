#!/usr/bin/env bash
# Based on https://github.com/richardgill/omarchy

exec setsid uwsm app -- chromium --app="$1" "${@:2}"
