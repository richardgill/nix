{ pkgs, ... }:
{
  launchd.daemons.eternal-terminal = {
    serviceConfig = {
      Label = "dev.eternalterminal.etserver";
      ProgramArguments = [
        "${pkgs.eternal-terminal}/bin/etserver"
        "--port"
        "2022"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardErrorPath = "/tmp/etserver.err";
      StandardOutPath = "/tmp/etserver.log";
    };
  };
}
