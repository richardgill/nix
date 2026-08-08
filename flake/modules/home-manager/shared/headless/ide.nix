{
  pkgs,
  nixpkgs-unstable,
  ...
}:
let
  unstable = import nixpkgs-unstable {
    inherit (pkgs.stdenv.hostPlatform) system;
  };
  treesitter = unstable.vimPlugins.nvim-treesitter.withPlugins (p: [
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
  treesitter-runtime = unstable.symlinkJoin {
    name = "nvim-treesitter-runtime";
    paths = treesitter.dependencies;
  };
in
{
  home.packages = with pkgs; [
    neovim

    # LSP servers
    astro-language-server
    biome
    gopls
    kotlin-language-server
    lua-language-server
    nixd
    vscode-langservers-extracted
    tailwindcss-language-server
    pyright
    ruff
    unstable.typescript-go

    # Formatters
    gofumpt
    ktfmt
    prettier
    prettierd
    stylua
  ];

  home.file = {
    ".local/share/nvim/nix-treesitter/parser".source = "${treesitter-runtime}/parser";
    ".local/share/nvim/nix-treesitter/queries".source =
      "${unstable.vimPlugins.nvim-treesitter}/runtime/queries";
  };
}
