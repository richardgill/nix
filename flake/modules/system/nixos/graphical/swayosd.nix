{
  pkgs,
  ...
}:
{
  systemd.user.services.swayosd = {
    description = "SwayOSD";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.swayosd}/bin/swayosd-server";
      Restart = "always";
      RestartSec = 1;
    };
  };
}
