#!/usr/bin/env bash

workspace="$1"
app="$2"

hyprctl dispatch exec "[workspace $workspace] uwsm app -- $app"
