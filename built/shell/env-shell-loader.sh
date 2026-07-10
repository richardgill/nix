# Dynamically loads .env.shell and .env.*.shell files by traversing up parent directories
# Pattern inspired by https://gist.github.com/krzyzanowskim/07450322713433af08798a6ab0c0ce8f
__env_shell_state_file="${XDG_RUNTIME_DIR:-/tmp}/env-shell-loader.$$"
__env_shell_last_pwd=""

__env_shell_trim() {
  local value="$1"
  value="${value#"${value%%[!$' \t\r\n']*}"}"
  value="${value%"${value##*[!$' \t\r\n']}"}"
  printf '%s' "$value"
}

__env_shell_restore_previous() {
  [ -f "$__env_shell_state_file" ] || return 0
  source "$__env_shell_state_file"
  : > "$__env_shell_state_file"
}

__env_shell_quote() {
  local value="$1"
  local quoted="'"

  while [ -n "$value" ]; do
    case "$value" in
      *"'"*)
        quoted="$quoted${value%%\'*}'\\''"
        value="${value#*\'}"
        ;;
      *)
        quoted="$quoted$value"
        value=""
        ;;
    esac
  done

  printf "%s'" "$quoted"
}

__env_shell_record_previous() {
  local name="$1"
  local old

  if eval '[ "${'"$name"'+__env_shell_set}" = "__env_shell_set" ]'; then
    eval "old=\"\${$name}\""
    printf 'export %s=%s\n' "$name" "$(__env_shell_quote "$old")" >> "$__env_shell_state_file"
  else
    printf 'unset %s\n' "$name" >> "$__env_shell_state_file"
  fi
}

__env_shell_record_name() {
  local name="$1"

  [[ "$name" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]] || return

  case "$__env_shell_loaded_names" in
    *$'\n'"$name"$'\n'*) ;;
    *)
      __env_shell_record_previous "$name"
      __env_shell_loaded_names="$__env_shell_loaded_names$name"$'\n'
      ;;
  esac
}

__env_shell_record_file_names() {
  local file="$1"
  local line name

  while IFS= read -r line || [ -n "$line" ]; do
    line="$(__env_shell_trim "$line")"
    [ -n "$line" ] || continue
    [ "${line#\#}" = "$line" ] || continue

    case "$line" in
      export[[:space:]]*) line="$(__env_shell_trim "${line#export}")" ;;
    esac

    case "$line" in
      *=*) ;;
      *) continue ;;
    esac

    name="$(__env_shell_trim "${line%%=*}")"
    __env_shell_record_name "$name"
  done < "$file"
}

__env_shell_load_file() {
  local file="$1"
  local had_allexport=""
  local load_status

  [ -r "$file" ] || return 0
  # Source the file instead of parsing lines so multiline shell-quoted env vars work.
  __env_shell_record_file_names "$file"

  case "$-" in
    *a*) had_allexport="1" ;;
  esac

  set -a
  source "$file"
  load_status=$?
  [ -n "$had_allexport" ] || set +a
  return "$load_status"
}

__env_shell_reload() {
  local dir="$PWD"
  local dirs=()
  local env_dir

  __env_shell_restore_previous
  __env_shell_loaded_names=$'\n'

  [ "$dir" = "$HOME" ] || [ "${dir#"$HOME/"}" != "$dir" ] || return 0

  while true; do
    dirs=("$dir" "${dirs[@]}")
    [ "$dir" = "$HOME" ] && break
    dir="${dir%/*}"
  done

  for env_dir in "${dirs[@]}"; do
    __env_shell_load_file "$env_dir/.env.shell"
    while IFS= read -r env_file; do
      __env_shell_load_file "$env_file"
    done < <(find "$env_dir" -maxdepth 1 -name '.env.*.shell' -print | sort)
  done
}

__env_shell_bash_hook() {
  local previous_exit_status=$?

  if [ "${__env_shell_last_pwd:-}" != "$PWD" ]; then
    __env_shell_reload
    __env_shell_last_pwd="$PWD"
  fi

  return "$previous_exit_status"
}

__env_shell_zsh_hook() {
  __env_shell_reload
  __env_shell_last_pwd="$PWD"
}

__env_shell_install() {
  if [ -n "${ZSH_VERSION:-}" ]; then
    autoload -Uz add-zsh-hook
    add-zsh-hook chpwd __env_shell_zsh_hook
    __env_shell_zsh_hook
    return
  fi

  if [ -n "${BASH_VERSION:-}" ]; then
    __env_shell_bash_hook
    if [[ ";${PROMPT_COMMAND[*]:-};" != *";__env_shell_bash_hook;"* ]]; then
      if [[ "$(declare -p PROMPT_COMMAND 2>&1)" == "declare -a"* ]]; then
        PROMPT_COMMAND=(__env_shell_bash_hook "${PROMPT_COMMAND[@]}")
      else
        PROMPT_COMMAND="__env_shell_bash_hook${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
      fi
    fi
  fi
}

__env_shell_install
