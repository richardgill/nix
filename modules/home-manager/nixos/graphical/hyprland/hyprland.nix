{ ... }:
{
  systemd.user.targets.hyprland-session.Unit.Wants = [
    "xdg-desktop-autostart.target"
  ];
  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    portalPackage = null;
    extraConfig = builtins.readFile ./hyprland.conf;
    xwayland = {
      enable = true;
    };
    systemd.enable = false;
  };

  # home.file.".config/hypr/hyprland.conf".source = ./hyprland.conf;
}
