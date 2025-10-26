{
  pkgs,
  ...
}:
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
    pyright
    ruff
    vtsls

    # Formatters
    gofumpt
    nodePackages.prettier
    prettierd
    stylua
  ];
}
