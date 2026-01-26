local M = {}

local providers = {
  ripgrep_files = {
    name = 'RipgrepFiles',
    module = 'custom.ai-prompt-completion-blink.ripgrep-files-provider',
    enabled = function()
      return vim.bo.filetype == 'prompt'
    end,
  },
  prompt_commands = {
    name = 'PromptCommands',
    module = 'custom.ai-prompt-completion-blink.prompt-commands-provider',
    enabled = function()
      return vim.bo.filetype == 'prompt'
    end,
  },
}

local ensure_providers = function()
  local config = require('blink.cmp.config')
  local add = require('blink.cmp').add_source_provider
  for id, provider in pairs(providers) do
    if not config.sources.providers[id] then
      add(id, provider)
    end
  end
end

local ensure_prompt_sources = function()
  local config = require('blink.cmp.config')
  config.sources.per_filetype.prompt = { 'prompt_commands', 'ripgrep_files' }
end

M.setup = function()
  ensure_providers()
  ensure_prompt_sources()
  require('custom.ai-prompt-completion-blink.keyword')
end

return M
