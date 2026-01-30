{ config, ... }:
let
  scriptPath = "${config.home.homeDirectory}/Scripts/overlay-sync-all";
in
{
  systemd.user.services.overlay-sync-all = {
    Unit = {
      Description = "Sync overlay repository";
    };
    Service = {
      Type = "oneshot";
      ExecStart = scriptPath;
      Environment = [ "PATH=/run/current-system/sw/bin:/usr/bin:/bin" ];
    };
  };

  systemd.user.timers.overlay-sync-all = {
    Unit = {
      Description = "Run overlay-sync-all every 5 minutes";
    };
    Timer = {
      OnCalendar = "*:0/5";
      Persistent = true;
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };
}
