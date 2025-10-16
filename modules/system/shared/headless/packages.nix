{ pkgs, ... }:
{
  packages = with pkgs; [
    _1password-cli
    cargo
    coreutils
    claude-code
    curl
    docker
    git
    git-lfs
    gnugrep
    gnused
    jq
    just
    less
    home-manager
    nixfmt-rfc-style
    nixd
    sops
    tmux
    unzip
  ];
}
