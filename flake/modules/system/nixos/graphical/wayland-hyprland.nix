{
  pkgs,
  ...
}:
{
  imports = [
    ./wayland-base.nix
    ./hyprland.nix
  ];

  environment.sessionVariables = {
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_DESKTOP = "Hyprland";
  };

  xdg.portal = {
    config = {
      common.default = [ "gtk" ];
      hyprland = {
        default = [
          "hyprland"
          "gtk"
        ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      };
    };

    # note: screen sharing dialogs on chromium: https://github.com/hyprwm/xdg-desktop-portal-hyprland/issues/11
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
    ];
  };
}
