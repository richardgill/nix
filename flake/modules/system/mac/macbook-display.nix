{ pkgs, vars, ... }:
let
  watcherScript = pkgs.writeShellScript "macbook-display-watch-launchd" ''
    export PATH="/opt/homebrew/bin:/usr/local/bin:/run/current-system/sw/bin:/usr/bin:/bin:$PATH"
    exec "/Users/${vars.userName}/Scripts/macbook-display-watch"
  '';
in
{
  launchd.user.agents.macbook-display-watch = {
    serviceConfig = {
      ProgramArguments = [ "${watcherScript}" ];
      EnvironmentVariables = {
        MACBOOK_DISPLAY_ALLOWLIST = "195e8";
      };
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/tmp/macbook-display-watch.log";
      StandardErrorPath = "/tmp/macbook-display-watch.err";
      Label = "org.nixos.macbook-display-watch";
    };
  };
}
