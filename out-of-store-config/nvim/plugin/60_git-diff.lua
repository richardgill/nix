-- Restart Neovim after changing the viewer: 'codediff' or 'diffview'.
local viewer = 'diffview'

require('custom.diff.' .. viewer)
