{ pkgs, ... }:
let
  unstable = pkgs.unstablePkgs;
in
{
  packages = with pkgs; [
    _1password-cli
    autossh
    eternal-terminal
    cargo
    coreutils
    curl
    datamash
    docker_29
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
    # Needed for Firefox build tooling (pkg-config).
    pkg-config
    less
    home-manager
    unstable.mise
    nix-fast-build
    nixfmt
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
