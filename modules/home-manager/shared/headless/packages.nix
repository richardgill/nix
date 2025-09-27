{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    bat
    btop
    delta
    eza
    fzf
    gh
    nixfmt-rfc-style
    oh-my-posh
    ripgrep
    sesh
    yazi
    zoxide
  ];
}