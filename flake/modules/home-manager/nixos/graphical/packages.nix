# NixOS-specific packages
# Shared packages: modules/home-manager/shared/
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  unstable = pkgs.unstablePkgs;
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
      evince
      file-roller
      glib
      grim
      firefox
      imv
      mpv
      video-trimmer
      p7zip
      satty
      slurp
      swaybg
      swayidle
      swaylock
      swayosd
      brightnessctl
      vscode
      wayland
      wf-recorder
      wl-clip-persist
      wl-clipboard
      unstable.wl-screenrec
      unstable.wiremix
      xsettingsd
      xwayland-satellite
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
    ];
}
