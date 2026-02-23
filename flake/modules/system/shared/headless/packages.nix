{ pkgs, nixpkgs-unstable, ... }:
let
  unstable = import nixpkgs-unstable {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };
in
{
  packages = with pkgs; [
    _1password-cli
    android-tools
    autossh
    eternal-terminal
    cargo
    coreutils
    curl
    datamash
    docker
    ffmpeg
    gcc
    gawk
    git
    git-lfs
    gnugrep
    gnused
    gnumake
    jq
    just
    less
    home-manager
    unstable.mise
    nix-fast-build
    nixfmt-rfc-style
    nixd
    openssl
    sops
    tmux
    unzip
    zip
  ];
}
