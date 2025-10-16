{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    bat
    btop
    delta
    eza
    fd
    fzf
    gh
    nixfmt-rfc-style
    oh-my-posh
    ripgrep
    sesh
    xdg-utils
    yazi
    zoxide
    (pkgs.writeShellScriptBin "open" ''
      exec ${pkgs.xdg-utils}/bin/xdg-open "$@"
    '')
  ];
}
