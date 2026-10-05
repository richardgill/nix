{ config, pkgs, ... }:
let
  appDir = "${config.home.homeDirectory}/code/nix-private/out-of-store-config/services/ai-cron";
  pnpmPath = "${config.home.homeDirectory}/.local/share/mise/shims/pnpm";
  pathEnv = "${config.home.homeDirectory}/.local/share/mise/shims:/etc/profiles/per-user/${config.home.username}/bin:/run/current-system/sw/bin:/usr/bin:/bin";
in
{
  systemd.user.services.ai-cron = {
    Unit = {
      Description = "AI cron";
      After = [ "overmux.service" ];
      Wants = [ "overmux.service" ];
    };
    Service = {
      WorkingDirectory = appDir;
      ExecStart = "${pkgs.bash}/bin/bash -lc 'set -a; source ${config.home.homeDirectory}/.config/secrets/env.sh; set +a; exec ${pnpmPath} start'";
      Restart = "always";
      RestartSec = "2s";
      StateDirectory = "ai-cron";
      Environment = [
        "PATH=${pathEnv}"
      ];
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
