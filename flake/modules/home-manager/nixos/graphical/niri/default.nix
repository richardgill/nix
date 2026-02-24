{ lib, pkgs, ... }:
{
  xdg.configFile."niri/config.kdl".source = ./config.kdl;

  # this is needed to scale down some x11 windows (bambu-studio) in niri
  services.xsettingsd = {
    enable = true;
    settings = {
      "Xft/DPI" = 98304;
      "Gdk/WindowScalingFactor" = 1;
      "Gdk/UnscaledDPI" = 98304;
    };
  };

  systemd.user.services.xsettingsd = {
    Unit = {
      After = [ "niri.service" ];
    };
    Service = {
      # Home Manager's xsettingsd module sets Restart=on-abort by default; force on-failure so startup races with Xwayland are retried and to avoid a conflicting option definition.
      Restart = lib.mkForce "on-failure";
      RestartSec = "2s";
    };
  };

  systemd.user.services.hyprpolkitagent = {
    Unit = {
      Description = "Polkit Authentication Agent";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
      Slice = "session.slice";
      TimeoutStopSec = "5sec";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
