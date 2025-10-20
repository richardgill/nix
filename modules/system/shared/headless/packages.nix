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
    jq
    just
    less
    home-manager
    mise
    nixfmt-rfc-style
    nixd
    sops
    tmux
    unzip
  ];
}
