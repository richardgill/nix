#!/usr/bin/env bash
# Based on https://github.com/richardgill/omarchy

url="$1"
web_url="https://app.zoom.us/wc/home"

if [[ $url =~ ^zoom(mtg|us):// ]]; then
  confno=$(echo "$url" | sed -n 's/.*[?&]confno=\([^&]*\).*/\1/p')

  if [[ -n $confno ]]; then
    pwd=$(echo "$url" | sed -n 's/.*[?&]pwd=\([^&]*\).*/\1/p')

    if [[ -n $pwd ]]; then
      web_url="https://app.zoom.us/wc/join/$confno?pwd=$pwd"
    else
      web_url="https://app.zoom.us/wc/join/$confno"
    fi
  fi
fi

compositor="$($HOME/Scripts/nixos/compositor)"
if [[ "$compositor" == "niri" ]]; then
  existing_zoom=$(niri msg --json windows \
    | jq -r '.[] | select(.app_id | startswith("chrome-app.zoom")) | .pid' \
    | head -1)
  niri msg action focus-workspace zoom
else
  existing_zoom=$(hyprctl clients -j | jq -r '.[] | select(.class | test("chrome-app.zoom")) | .pid')
  hyprctl dispatch workspace 19
fi

if [[ -n "$existing_zoom" ]]; then
  kill "$existing_zoom"
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    kill -0 "$existing_zoom" 2>/dev/null || break
    sleep 0.1
  done
fi

exec omarchy-launch-webapp "$web_url" --user-data-dir="${ZOOM_USER_DATA_DIR:-$HOME/.config/chromium-zoom}"
