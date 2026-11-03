return {
  cmd = { 'nixd' },
  filetypes = { 'nix' },
  root_markers = { 'flake.nix', '.git' },
  settings = {
    nixd = {
      nixpkgs = {
        expr = 'import (builtins.getFlake "' .. vim.fn.getcwd() .. '").inputs.nixpkgs { }',
      },
      formatting = {
        command = { 'nixfmt' },
      },
      options = {
        nixos = {
          expr = '(builtins.getFlake "' .. vim.fn.getcwd() .. '").nixosConfigurations.um790.options',
        },
        home_manager = {
          expr = '(builtins.getFlake "' .. vim.fn.getcwd() .. '").nixosConfigurations.um790.options.home-manager.users.type.getSubOptions []',
        },
      },
    },
  },
}
