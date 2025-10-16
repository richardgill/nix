{
  config,
  lib,
  pkgs,
  nixpkgs-unstable,
  ...
}:
{
  environment.systemPackages =
    with pkgs;
    [
      wl-clipboard
      xclip
      xdg-utils
      mako
      hypridle
      swayosd
      sound-theme-freedesktop
      playerctl
    ]
    ++ lib.optionals (pkgs.stdenv.system == "x86_64-linux") [
      beeper
    ];
}
