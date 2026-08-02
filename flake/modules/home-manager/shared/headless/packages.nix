# Shared packages for macOS and NixOS
# Platform-specific packages: modules/home-manager/nixos/ and modules/home-manager/mac/
{
  lib,
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
  home.activation.installGhStack = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    extension_dir="$HOME/.local/share/gh/extensions/gh-stack"
    if ! ${pkgs.gnugrep}/bin/grep -qx 'tag: v0.1.0' "$extension_dir/manifest.yml" 2>/dev/null || ! ${pkgs.gnugrep}/bin/grep -qx 'ispinned: true' "$extension_dir/manifest.yml" 2>/dev/null; then
      ${unstable.gh}/bin/gh extension install github/gh-stack --force --pin v0.1.0
    fi
  '';

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
    unstable.gh
    lefthook
    nixfmt-rfc-style
    ncdu
    oh-my-posh
    postgresql
    ripgrep
    stripe-cli
    unstable.gws
    unstable.todoist
    socat
    xdg-utils
    yazi
    zoxide
  ];
}
