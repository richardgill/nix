{
  lib,
  pkgs,
  ...
}:
let
  niriSession = pkgs.writeTextFile {
    name = "niri-session";
    destination = "/share/wayland-sessions/niri.desktop";
    text = ''
      [Desktop Entry]
      Name=Niri
      Comment=A scrollable-tiling Wayland compositor
      Exec=${lib.getExe pkgs.uwsm} start -F -- /run/current-system/sw/bin/niri-session
      Type=Application
      DesktopNames=niri
    '';
    derivationArgs.passthru.providedSessions = [ "niri" ];
  };
in
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

  programs.uwsm.enable = true;

  services.displayManager = {
    defaultSession = "niri";
    sessionPackages = lib.mkForce [ niriSession ];
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
