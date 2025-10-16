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

hyprctl dispatch workspace 19

existing_zoom=$(hyprctl clients -j | jq -r '.[] | select(.class | test("chrome-app.zoom")) | .pid')

if [[ -n "$existing_zoom" ]]; then
  kill "$existing_zoom"
fi

exec omarchy-launch-webapp "$web_url"
