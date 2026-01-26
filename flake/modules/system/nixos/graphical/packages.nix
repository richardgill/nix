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
      libsecret
      mako
      hypridle
      swayosd
      sound-theme-freedesktop
      playerctl
    ]
    ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [
      beeper
    ];
}
