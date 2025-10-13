{ ... }:
{
  systemd.user.targets.hyprland-session.Unit.Wants = [
    "xdg-desktop-autostart.target"
  ];
  wayland.windowManager.hyprland = {
    enable = false;
    package = null;
    portalPackage = null;

    xwayland = {
      enable = true;
    };
    systemd.enable = false;
  };

  home.file.".config/hypr/hyprland.conf".source = ./hyprland.conf;
}
