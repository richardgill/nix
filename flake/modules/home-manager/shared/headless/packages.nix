# Shared packages for macOS and NixOS
# Platform-specific packages: modules/home-manager/nixos/ and modules/home-manager/mac/
{
  config,
  lib,
  pkgs,
  ...
}:
let
  unstable = pkgs.unstablePkgs;
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
    autossh
    bash
    bat
    btop
    cargo
    coreutils
    curl
    datamash
    delta
    dnsutils # dig, nslookup
    docker_29
    eternal-terminal
    eza
    fd
    ffmpeg
    file # yazi uses this for mime type detection (previews)
    findutils
    fzf
    gawk
    gcc
    unstable.gh
    gh-stack
    git
    git-lfs
    gnugrep
    gnused
    gnumake
    home-manager
    jq
    just
    lefthook
    less
    nix-fast-build
    nixfmt
    ncdu
    oh-my-posh
    openssl
    # Needed for Firefox build tooling (pkg-config).
    pkg-config
    postgresql
    qrencode
    ripgrep
    sops
    stripe-cli
    unstable.gws
    unstable.todoist
    socat
    unzip
    which
    xdg-utils
    xxd
    yazi
    zip
    zoxide
  ];
}
