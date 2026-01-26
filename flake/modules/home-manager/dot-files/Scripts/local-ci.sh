#!/usr/bin/env bash

set -euo pipefail

# Work from git root (or current dir if not in a repo)
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo ".")"

# Exit codes:
# 0 = success
# 1 = no local-ci found
# 2 = command failed

# Check for override file first (highest precedence)
if [[ -x "./local-ci.sh" ]]; then
  echo "Using override: ./local-ci.sh"
  if ./local-ci.sh; then
    exit 0
  else
    exit 2
  fi
fi

# Detect package manager from lockfiles
detect_package_manager() {
  local found=()

  [[ -f "bun.lockb" || -f "bun.lock" ]] && found+=("bun")
  [[ -f "pnpm-lock.yaml" ]] && found+=("pnpm")
  [[ -f "package-lock.json" ]] && found+=("npm")
  [[ -f "yarn.lock" ]] && found+=("yarn")

  if [[ ${#found[@]} -gt 1 ]]; then
    echo "Error: Multiple lockfiles found: ${found[*]}" >&2
    echo "Create a local-ci.sh override to specify which to use" >&2
    exit 1
  fi

  if [[ ${#found[@]} -eq 1 ]]; then
    echo "${found[0]}"
  fi
}

# Check if package.json has the local-ci script
has_script() {
  local script="$1"

  if [[ ! -f "package.json" ]]; then
    return 1
  fi

  jq -e ".scripts[\"$script\"]" package.json >/dev/null 2>&1
}

# Run the command
run_ci() {
  local pm="$1"

  if ! has_script "local-ci"; then
    return 1
  fi

  echo "Detected: $pm"
  echo "Running: $pm run local-ci"

  if "$pm" run local-ci; then
    exit 0
  else
    exit 2
  fi
}

# Main logic
pm=$(detect_package_manager)

if [[ -n "$pm" ]]; then
  run_ci "$pm"
fi

# Nothing found - provide helpful error message
echo "Error: No local-ci found" >&2
echo "Looked for:" >&2
echo "  - ./local-ci.sh (executable override)" >&2
if [[ -n "${pm:-}" ]]; then
  echo "  - package.json script \"local-ci\" (not found, but detected $pm)" >&2
elif [[ -f "package.json" ]]; then
  echo "  - package.json script \"local-ci\" (no lockfile to detect package manager)" >&2
else
  echo "  - package.json script \"local-ci\"" >&2
fi
exit 0
