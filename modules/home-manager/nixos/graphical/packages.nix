# NixOS-specific packages
# Shared packages: modules/home-manager/shared/
{
  config,
  lib,
  pkgs,
  nixpkgs-unstable,
  inputs,
  ...
}:
let
  unstable = import nixpkgs-unstable {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
  isAarch64Linux = pkgs.stdenv.hostPlatform.system == "aarch64-linux";
in
{
  home.sessionVariables = {
    PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH = lib.getExe pkgs.chromium;
  };

  home.packages =
    with pkgs;
    [
      alacritty
      bubblewrap

      # Fix Chromium crash on Wayland/Hyprland with color management
      # https://github.com/hyprwm/Hyprland/discussions/11843
      (chromium.override {
        commandLineArgs = [
          "--disable-features=WaylandWpColorManagerV1"
        ];
      })
      cliphist
      evince
      file-roller
      glib
      hyprpaper
      hyprshot
      firefox
      imv
      mpv
      p7zip
      satty
      slurp
      swayosd
      vscode
      walker
      wayland
      wf-recorder
      wl-clip-persist
      wl-clipboard
      unstable.wl-screenrec
      unstable.wiremix
      xournalpp
      inputs.voxtype.packages.${pkgs.system}.vulkan
    ]
    ++ lib.optionals (!isAarch64Linux) [
      ghostty
      slack
      spotify
      discord
      google-chrome
      todoist-electron
      unstable._1password-gui
      unstable.code-cursor
    ];
}
