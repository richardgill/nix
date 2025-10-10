{
  config,
  lib,
  pkgs,
  nixpkgs-unstable,
  ...
}:
let
  unstable = import nixpkgs-unstable {
    inherit (pkgs) system;
    config.allowUnfree = true;
  };
  isAarch64Linux = pkgs.system == "aarch64-linux";
in
{
  home.packages =
    with pkgs;
    [
      alacritty
      chromium
      cliphist
      evince
      glib
      hyprshot
      firefox
      imv
      mpv
      nautilus
      satty
      slurp
      sushi
      swayosd
      vscode
      walker
      wayland
      wf-recorder
      wl-clip-persist
      wl-clipboard
      unstable.wl-screenrec
      unstable.wiremix
    ]
    ++ lib.optionals (!isAarch64Linux) [
      ghostty
      slack
      spotify
      discord
      google-chrome
      unstable._1password-gui
      unstable.code-cursor
    ];
}
