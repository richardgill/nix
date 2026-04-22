# Shared packages for macOS and NixOS
# Platform-specific packages: modules/home-manager/nixos/ and modules/home-manager/mac/
{
  pkgs,
  nixpkgs-unstable,
  ...
}:
let
  unstable = import nixpkgs-unstable {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };
in
{
  home.packages =
    with pkgs;
    [
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
      ncdu
      oh-my-posh
      postgresql
      ripgrep
      sesh
      stripe-cli
      unstable.gws
      unstable.todoist
      socat
      xdg-utils
      yazi
      zoxide
    ];
}
