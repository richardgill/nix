#!/usr/bin/env bash
# Based on https://github.com/basecamp/omarchy

exec setsid uwsm app -- chromium --app="$1" "${@:2}"
