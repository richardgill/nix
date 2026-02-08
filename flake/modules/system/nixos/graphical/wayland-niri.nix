{
  pkgs,
  ...
}:
{
  imports = [ ./wayland-base.nix ];

  environment.sessionVariables = {
    XDG_CURRENT_DESKTOP = "niri";
    XDG_SESSION_DESKTOP = "niri";
  };

  programs.niri = {
    enable = true;
    package = pkgs.niri;
  };

  xdg.portal = {
    config = {
      common.default = [ "gtk" ];
      niri = {
        default = [
          "gnome"
          "gtk"
        ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      };
    };

    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
    ];
  };
}
