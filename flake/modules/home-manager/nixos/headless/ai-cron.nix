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
    };
    Service = {
      WorkingDirectory = appDir;
      ExecStart = "${pkgs.bash}/bin/bash -lc 'set -a; source ${config.home.homeDirectory}/.config/secrets/env.sh; set +a; exec ${pnpmPath} start'";
      Restart = "always";
      RestartSec = "2s";
      StateDirectory = "ai-cron";
      Environment = [
        "PATH=${pathEnv}"
        "NTFY_AGENT_TOPIC_FILE=${config.home.sessionVariables.NTFY_AGENT_TOPIC_FILE}"
        "NTFY_GITHUB_TOPIC_FILE=${config.home.sessionVariables.NTFY_GITHUB_TOPIC_FILE}"
      ];
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
