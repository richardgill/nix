{
  lib,
  pkgs,
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
      swayosd
      sound-theme-freedesktop
      playerctl
      blender
    ]
    ++ lib.optionals (pkgs.stdenv.hostPlatform.system == "x86_64-linux") [
      beeper
    ];
}
