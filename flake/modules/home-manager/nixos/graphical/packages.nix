# NixOS-specific packages
# Shared packages: modules/home-manager/shared/
{
  config,
  lib,
  pkgs,
  nixpkgs-unstable,
  inputs,
  vars,
  ...
}:
let
  unstable = import nixpkgs-unstable {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
  isAarch64Linux = pkgs.stdenv.hostPlatform.system == "aarch64-linux";
  isNiri = (vars.waylandCompositor or "hyprland") == "niri";
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
      hyprpolkitagent
      hyprpaper
      hyprshot
      firefox
      imv
      mpv
      video-trimmer
      p7zip
      satty
      slurp
      swayidle
      swaylock
      swayosd
      brightnessctl
      vscode
      walker
      wayland
      wf-recorder
      wl-clip-persist
      wl-clipboard
      unstable.wl-screenrec
      unstable.wiremix
      xournalpp
      inputs.voxtype.packages.${pkgs.stdenv.hostPlatform.system}.vulkan
    ]
    ++ lib.optionals (!isAarch64Linux) [
      ghostty
      slack
      spotify
      discord
      (google-chrome.override {
        commandLineArgs = [
          "--remote-debugging-port=9222"
          "--remote-debugging-address=127.0.0.1"
          "--user-data-dir=${config.home.homeDirectory}/.config/google-chrome-remote-debug"
        ];
      })
      todoist-electron
      unstable._1password-gui
      unstable.code-cursor
    ]
    ++ lib.optionals isNiri [
      swaybg
      xsettingsd
      xwayland-satellite
    ];
}
