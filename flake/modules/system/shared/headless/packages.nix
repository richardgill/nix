{ pkgs, ... }:
{
  packages = with pkgs; [
    _1password-cli

    # Rescue toolkit for root, available even if the user's Home Manager profile is broken.
    # Also declared in Home Manager for portability; matching packages share one Nix-store installation.
    coreutils
    curl
    gawk
    git
    gnugrep
    gnused
    jq
    less
    openssl
    tmux
  ];
}
