local root_markers = {
  'settings.gradle',
  'settings.gradle.kts',
  'build.xml',
  'pom.xml',
  'build.gradle',
  'build.gradle.kts',
}

local has_file = function(path)
  return vim.uv.fs_stat(path) ~= nil
end

local react_native_root = function(filename)
  for parent in vim.fs.parents(filename) do
    if filename:find(parent .. '/modules/', 1, true) then
      if has_file(parent .. '/android/settings.gradle') or has_file(parent .. '/android/settings.gradle.kts') then
        return parent
      end
    end
  end
end

local shell_quote = function(value)
  return "'" .. value:gsub("'", "'\\''") .. "'"
end

local ensure_gradle_shim = function()
  local shim_dir = vim.fn.stdpath 'data' .. '/kotlin-gradle-shim'
  local shim_path = shim_dir .. '/gradle'
  vim.fn.mkdir(shim_dir, 'p')
  vim.fn.writefile({
    '#!/usr/bin/env bash',
    'set -euo pipefail',
    'if [ -x ./gradlew ]; then',
    '  exec ./gradlew "$@"',
    'fi',
    'if [ -x ./android/gradlew ]; then',
    '  cd android',
    '  exec ./gradlew "$@"',
    'fi',
    'echo "gradle wrapper not found from $PWD" >&2',
    'exit 127',
  }, shim_path)
  vim.uv.fs_chmod(shim_path, 493)
  return shim_dir
end

local ensure_language_server_shim = function()
  local server_path = vim.fn.exepath 'kotlin-language-server'
  if server_path == '' then
    return 'kotlin-language-server'
  end

  local shim_dir = vim.fn.stdpath 'data' .. '/kotlin-language-server-shim'
  local shim_path = shim_dir .. '/kotlin-language-server'
  vim.fn.mkdir(shim_dir, 'p')
  vim.fn.writefile({
    '#!/usr/bin/env bash',
    'set -euo pipefail',
    'server=' .. shell_quote(server_path),
    'server="$(readlink -f "$server")"',
    'wrapped="$(dirname "$server")/.kotlin-language-server-wrapped"',
    'if [ -x "$wrapped" ]; then',
    '  exec "$wrapped" "$@"',
    'fi',
    'exec "$server" "$@"',
  }, shim_path)
  vim.uv.fs_chmod(shim_path, 493)
  return shim_path
end

local cmd_env = function()
  return {
    ENVIRONMENT = vim.env.ENVIRONMENT or 'local',
    EXPO_PUBLIC_API_URL = vim.env.EXPO_PUBLIC_API_URL or vim.env.PUBLIC_API_URL or 'http://localhost',
    EXPO_PUBLIC_POSTHOG_KEY = vim.env.EXPO_PUBLIC_POSTHOG_KEY or vim.env.PUBLIC_POSTHOG_KEY or 'phc_local',
    JAVA_HOME = vim.env.JAVA_HOME,
    PATH = ensure_gradle_shim() .. ':' .. vim.env.PATH,
    PUBLIC_API_URL = vim.env.PUBLIC_API_URL or vim.env.EXPO_PUBLIC_API_URL or 'http://localhost',
    PUBLIC_POSTHOG_KEY = vim.env.PUBLIC_POSTHOG_KEY or vim.env.EXPO_PUBLIC_POSTHOG_KEY or 'phc_local',
  }
end

return {
  cmd = { ensure_language_server_shim() },
  cmd_env = cmd_env(),
  filetypes = { 'kotlin' },
  on_attach = function(client)
    client.server_capabilities.semanticTokensProvider = nil
  end,
  root_dir = function(bufnr, on_dir)
    local filename = vim.api.nvim_buf_get_name(bufnr)
    if filename:find '^codediff://' then
      return
    end

    local workspace_root = react_native_root(filename)
    if workspace_root then
      on_dir(workspace_root)
      return
    end

    local settings_root = vim.fs.root(bufnr, { 'settings.gradle', 'settings.gradle.kts' })
    if settings_root then
      on_dir(settings_root)
      return
    end

    local project_root = vim.fs.root(bufnr, root_markers)
    if project_root then
      on_dir(project_root)
    end
  end,
  root_markers = root_markers,
}
