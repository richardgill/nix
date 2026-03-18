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
    jdk17
    just
    # Needed for Firefox build tooling (pkg-config).
    pkg-config
    less
    home-manager
    unstable.mise
    nix-fast-build
    nixfmt-rfc-style
    nixd
    openssl
    qrencode
    sops
    tmux
    unzip
    xxd
    zip
  ];
}
