--[[
Shows changes against remote main behind local Gitsigns changes.
Prefers upstream/main, then origin/main, and compares from their merge base.
Signs share Gitsigns symbols with muted colors; local signs win on overlap.
VCSigns is display-only here, with no keybindings or other features enabled.
]]

vim.pack.add {
  'https://github.com/algmyr/vcsigns.nvim',
  'https://github.com/algmyr/vclib.nvim',
  'https://github.com/lewis6991/async.nvim',
}

local git_sign_symbols = require 'config.git-sign-symbols'
local actions = require 'vcsigns.actions'
local state = require 'vcsigns.state'
local updates = require 'vcsigns.updates'

local function run_git(cwd, args)
  local command = vim.list_extend({ 'git' }, args)
  local result = vim.system(command, { cwd = cwd, text = true }):wait(2000)
  if result.code ~= 0 then
    return nil
  end
  return vim.trim(result.stdout or '')
end

local function select_remote_main(refs)
  for _, preferred in ipairs { 'refs/remotes/upstream/main', 'refs/remotes/origin/main' } do
    if vim.list_contains(refs, preferred) then
      return preferred
    end
  end
  for _, ref in ipairs(refs) do
    if ref:match '^refs/remotes/[^/]+/main$' then
      return ref
    end
  end
end

local function find_remote_base(bufnr)
  local path = vim.api.nvim_buf_get_name(bufnr)
  local cwd = vim.fn.fnamemodify(path, ':p:h')
  local root = run_git(cwd, { 'rev-parse', '--show-toplevel' })
  if not root then
    return nil
  end
  local refs = run_git(root, { 'for-each-ref', '--format=%(refname)', 'refs/remotes' })
  local remote_main = refs and select_remote_main(vim.split(refs, '\n', { trimempty = true }))
  if not remote_main then
    return nil
  end
  return root, run_git(root, { 'merge-base', 'HEAD', remote_main })
end

local function stop_remote_signs(bufnr)
  if vim.api.nvim_buf_is_valid(bufnr) then
    actions.stop(bufnr)
  end
end

local function attach_remote_signs(bufnr, root, base)
  local repo_state = state.repo_get(root)
  local current_vcs = state.get(bufnr).vcs.vcs
  local base_changed = repo_state.revset ~= base
  local needs_attach = not current_vcs or current_vcs.root ~= root
  repo_state.revset = base
  if needs_attach then
    stop_remote_signs(bufnr)
    actions.start(bufnr)
  end
  if base_changed then
    state.mark_vcs_dirty(bufnr)
  end
  if base_changed and not needs_attach then
    updates.deep_update(bufnr)
  end
end

local function update_remote_signs(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  local path = vim.api.nvim_buf_get_name(bufnr)
  local file = path ~= '' and vim.uv.fs_stat(path)
  if vim.bo[bufnr].buftype ~= '' or not file or file.type ~= 'file' then
    stop_remote_signs(bufnr)
    return
  end
  local root, base = find_remote_base(bufnr)
  if not base then
    stop_remote_signs(bufnr)
    return
  end
  attach_remote_signs(bufnr, root, base)
end

require('vcsigns').setup {
  auto_enable = false,
  signs = {
    text = {
      add = git_sign_symbols.add,
      change = git_sign_symbols.change,
      delete_below = git_sign_symbols.delete,
      delete_above = git_sign_symbols.topdelete,
      delete_above_below = git_sign_symbols.change,
      combined = git_sign_symbols.change,
    },
    hl = {
      add = 'RemoteGitSignAdd',
      change = 'RemoteGitSignChange',
      delete = 'RemoteGitSignDelete',
      combined = 'RemoteGitSignChange',
    },
    priority = 5, -- Gitsigns defaults to 6, so local changes win the single sign column.
  },
}

local group = vim.api.nvim_create_augroup('RemoteGitSigns', { clear = true })
vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufNewFile', 'FocusGained', 'ShellCmdPost' }, {
  group = group,
  callback = function(event)
    update_remote_signs(event.buf)
  end,
})
vim.api.nvim_create_autocmd('BufWipeout', {
  group = group,
  callback = function(event)
    stop_remote_signs(event.buf)
  end,
})
