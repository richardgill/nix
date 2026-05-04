{
  pkgs,
  ...
}:
let
  treesitter-parsers = pkgs.vimPlugins.nvim-treesitter.withPlugins (p: [
    p.bash
    p.diff
    p.html
    p.lua
    p.luadoc
    p.markdown
    p.markdown_inline
    p.typescript
    p.vim
    p.vimdoc
  ]);
in
{
  home.packages = with pkgs; [
    # LSP servers
    astro-language-server
    biome
    gopls
    kotlin-language-server
    lua-language-server
    nixd
    nodePackages.vscode-langservers-extracted
    nodePackages."@tailwindcss/language-server"
    nodePackages.typescript-language-server
    pyright
    ruff
    vtsls

    # Formatters
    gofumpt
    nodePackages.prettier
    prettierd
    stylua
  ];

  home.file.".local/share/nvim/nix-treesitter/parser".source = "${treesitter-parsers}/parser";
}
