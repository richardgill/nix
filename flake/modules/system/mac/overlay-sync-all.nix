{ pkgs, vars, ... }:
let
  overlaySyncScript = pkgs.writeShellScript "overlay-sync-all-launchd" ''
    export PATH="/run/current-system/sw/bin:/usr/bin:/bin:$PATH"
    exec "/Users/${vars.userName}/Scripts/overlay-sync-all"
  '';
in
{
  launchd.user.agents.overlay-sync-all = {
    serviceConfig = {
      ProgramArguments = [ "${overlaySyncScript}" ];
      RunAtLoad = true;
      StartInterval = 300;
      StandardOutPath = "/tmp/overlay-sync-all.log";
      StandardErrorPath = "/tmp/overlay-sync-all.err";
      Label = "org.nixos.overlay-sync-all";
    };
  };
}
