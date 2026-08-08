# Shared packages for macOS and NixOS
# Platform-specific packages: modules/home-manager/nixos/ and modules/home-manager/mac/
{
  config,
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
  home.activation.removeMutableGhStack = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    stack_dir="${config.xdg.dataHome}/gh/extensions/gh-stack"
    if [[ -e "$stack_dir" && ! -L "$stack_dir" ]]; then
      run rm -rf "$stack_dir"
    fi
    if [[ -e "$stack_dir.backup" ]]; then
      run rm -rf "$stack_dir.backup"
    fi
  '';

  xdg.dataFile."gh/extensions/gh-stack".source = "${pkgs.gh-stack}/bin";

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
    gh-stack
    lefthook
    nixfmt
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
