{ config, lib, pkgs, nixpkgs-unstable, ... }:

{
  environment.systemPackages = with pkgs; [
    hack-font
    wl-clipboard
    xclip
    xdg-utils
    mako
    hypridle
    swayosd
    sound-theme-freedesktop
    beeper
    playerctl
  ];

  # User applications moved to home-manager: modules/home-manager/nixos/graphical/packages.nix
  # XDG mime configuration moved to home-manager: modules/home-manager/nixos/graphical/mimetypes.nix
}
