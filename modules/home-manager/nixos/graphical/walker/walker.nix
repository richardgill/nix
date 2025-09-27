{ config, lib, pkgs, ... }:

{
  systemd.user.services.walker = {
    Unit = {
      Description = "Walker Application Launcher";
      After = [ "graphical-session.target" ];
      Requisite = [ "graphical-session.target" ];
    };
    Service = {
      Type = "dbus";
      BusName = "org.gnome.Walker";
      ExecStart = "${pkgs.walker}/bin/walker --gapplication-service";
      Restart = "on-failure";
      Environment = [ "WAYLAND_DISPLAY=wayland-1" ];
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  home.file = {
    ".config/walker/config.toml".source = ./config.toml;
    ".config/walker/themes/tokyo-night.toml".source = ./tokyo-night.toml;
    ".config/walker/themes/tokyo-night.css".source = ./tokyo-night.css;
    ".config/walker/launch-app.sh" = {
      source = ./launch-app.sh;
      executable = true;
    };
  };
}
