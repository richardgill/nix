# Shared packages for macOS and NixOS
# Platform-specific packages: modules/home-manager/nixos/ and modules/home-manager/mac/
{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    argc
    bat
    btop
    delta
    dnsutils # dig, nslookup
    eza
    fd
    file # yazi uses this for mime type detection (previews)
    fzf
    gh
    lefthook
    nixfmt-rfc-style
    oh-my-posh
    postgresql
    ripgrep
    sesh
    stripe-cli
    socat
    xdg-utils
    yazi
    zoxide
  ];
}
