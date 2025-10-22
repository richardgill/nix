{ pkgs, ... }:
{
  packages = with pkgs; [
    _1password-cli
    cargo
    coreutils
    claude-code
    curl
    datamash
    docker
    git
    git-lfs
    gnugrep
    gnused
    gnumake
    jq
    just
    less
    home-manager
    mise
    nixfmt-rfc-style
    nixd
    openssl
    sops
    tmux
    unzip
  ];
}
