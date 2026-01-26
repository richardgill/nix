-- OSC52 + tmux clipboard integration for SSH + TMUX copy and paste (paste is hard!)
-- To make this work we had to set ghossty clipboard-read = allow; clipboard-write = allow
-- Source: https://github.com/bobrippling/nvim-osc52-tmux/blob/main/plugin/osc52-tmux.lua
-- Related: https://github.com/neovim/neovim/discussions/29350#discussioncomment-11127983
-- Root cause in Tmux: https://github.com/tmux/tmux/issues/4275

local M = {}

M.setup = function(opts)
  local paste_wrap = function(paste_fn)
    if os.getenv 'TMUX' then
      local stat = os.execute 'tmux refresh-client -l'
      if stat ~= 0 then
        vim.notify "couldn't refresh tmux client (osc52-tmux)"
      end
      vim.uv.sleep(50)
    end

    return paste_fn()
  end

  local osc52 = require 'vim.ui.clipboard.osc52'

  vim.g.clipboard = {
    name = 'tmux-osc-52',
    copy = {
      ['+'] = osc52.copy '+',
      ['*'] = osc52.copy(opts.force_plus and '+' or '*'),
    },
    paste = {
      ['+'] = function()
        return paste_wrap(osc52.paste '+')
      end,
      ['*'] = function()
        return paste_wrap(osc52.paste '*')
      end,
    },
  }
end

return M
