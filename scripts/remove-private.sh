#!/usr/bin/env bash

set -euo pipefail

if [ $# -eq 0 ]; then
  input_file="-"
else
  input_file="$1"
fi

sed '/^[[:space:]]*\(#\|\/\/\|\/\*\|\*\).*PRIVATE-START/,/^[[:space:]]*\(#\|\/\/\|\/\*\|\*\).*PRIVATE-END/d' "$input_file"
