{
  config,
  lib,
  pkgs,
  nixpkgs-unstable,
  ...
}:
{
  environment.systemPackages = with pkgs; [
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

  programs.ydotool.enable = true;
}
